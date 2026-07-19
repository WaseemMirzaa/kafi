import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

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
    const sub = (fam.subscription ?? {}) as { status?: string };
    const subscribed = sub.status === 'active' || sub.status === 'cancelled';
    const viewed =
      Array.isArray(fam.viewedProfiles) && (fam.viewedProfiles as string[]).includes(nannyId);
    const activeTrial =
      Array.isArray(fam.activeTrialNannyIds) &&
      (fam.activeTrialNannyIds as string[]).includes(nannyId);

    if (!subscribed && !viewed && !activeTrial) {
      await ref.set({ status: 'denied', reason: 'paywall' }, { merge: true });
      return;
    }

    const nannyUser = (await db.collection('users').doc(nannyId).get()).data() ?? {};
    const phone = (nannyUser.phone as string) || '';
    await ref.set({ status: 'revealed', phone }, { merge: true });
  },
);
