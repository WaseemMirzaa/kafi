import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as logger from 'firebase-functions/logger';
import * as admin from 'firebase-admin';
import { sendNotification, writeInbox, getFamily, getUser } from '../utils/notifications';
import { recomputeActiveTrialNannyIds } from './trial';
import { tn } from '../i18n/notifications';

export const trialStartingReminder = onSchedule('every 1 hours', async () => {
  const now = new Date();
  const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  const db = admin.firestore();

  const trials = await db
    .collection('trials')
    .where('status', '==', 'accepted')
    .where('startDate', '<=', admin.firestore.Timestamp.fromDate(tomorrow))
    .where('startDate', '>', admin.firestore.Timestamp.fromDate(now))
    .limit(200)
    .get();

  await Promise.all(
    trials.docs.map(async (doc) => {
      const trial = doc.data();
      if (trial.reminderSent) return;

      const [family, nannyUser] = await Promise.all([
        getFamily(trial.familyId as string),
        getUser(trial.nannyId as string),
      ]);

      const data = {
        type: 'trial_starting_soon',
        trialId: doc.id,
        nannyId: String(trial.nannyId ?? ''),
        familyId: String(trial.familyId ?? ''),
        route: '/trial',
      };

      // Each side may have a different locale preference, so the reminder is
      // built and sent per-recipient rather than as one shared push.
      for (const [recipientId, bearer] of [
        [trial.familyId as string, family],
        [trial.nannyId as string, nannyUser],
      ] as const) {
        const locale = bearer.locale ?? 'en';
        const title = tn('trial.startingSoon.title', locale);
        const body = tn('trial.startingSoon.body', locale, {
          time: (trial.startTime as string) || tn('trial.startingSoon.defaultTime', locale),
        });
        await writeInbox(recipientId, 'trialStartingSoon', title, body, data);
        await sendNotification((bearer.fcmTokens as string[]) ?? [], { title, body, data });
      }
      await doc.ref.update({ reminderSent: true });
    }),
  );
});

/// Pure predicate behind `trialOutcomeDetector` — a trial is due for the
/// mutual-outcome prompt once its execution window has closed (`endDate`
/// reached) and it hasn't already been prompted (idempotency flag, mirrors
/// `trialStartingReminder`'s `reminderSent`). Kept pure/exported so the
/// boundary conditions (exactly-now vs. one-ms-past, already-prompted) are
/// unit-testable without a live Firestore query.
export function isTrialDueForOutcome(
  trial: {
    status?: string;
    endDate?: FirebaseFirestore.Timestamp | Date;
    outcomePromptSent?: boolean;
  },
  nowMs: number,
): boolean {
  if (trial.status !== 'active') return false;
  if (trial.outcomePromptSent) return false;
  if (!trial.endDate) return false;
  const endMs = trial.endDate instanceof Date ? trial.endDate.getTime() : trial.endDate.toMillis();
  return endMs <= nowMs;
}

/// Fires the mutual-outcome prompt for one trial doc: notifies both parties
/// and flips status → `awaitingOutcome`. Shared by the primary (Timestamp
/// `endDate`) path and the legacy-repair path below so a trial healed from a
/// string `endDate` doesn't have to wait for a second hourly run.
async function fireOutcomePrompt(doc: FirebaseFirestore.QueryDocumentSnapshot): Promise<void> {
  const trial = doc.data();
  const [family, nannyUser] = await Promise.all([
    getFamily(trial.familyId as string),
    getUser(trial.nannyId as string),
  ]);

  const famLocale = family.locale ?? 'en';
  const nanLocale = nannyUser.locale ?? 'en';
  const famTitle = tn('trial.outcomePendingFamily.title', famLocale);
  const famBody = tn('trial.outcomePendingFamily.body', famLocale);
  const nanTitle = tn('trial.outcomePendingNanny.title', nanLocale);
  const nanBody = tn('trial.outcomePendingNanny.body', nanLocale);
  const data = { type: 'trial_outcome_pending', trialId: doc.id };

  await writeInbox(trial.familyId as string, 'trialOutcomePending', famTitle, famBody, data);
  await sendNotification((family.fcmTokens as string[]) ?? [], {
    title: famTitle,
    body: famBody,
    data,
  });
  await writeInbox(trial.nannyId as string, 'trialOutcomePending', nanTitle, nanBody, data);
  await sendNotification((nannyUser.fcmTokens as string[]) ?? [], {
    title: nanTitle,
    body: nanBody,
    data,
  });

  await doc.ref.update({
    status: 'awaitingOutcome',
    endReachedAt: admin.firestore.FieldValue.serverTimestamp(),
    outcomePromptSent: true,
  });
  // The family's chat-unlock list must widen to include this nanny for the
  // awaitingOutcome wait too — see recomputeActiveTrialNannyIds' doc
  // comment (trial.ts) for why. Exactly as onTrialResponse does on accept.
  await recomputeActiveTrialNannyIds(trial.familyId as string);
}

/// Detects trials whose execution window has closed (`endDate` reached while
/// still `active`) and moves them into `awaitingOutcome`, prompting both
/// parties to record what happened. This is the entry point into the
/// mutual-confirm gate — `onTrialOutcomeResolved` (trial.ts) takes over once
/// either/both sides respond. Modeled on `trialStartingReminder` above:
/// hourly schedule, Timestamp range query, bounded `.limit(200)`, per-doc
/// idempotency flag.
///
/// `endDate` must be a Firestore Timestamp for the range query to match it
/// (`TrialModel.toMap()` writes it as an ISO string by default; the real
/// write paths — `sendOffer`/`applyCounterAndAccept` — override that before
/// persisting). A trial written some other way could still end up with a
/// string `endDate`, which the query above would silently never match — the
/// self-heal pass below (after the main query) finds and repairs exactly
/// that case instead of leaving the trial stuck forever.
export const trialOutcomeDetector = onSchedule('every 1 hours', async () => {
  const now = admin.firestore.Timestamp.now();
  const trials = await admin
    .firestore()
    .collection('trials')
    .where('status', '==', 'active')
    .where('endDate', '<=', now)
    .limit(200)
    .get();

  // Diagnostic logging (no PII beyond doc ids) — the only way to see, from
  // Cloud Functions logs alone, whether a given hourly run found zero
  // qualifying trials (most common: no trial has reached its real end date
  // yet) vs. found some but skipped them (e.g. a legacy string `endDate` that
  // failed the query, or `outcomePromptSent` already true).
  logger.info(`trialOutcomeDetector: query matched ${trials.size} trial(s) with status=active, endDate<=now`);

  await Promise.all(
    trials.docs.map(async (doc) => {
      const trial = doc.data();
      const due = isTrialDueForOutcome(trial, now.toMillis());
      logger.info(
        `trialOutcomeDetector: trial ${doc.id} status=${trial.status} outcomePromptSent=${trial.outcomePromptSent} due=${due}`,
      );
      if (!due) return;
      await fireOutcomePrompt(doc);
    }),
  );

  // A trial whose `endDate` is a legacy ISO string (not a Firestore
  // Timestamp) fails the `<=` comparison above silently — it just never
  // matches, with no error anywhere (see this function's doc comment). Rather
  // than leaving that trial stuck forever, self-heal it: rewrite `endDate` as
  // a proper Timestamp so future runs pick it up normally, and — since this
  // run already has the doc in hand — fire the prompt immediately if it's
  // already due, instead of making the family/nanny wait for a 2nd hourly run.
  const allActive = await admin.firestore().collection('trials').where('status', '==', 'active').limit(200).get();
  logger.info(`trialOutcomeDetector: ${allActive.size} trial(s) total with status=active (before the endDate filter)`);
  await Promise.all(
    allActive.docs.map(async (doc) => {
      const endDate = doc.data().endDate;
      if (endDate instanceof admin.firestore.Timestamp) return;

      const parsed = new Date(endDate as string);
      if (Number.isNaN(parsed.getTime())) {
        logger.error(
          `trialOutcomeDetector: trial ${doc.id} has status=active but endDate is unparseable (typeof=${typeof endDate}, value=${String(endDate)}) — cannot self-heal, needs manual data fix.`,
        );
        return;
      }

      logger.warn(
        `trialOutcomeDetector: trial ${doc.id} had a legacy string endDate (${String(endDate)}) — repairing to a Timestamp.`,
      );
      const endTimestamp = admin.firestore.Timestamp.fromDate(parsed);
      await doc.ref.update({ endDate: endTimestamp });

      const trial = { ...doc.data(), endDate: endTimestamp };
      const due = isTrialDueForOutcome(trial, now.toMillis());
      logger.info(`trialOutcomeDetector: repaired trial ${doc.id} due=${due} — firing prompt now if due.`);
      if (due) await fireOutcomePrompt(doc);
    }),
  );
});

export const subscriptionExpiringReminder = onSchedule('every day 09:00', async () => {
  const in3Days = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
  const families = await admin
    .firestore()
    .collection('families')
    .where('subscription.status', '==', 'active')
    .where('subscription.endDate', '<=', admin.firestore.Timestamp.fromDate(in3Days))
    .limit(200)
    .get();

  await Promise.all(
    families.docs.map(async (doc) => {
      const family = await getFamily(doc.id);
      const tokens = (family.fcmTokens as string[]) ?? [];
      const locale = family.locale ?? 'en';

      const title = tn('subscription.expiringSoon.title', locale);
      const body = tn('subscription.expiringSoon.body', locale);
      const data = { type: 'subscription_expiring' };
      await writeInbox(doc.id, 'subscriptionExpiring', title, body, data);
      await sendNotification(tokens, { title, body, data });
    }),
  );
});

export const subscriptionExpiredEnforcer = onSchedule('every 1 hours', async () => {
  const now = admin.firestore.Timestamp.now();
  const db = admin.firestore();
  const families = await db
    .collection('families')
    .where('subscription.status', 'in', ['active', 'cancelled'])
    .where('subscription.endDate', '<=', now)
    .limit(450)
    .get();

  // Chunk into batches of ≤450 writes (Firestore limit 500).
  for (let i = 0; i < families.docs.length; i += 450) {
    const batch = db.batch();
    families.docs.slice(i, i + 450).forEach((doc) => {
      batch.update(doc.ref, {
        'subscription.status': 'expired',
        'subscription.expiredAt': now,
        'subscription.contactsHidden': true,
        'subscription.chatLocked': true,
      });
    });
    await batch.commit();
  }

  await Promise.all(
    families.docs.map(async (doc) => {
      const family = await getFamily(doc.id);
      const tokens = (family.fcmTokens as string[]) ?? [];
      const locale = family.locale ?? 'en';

      const title = tn('subscription.expiredEnforced.title', locale);
      const body = tn('subscription.expiredEnforced.body', locale);
      const data = { type: 'subscription_expired' };
      await writeInbox(doc.id, 'subscriptionExpired', title, body, data);
      await sendNotification(tokens, { title, body, data });
    }),
  );
});
