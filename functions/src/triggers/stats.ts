import { onDocumentCreated, onDocumentDeleted } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

/// Clamps a counter to `>= 0` after applying a delta, tolerating a missing or
/// non-numeric current value. Pure so the floor behaviour can be unit-tested.
export function flooredCount(current: unknown, delta: number): number {
  const n = typeof current === 'number' && Number.isFinite(current) ? current : 0;
  return Math.max(0, n + delta);
}

/// Folds a new rating into a running average. Tolerates missing/garbage current
/// values and rounds to 2 dp. Pure so the math can be unit-tested.
export function nextAverage(
  currentAvg: unknown,
  currentCount: unknown,
  rating: number,
): { averageRating: number; reviewsCount: number } {
  const count =
    typeof currentCount === 'number' && currentCount > 0 ? Math.floor(currentCount) : 0;
  const avg =
    typeof currentAvg === 'number' && Number.isFinite(currentAvg) ? currentAvg : 0;
  const reviewsCount = count + 1;
  const averageRating = (avg * count + rating) / reviewsCount;
  return { averageRating: Math.round(averageRating * 100) / 100, reviewsCount };
}

/// Nanny aggregate stats (`nannies/{id}.stats.*`) are read on the nanny
/// dashboard but must be **server-owned**: the security rules only let a nanny
/// (or admin) write her own doc, so a family shortlisting a nanny cannot touch
/// the nanny's stats from the client. These triggers maintain the counters in
/// response to the family-owned `shortlists/{id}` docs the family *is* allowed
/// to write.

export const onShortlistCreated = onDocumentCreated('shortlists/{shortlistId}', async (event) => {
  const nannyId = event.data?.data()?.nannyId as string | undefined;
  if (!nannyId) return;
  await admin
    .firestore()
    .collection('nannies')
    .doc(nannyId)
    .set({ stats: { shortlists: admin.firestore.FieldValue.increment(1) } }, { merge: true });
});

export const onShortlistDeleted = onDocumentDeleted('shortlists/{shortlistId}', async (event) => {
  const nannyId = event.data?.data()?.nannyId as string | undefined;
  if (!nannyId) return;
  const ref = admin.firestore().collection('nannies').doc(nannyId);
  // Floor at 0 via a transaction so out-of-order events can't drive it negative.
  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const current = (snap.data()?.stats as { shortlists?: unknown } | undefined)?.shortlists;
    tx.set(ref, { stats: { shortlists: flooredCount(current, -1) } }, { merge: true });
  });
});

/// A family records a profile view by creating `profileViews/{familyId}_{nannyId}`
/// (deterministic id → one event per pair). The family can't write its own
/// `viewedProfiles`/`freeContactsUsed` or the nanny's stats (security rules), so
/// this trigger owns both: it burns a free contact only the FIRST time a family
/// views a given nanny, and bumps the nanny's server-owned profileViews stat.
export const onProfileViewed = onDocumentCreated('profileViews/{viewId}', async (event) => {
  const view = event.data?.data();
  const familyId = view?.familyId as string | undefined;
  const nannyId = view?.nannyId as string | undefined;
  if (!familyId || !nannyId) return;
  const db = admin.firestore();

  // Family free-contact accounting — only new views count.
  let isNew = false;
  await db.runTransaction(async (tx) => {
    const ref = db.collection('families').doc(familyId);
    const snap = await tx.get(ref);
    const viewed: string[] = Array.isArray(snap.data()?.viewedProfiles)
      ? (snap.data()!.viewedProfiles as string[])
      : [];
    if (viewed.includes(nannyId)) return;
    isNew = true;
    viewed.push(nannyId);
    tx.set(
      ref,
      { viewedProfiles: viewed, freeContactsUsed: admin.firestore.FieldValue.increment(1) },
      { merge: true },
    );
  });

  if (!isNew) return;
  await db
    .collection('nannies')
    .doc(nannyId)
    .set({ stats: { profileViews: admin.firestore.FieldValue.increment(1) } }, { merge: true });
});

/// A family creates `hires/{hireId}` when it hires a nanny. The rules forbid
/// the family from writing the nanny's doc, so this trigger owns the nanny's
/// server-side `stats.hiresCount`.
export const onHireCreated = onDocumentCreated('hires/{hireId}', async (event) => {
  const nannyId = event.data?.data()?.nannyId as string | undefined;
  if (!nannyId) return;
  await admin
    .firestore()
    .collection('nannies')
    .doc(nannyId)
    .set({ stats: { hiresCount: admin.firestore.FieldValue.increment(1) } }, { merge: true });
});

/// A review of a nanny folds into her server-owned rating aggregate. The rules
/// forbid a reviewer from writing the reviewee's doc, so this trigger owns
/// nannies/{id}.stats.averageRating / reviewsCount.
export const onReviewCreated = onDocumentCreated('reviews/{reviewId}', async (event) => {
  const review = event.data?.data();
  if (!review || review.revieweeType !== 'nanny') return;
  const nannyId = review.revieweeId as string | undefined;
  const rating = typeof review.rating === 'number' ? review.rating : Number(review.rating);
  if (!nannyId || !Number.isFinite(rating)) return;

  const ref = admin.firestore().collection('nannies').doc(nannyId);
  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const stats = (snap.data()?.stats ?? {}) as {
      averageRating?: unknown;
      reviewsCount?: unknown;
    };
    tx.set(ref, { stats: nextAverage(stats.averageRating, stats.reviewsCount, rating) }, {
      merge: true,
    });
  });
});
