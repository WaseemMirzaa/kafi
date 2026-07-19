import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

/// The subset of a family doc that decides contact entitlement.
export interface ContactEntitlementInput {
  subscription?: { status?: string } | null;
  viewedProfiles?: unknown;
  activeTrialNannyIds?: unknown;
}

/// A family may see a nanny's contact if it (a) has an active or cancelled
/// (still-in-period) subscription, (b) has an active trial with that nanny, or
/// (c) has already spent a free contact on them (the nanny is in
/// `viewedProfiles`). Pure — no Firestore — so the security-critical decision
/// can be unit tested. Non-array history fields are treated as empty.
export function isContactEntitled(fam: ContactEntitlementInput, nannyId: string): boolean {
  const status = fam.subscription?.status;
  const subscribed = status === 'active' || status === 'cancelled';
  const viewed =
    Array.isArray(fam.viewedProfiles) && (fam.viewedProfiles as string[]).includes(nannyId);
  const activeTrial =
    Array.isArray(fam.activeTrialNannyIds) &&
    (fam.activeTrialNannyIds as string[]).includes(nannyId);
  return subscribed || viewed || activeTrial;
}

/// Privacy-gated contact reveal. A family requests a nanny's phone by creating
/// `contactReveals/{familyId}_{nannyId}` (it cannot read the nanny's `users` doc
/// directly — the rules forbid it). This trigger checks the family is entitled
/// (active/cancelled subscription, an active trial with that nanny, or the nanny
/// is already in viewedProfiles — i.e. a free contact was spent) and, only then,
/// writes back JUST the phone. Nothing else from the nanny's user doc is exposed.
export const onContactRevealRequested = onDocumentCreated(
  'contactReveals/{revealId}',
  async (event) => {
    const req = event.data?.data();
    const familyId = req?.familyId as string | undefined;
    const nannyId = req?.nannyId as string | undefined;
    if (!familyId || !nannyId) return;

    const db = admin.firestore();
    const ref = event.data!.ref;

    const fam = (await db.collection('families').doc(familyId).get()).data() ?? {};
    if (!isContactEntitled(fam, nannyId)) {
      await ref.set({ status: 'denied', reason: 'paywall' }, { merge: true });
      return;
    }

    const nannyUser = (await db.collection('users').doc(nannyId).get()).data() ?? {};
    const phone = (nannyUser.phone as string) || '';
    await ref.set({ status: 'revealed', phone }, { merge: true });
  },
);
