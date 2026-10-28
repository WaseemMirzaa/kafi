import * as admin from 'firebase-admin';

/** Paid / cancelled-in-period families list jobs to nannies; free/expired do not. */
export function familyJobsVisibleToNannies(status: unknown): boolean {
  // paymentFailed = grace period: access (and the family's visible jobs) continue.
  return status === 'active' || status === 'cancelled' || status === 'paymentFailed';
}

/** Re-stamp `visibleToNannies` on every job owned by [familyId]. */
export async function syncFamilyJobsVisibility(
  familyId: string,
  visible: boolean,
): Promise<number> {
  const db = admin.firestore();
  const snap = await db.collection('jobs').where('familyId', '==', familyId).get();
  if (snap.empty) return 0;

  let batch = db.batch();
  let ops = 0;
  let total = 0;
  for (const doc of snap.docs) {
    batch.update(doc.ref, { visibleToNannies: visible });
    ops += 1;
    total += 1;
    if (ops >= 400) {
      await batch.commit();
      batch = db.batch();
      ops = 0;
    }
  }
  if (ops > 0) await batch.commit();
  return total;
}
