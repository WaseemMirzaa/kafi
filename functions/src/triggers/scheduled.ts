import { onSchedule } from 'firebase-functions/v2/scheduler';
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

/// Detects trials whose execution window has closed (`endDate` reached while
/// still `active`) and moves them into `awaitingOutcome`, prompting both
/// parties to record what happened. This is the entry point into the
/// mutual-confirm gate — `onTrialOutcomeResolved` (trial.ts) takes over once
/// either/both sides respond. Modeled exactly on `trialStartingReminder`
/// above: hourly schedule, Timestamp range query, bounded `.limit(200)`,
/// per-doc idempotency flag.
///
/// Depends on `endDate` being stored as a Firestore Timestamp (not the ISO
/// string `TrialModel.toMap()` used to produce) — trials created before that
/// app-side fix keep a string `endDate` and are silently excluded from this
/// query rather than erroring, an accepted additive gap.
export const trialOutcomeDetector = onSchedule('every 1 hours', async () => {
  const now = admin.firestore.Timestamp.now();
  const trials = await admin
    .firestore()
    .collection('trials')
    .where('status', '==', 'active')
    .where('endDate', '<=', now)
    .limit(200)
    .get();

  await Promise.all(
    trials.docs.map(async (doc) => {
      const trial = doc.data();
      if (!isTrialDueForOutcome(trial, now.toMillis())) return;

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
