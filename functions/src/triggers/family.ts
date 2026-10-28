import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import {
  familyJobsVisibleToNannies,
  syncFamilyJobsVisibility,
} from '../utils/jobVisibility';
import * as admin from 'firebase-admin';
import { isContactLockedOut, revokeContactReveals } from './contact';

function sameIds(a: unknown, b: unknown): boolean {
  const x = Array.isArray(a) ? [...(a as string[])].sort() : [];
  const y = Array.isArray(b) ? [...(b as string[])].sort() : [];
  return x.length === y.length && x.every((id, i) => id === y[i]);
}

/// Mirrors the family's lapsed state onto the chat threads and applications the
/// *nanny* sees, so her app can hide them without being allowed to read the
/// family's subscription. Same denormalised-flag pattern as jobs'
/// `visibleToNannies`. Only a lapsed plan (expired / payment failed) hides
/// anything: a free-tier family's unlocked chats must keep working.
export async function syncFamilyLockedFlag(familyId: string, locked: boolean): Promise<number> {
  const db = admin.firestore();
  let touched = 0;
  for (const col of ['chatThreads', 'applications']) {
    const snap = await db.collection(col).where('familyId', '==', familyId).get();
    const docs = snap.docs.filter((d) => (d.data().familyLocked === true) !== locked);
    for (let i = 0; i < docs.length; i += 450) {
      const batch = db.batch();
      docs.slice(i, i + 450).forEach((d) => batch.update(d.ref, { familyLocked: locked }));
      await batch.commit();
    }
    touched += docs.length;
  }
  return touched;
}

/**
 * When a family's subscription status changes:
 *  - re-stamp all of their job posts so the nanny board shows/hides them
 *    (free-tier posts stay in My Jobs only);
 *  - flag their chats/applications so nannies stop seeing them while lapsed;
 *  - once the plan has lapsed, take back the phone numbers already revealed to
 *    them (`contactReveals` docs hold the phone and stay readable by the
 *    family), keeping only nannies they still have a live trial with.
 */
export const onFamilySubscriptionWritten = onDocumentWritten(
  'families/{familyId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!after) return;

    const beforeStatus = (before?.subscription as { status?: string } | undefined)
      ?.status;
    const afterStatus = (after.subscription as { status?: string } | undefined)?.status;
    const statusChanged = beforeStatus !== afterStatus || before == null;
    const trialsChanged = !sameIds(before?.activeTrialNannyIds, after.activeTrialNannyIds);

    const familyId = event.params.familyId as string;

    if (statusChanged) {
      await syncFamilyJobsVisibility(familyId, familyJobsVisibleToNannies(afterStatus));
      await syncFamilyLockedFlag(familyId, isContactLockedOut(afterStatus));
    }

    // A live trial ending while the plan is already lapsed also costs the
    // family that nanny's contact, hence the trialsChanged branch.
    if (isContactLockedOut(afterStatus) && (statusChanged || trialsChanged)) {
      await revokeContactReveals(familyId, after.activeTrialNannyIds);
    }
  },
);
