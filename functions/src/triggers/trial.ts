import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { sendNotification, writeInbox, getUser, getNanny, getFamily } from '../utils/notifications';

/// Recomputes `families/{familyId}.activeTrialNannyIds` from the family's trials
/// currently in an entitling state (accepted/active/awaitingOutcome). This
/// server-owned list is what the security rules' `hasActiveTrialWith` reads to
/// let a family without a subscription chat with a nanny during a trial, so it
/// must be refreshed whenever a trial ENTERS that set (accept; the scheduled
/// detector's active→awaitingOutcome flip) as well as when it LEAVES it (end)
/// — previously only the end transition recomputed it, so an accepted trial
/// never unlocked the chat for a free family. `awaitingOutcome` is included so
/// an unsubscribed family doesn't lose chat access at exactly the point both
/// parties most need to discuss the outcome — she hasn't left the
/// relationship, she's just waiting on both sides to record what happened.
/// Distinct from the browse-hide derivation (`activeTrialNannyIds` on
/// `ITrialService`), which is intentionally left unwidened — see the
/// trial-completion plan §4.4. Exported so the scheduled detector
/// (scheduled.ts) can call it too.
export async function recomputeActiveTrialNannyIds(familyId: string): Promise<void> {
  if (!familyId) return;
  const db = admin.firestore();
  const snap = await db
    .collection('trials')
    .where('familyId', '==', familyId)
    .where('status', 'in', ['active', 'accepted', 'awaitingOutcome'])
    .get();
  const activeIds = Array.from(
    new Set(snap.docs.map((d) => d.data().nannyId as string).filter(Boolean)),
  );
  await db.collection('families').doc(familyId).update({ activeTrialNannyIds: activeIds });
}

export const onNewApplication = onDocumentCreated(
  'applications/{appId}',
  async (event) => {
    const app = event.data?.data();
    if (!app) return;

    const family = await getFamily(app.familyId);
    const nanny = await getNanny(app.nannyId);

    const title = '📝 New application';
    const body = `${nanny.fullName || 'A nanny'} applied - ${app.matchScore || 0}% match`;
    const data = { type: 'new_application', applicationId: event.params.appId };

    // Durable inbox record first (survives a missing FCM token), then the push.
    await writeInbox(app.familyId as string, 'newApplication', title, body, data);
    await sendNotification((family.fcmTokens as string[]) ?? [], { title, body, data });

    // Server-owned nanny aggregate (rules deny cross-client nanny-doc writes).
    if (app.nannyId) {
      await admin
        .firestore()
        .collection('nannies')
        .doc(app.nannyId as string)
        .set(
          { stats: { applicationsCount: admin.firestore.FieldValue.increment(1) } },
          { merge: true },
        );
    }
  }
);

// Notify the nanny when a family VIEWS or DECLINES her application. The
// applicationViewed / applicationDeclined inbox types and their app routing
// already exist; only this producer was missing. Fires once, on the transition
// INTO 'viewed'/'declined' (guards against no-op writes and other statuses).
export const onApplicationUpdated = onDocumentUpdated(
  'applications/{appId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === after.status) return;
    if (after.status !== 'viewed' && after.status !== 'declined') return;

    const [nanny, family] = await Promise.all([
      getNanny(after.nannyId),
      getFamily(after.familyId),
    ]);
    const famName = family.fullName || 'A family';
    const jobTitle = after.jobTitle || 'your application';
    const viewed = after.status === 'viewed';

    const title = viewed ? '👀 Application viewed' : 'Application update';
    const body = viewed
      ? `${famName} viewed your application for ${jobTitle}`
      : `${famName} passed on your application for ${jobTitle}`;
    const data = {
      type: viewed ? 'application_viewed' : 'application_declined',
      applicationId: event.params.appId,
    };

    // Durable inbox first (survives a missing FCM token), then the push.
    await writeInbox(
      after.nannyId as string,
      viewed ? 'applicationViewed' : 'applicationDeclined',
      title,
      body,
      data,
    );
    await sendNotification((nanny.fcmTokens as string[]) ?? [], { title, body, data });
  }
);

export const onTrialOffered = onDocumentCreated('trials/{trialId}', async (event) => {
  const trial = event.data?.data();
  if (!trial || trial.status !== 'pending') return;

  const nanny = await getUser(trial.nannyId);
  const family = await getFamily(trial.familyId);

  const title = '🎉 Trial offer received!';
  const body = `${family.fullName || 'A family'} sent ${trial.durationDays}-day trial @ AED ${trial.dailyRate}/day`;
  const data = { type: 'trial_offer_received', trialId: event.params.trialId };

  await writeInbox(trial.nannyId as string, 'trialOfferReceived', title, body, data);
  await sendNotification((nanny.fcmTokens as string[]) ?? [], { title, body, data });
});

export const onTrialResponse = onDocumentUpdated('trials/{trialId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status) return;

  const trialId = event.params.trialId;

  // A response to the nanny's COUNTER offer is the FAMILY acting, so it must be
  // attributed to the family and delivered to the NANNY — the mirror image of a
  // first-round nanny response. Handle it before the nanny-response table, which
  // would otherwise (wrongly) tell the family "Nanny accepted your offer!".
  if (
    before.status === 'countered' &&
    (after.status === 'accepted' || after.status === 'declined')
  ) {
    const [family, nanny] = await Promise.all([
      getFamily(after.familyId),
      getUser(after.nannyId),
    ]);
    const accepted = after.status === 'accepted';
    const famName = family.fullName || 'The family';
    const title = accepted ? '✅ Counter accepted' : 'Counter declined';
    const body = accepted
      ? `${famName} accepted your counter offer!`
      : `${famName} declined your counter offer`;
    const data = { type: `trial_counter_${after.status}`, trialId };
    await writeInbox(
      after.nannyId as string,
      accepted ? 'trialAccepted' : 'trialDeclined',
      title,
      body,
      data,
    );
    await sendNotification((nanny.fcmTokens as string[]) ?? [], { title, body, data });
    if (accepted) await recomputeActiveTrialNannyIds(after.familyId as string);
    return;
  }

  const family = await getFamily(after.familyId);
  const nanny = await getUser(after.nannyId);

  const byStatus = {
    accepted: {
      title: '✅ Trial accepted',
      body: `${nanny.fullName || 'Nanny'} accepted your offer!`,
      type: 'trialAccepted',
    },
    declined: {
      title: 'Trial declined',
      body: `${nanny.fullName || 'Nanny'} declined your offer`,
      type: 'trialDeclined',
    },
    countered: {
      title: '🔄 Counter offer',
      body: `${nanny.fullName || 'Nanny'} sent a counter offer`,
      type: 'trialCountered',
    },
  } as const;

  const entry = byStatus[after.status as keyof typeof byStatus];
  if (!entry) return;

  const data = { type: `trial_${after.status}`, trialId: event.params.trialId };
  await writeInbox(after.familyId as string, entry.type, entry.title, entry.body, data);
  await sendNotification((family.fcmTokens as string[]) ?? [], {
    title: entry.title,
    body: entry.body,
    data,
  });

  // Acceptance unlocks trial-chat: refresh the family's entitlement list so a
  // free family can immediately message this nanny (the gate reads it).
  if (after.status === 'accepted') {
    await recomputeActiveTrialNannyIds(after.familyId as string);
  }
});

/// Pure truth table behind `onTrialOutcomeResolved` — decides the
/// mutual-confirm verdict from each side's independently-written outcome
/// field. `notHired` on EITHER side wins outright (the mismatch case: a
/// family that already said "hired" but a nanny who says "notHired" must
/// never create a hire), both sides must say `hired` for a match, and
/// anything else (a side hasn't responded yet) stays `pending`. Kept
/// pure/exported so the truth table is unit-testable without a live trigger
/// invocation.
export function resolveMutualOutcome(
  familyOutcome?: string,
  nannyOutcome?: string,
): 'hired' | 'notHired' | 'pending' {
  if (familyOutcome === 'notHired' || nannyOutcome === 'notHired') return 'notHired';
  if (familyOutcome === 'hired' && nannyOutcome === 'hired') return 'hired';
  return 'pending';
}

/// Resolves the mutual-confirm gate once a side writes its outcome onto an
/// `awaitingOutcome` trial. Fires on every update to such a trial but only
/// acts when `familyOutcome`/`nannyOutcome` actually changed and the verdict
/// is decided (`resolveMutualOutcome` above) — a lone response is a no-op,
/// still waiting on the other side.
///
/// Resolution is server-side by design, not client-side: `firestore.rules`'
/// `hires` collection only lets the FAMILY's client create a hire doc, so a
/// client-side resolution running on the nanny's device (when she's the
/// second party to respond) could never write it — hire creation would
/// silently fail for exactly half of the possible response orderings. The
/// Admin SDK bypasses rules entirely, so this works regardless of which side
/// resolves the match second.
export const onTrialOutcomeResolved = onDocumentUpdated('trials/{trialId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || after.status !== 'awaitingOutcome') return;
  if (
    before.familyOutcome === after.familyOutcome &&
    before.nannyOutcome === after.nannyOutcome
  ) {
    return;
  }

  const verdict = resolveMutualOutcome(
    after.familyOutcome as string | undefined,
    after.nannyOutcome as string | undefined,
  );
  if (verdict === 'pending') return;

  const trialId = event.params.trialId;
  const db = admin.firestore();
  const ref = db.collection('trials').doc(trialId);

  // First-resolution-wins: read the trial fresh inside a transaction and bail
  // if another invocation already resolved it — mirrors `onHireEnded`'s
  // before/after guard and `FirestoreHireService.endHire`'s transactional
  // first-end-wins pattern, both already in this codebase.
  let didResolve = false;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.data()?.status !== 'awaitingOutcome') return;
    tx.update(ref, {
      status: 'completed',
      outcome: verdict === 'hired' ? 'hired' : 'failed',
      outcomeAt: admin.firestore.FieldValue.serverTimestamp(),
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    didResolve = true;
  });
  // A verdict lost the race (another invocation resolved it first) or wasn't
  // a hire — either way there's no hire record to create.
  if (!didResolve || verdict !== 'hired') return;

  // A background function has no client auth context — it cannot read
  // `_auth.currentUser` the way the old client-side `_createHireFromTrial`
  // did — so the display names for the hire record must be looked up here.
  const [family, nanny] = await Promise.all([
    getFamily(after.familyId as string),
    getNanny(after.nannyId as string),
  ]);

  const hireId = `hire_${trialId}`;
  await db
    .collection('hires')
    .doc(hireId)
    .set({
      id: hireId,
      familyId: after.familyId,
      nannyId: after.nannyId,
      jobPostId: (after.jobPostId as string | undefined) ?? null,
      trialId,
      employmentType: (after.trialType as string | undefined) ?? 'live-in',
      salaryAed: 0,
      status: 'active',
      endReason: null,
      startedAt: admin.firestore.FieldValue.serverTimestamp(),
      endedAt: null,
      endNote: null,
      nannyName: (nanny.fullName as string | undefined) ?? null,
      familyName: (family.fullName as string | undefined) ?? null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  // Best-effort: flip the matching application to hired, using the exact same
  // write shape `FirestoreApplicationService.markHired` already uses. A
  // missing application is fine (a trial offered directly, not via an
  // application) — swallow errors so a lookup failure never undoes the hire
  // that already committed above, matching `_createHireFromTrial`'s existing
  // behavior.
  try {
    const appsSnap = await db
      .collection('applications')
      .where('familyId', '==', after.familyId)
      .where('nannyId', '==', after.nannyId)
      .limit(10)
      .get();
    const jobPostId = after.jobPostId as string | undefined;
    const match = appsSnap.docs.find((d) => !jobPostId || d.data().jobPostId === jobPostId);
    if (match) {
      await match.ref.update({
        status: 'hired',
        respondedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  } catch (error) {
    console.error('onTrialOutcomeResolved: application lookup failed', error);
  }
});

/// Per Technical Architecture §10.2 — when a trial transitions to a terminal
/// state (completed/cancelled), recompute family.activeTrialNannyIds so the
/// subscription bypass falls back to normal lockdown rules.
export const onTrialEnded = onDocumentUpdated('trials/{trialId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;

  const terminal = ['completed', 'cancelled', 'declined'];
  const wasActive = !terminal.includes(before.status);
  const isTerminal = terminal.includes(after.status);
  if (!wasActive || !isTerminal) return;

  const familyId = after.familyId as string;
  if (!familyId) return;

  // A trial left the entitling set — recompute the list (shared with the accept
  // path) and stamp when the last trial ended.
  await recomputeActiveTrialNannyIds(familyId);
  await admin.firestore().collection('families').doc(familyId).update({
    'subscription.lastTrialEndedAt': admin.firestore.FieldValue.serverTimestamp(),
  });

  // Both terminal outcomes must reach BOTH parties. Previously only 'completed'
  // fired, only to the family, with stale "evaluate the nanny" copy — and
  // 'cancelled' notified nobody despite the UI promising "both parties will be
  // notified".
  if (after.status === 'completed' || after.status === 'cancelled') {
    const nannyId = after.nannyId as string | undefined;
    const [family, nanny] = await Promise.all([
      getFamily(familyId),
      nannyId ? getUser(nannyId) : Promise.resolve({} as Record<string, unknown>),
    ]);
    const data = { type: `trial_${after.status}`, trialId: event.params.trialId };

    if (after.status === 'completed') {
      // Outcome-aware, de-duplicated copy — replaces the old always-generic
      // pair that fired verbatim even when the family had already decided
      // against hiring.
      const outcome = after.outcome as string | undefined;
      let famTitle: string;
      let famBody: string;
      let nanTitle: string | undefined;
      let nanBody: string | undefined;

      if (outcome === 'hired') {
        // The nanny already got "🎉 You’ve been hired!" from `onHireCreated`
        // (fired off the `hires/{id}` doc `onTrialOutcomeResolved` just
        // created) — sending her this generic push too would double-notify
        // her for the same event, so only the family gets a push here.
        const nannyName = (nanny.fullName as string | undefined) || 'your nanny';
        famTitle = '✅ Hire confirmed';
        famBody = `You and ${nannyName} confirmed the hire — she’s now marked Hired.`;
      } else if (outcome === 'failed') {
        famTitle = 'Trial closed';
        famBody = 'This trial didn’t lead to a hire. Keep browsing for your next match.';
        nanTitle = 'Trial update';
        nanBody =
          'This trial didn’t lead to a hire this time. Your profile is visible in search again.';
      } else {
        // Defensive fallback for a trial completed via a path this phase
        // doesn't control (e.g. a future admin action) — keep today's copy
        // verbatim so that path never regresses.
        famTitle = '✅ Trial completed';
        famBody = 'The trial is complete — decide whether to hire.';
        nanTitle = '✅ Trial completed';
        nanBody = 'Your trial is complete. The family will confirm next steps.';
      }

      await writeInbox(familyId, 'trialCompleted', famTitle, famBody, data);
      await sendNotification((family.fcmTokens as string[]) ?? [], {
        title: famTitle,
        body: famBody,
        data,
      });
      if (nannyId && nanTitle && nanBody) {
        await writeInbox(nannyId, 'trialCompleted', nanTitle, nanBody, data);
        await sendNotification((nanny.fcmTokens as string[]) ?? [], {
          title: nanTitle,
          body: nanBody,
          data,
        });
      }
    } else {
      const title = 'Trial cancelled';
      const body = 'The trial has been cancelled.';
      await writeInbox(familyId, 'systemAnnouncement', title, body, data);
      await sendNotification((family.fcmTokens as string[]) ?? [], { title, body, data });
      if (nannyId) {
        await writeInbox(nannyId, 'systemAnnouncement', title, body, data);
        await sendNotification((nanny.fcmTokens as string[]) ?? [], { title, body, data });
      }
    }
  }
});
