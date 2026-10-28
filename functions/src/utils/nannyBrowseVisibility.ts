import * as admin from 'firebase-admin';

/// Compact fingerprint of a nanny's availability setting, used to notice when a
/// HIRED nanny changes it. Must match NannyListingActivity.availabilityKey in
/// the app. `availableFrom` only counts when the status is availableFrom, and
/// only its calendar date (UTC) — a time-of-day edit is not a change.
export function availabilityKey(nanny: {
  availability?: unknown;
  availableFrom?: unknown;
}): string {
  const status = typeof nanny.availability === 'string' && nanny.availability
    ? nanny.availability
    : 'availableNow';
  if (status !== 'availableFrom') return `${status}|`;
  const raw = nanny.availableFrom as { toDate?: () => Date } | string | null | undefined;
  let date = '';
  if (typeof raw === 'string') date = raw.slice(0, 10);
  else if (raw && typeof raw.toDate === 'function') date = raw.toDate().toISOString().slice(0, 10);
  return `${status}|${date}`;
}

/**
 * Server-owned flag on `nannies/{id}.hiddenFromBrowse`.
 * True while the nanny has an accepted/active trial OR an active hire. It is an
 * "engaged" marker so clients never need a global `trials`/`hires` status query
 * (those queries fail security rules: parties may only read their own docs).
 *
 * NOTE: family Browse does NOT hide on this flag. Product rule: hired nannies and
 * nannies on a live trial stay visible and are only ordered by match %. Do not
 * reintroduce hiding on it without a product decision.
 */
export async function recomputeNannyBrowseHidden(nannyId: string): Promise<void> {
  if (!nannyId) return;
  const db = admin.firestore();
  const [trials, hires, nannySnap] = await Promise.all([
    db
      .collection('trials')
      .where('nannyId', '==', nannyId)
      .where('status', 'in', ['active', 'accepted'])
      .limit(1)
      .get(),
    db
      .collection('hires')
      .where('nannyId', '==', nannyId)
      .where('status', '==', 'active')
      .limit(1)
      .get(),
    db.collection('nannies').doc(nannyId).get(),
  ]);
  const hired = !hires.empty;
  const hidden = !trials.empty || hired;

  // While hired, remember the availability she had when she was hired. Browse
  // keeps her listed until she changes it herself, then hides her until the
  // hire ends. Take the snapshot once (first recompute during the hire) and
  // clear it when the hire is over.
  const data = nannySnap.data() ?? {};
  const update: Record<string, unknown> = { hiddenFromBrowse: hidden };
  if (!hired) update.hireAvailabilityKey = admin.firestore.FieldValue.delete();
  else if (!data.hireAvailabilityKey) update.hireAvailabilityKey = availabilityKey(data);

  await db.collection('nannies').doc(nannyId).set(update, { merge: true });
}

/// Which nannies need their engaged-marker recomputed: everyone with an active
/// hire (so a nanny hired before the availability snapshot existed gets one),
/// plus everyone still flagged (so a stale flag/snapshot is cleared). Pure.
export function nannyIdsToReconcile(
  activeHireNannyIds: Array<string | undefined | null>,
  flaggedNannyIds: string[],
): string[] {
  const ids = new Set<string>();
  for (const id of [...activeHireNannyIds, ...flaggedNannyIds]) {
    if (typeof id === 'string' && id) ids.add(id);
  }
  return [...ids];
}

/// Re-runs [recomputeNannyBrowseHidden] for every engaged nanny. Returns how
/// many were processed. One bad record never stops the rest.
export async function reconcileBrowseVisibility(): Promise<number> {
  const db = admin.firestore();
  const [hires, flagged] = await Promise.all([
    db.collection('hires').where('status', '==', 'active').get(),
    db.collection('nannies').where('hiddenFromBrowse', '==', true).get(),
  ]);
  const ids = nannyIdsToReconcile(
    hires.docs.map((d) => d.data().nannyId as string | undefined),
    flagged.docs.map((d) => d.id),
  );
  for (const id of ids) {
    try {
      await recomputeNannyBrowseHidden(id);
    } catch (e) {
      console.error(`[browseVisibilityReconciler] ${id}`, e);
    }
  }
  return ids.length;
}
