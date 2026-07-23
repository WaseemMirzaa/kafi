import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { getStorage } from 'firebase-admin/storage';

/// Per System Spec §6.9 — when a user document is deleted, cascade-delete every
/// collection that references the user: chat threads, trials, applications,
/// shortlists, job posts, notifications, disputes (+messages), support tickets
/// (+messages), hires, profileViews and contactReveals, plus the profile docs,
/// Auth account and Storage folders. (`deletionAudits` is intentionally retained
/// — it is the admin-readable record of why the user left.)
export const onUserDeleted = onDocumentDeleted(
  'users/{userId}',
  async (event) => {
    const userId = event.params.userId;
    const db = admin.firestore();

    // Best-effort cascade. We swallow errors per collection so a single
    // missing reference does not block the rest.
    const tasks: Promise<unknown>[] = [];

    // Delete chat threads for both family and nanny. The Flutter client
    // writes to `chatThreads` (see `firestore_chat_service.dart`), so the
    // cascade must use the same collection name.
    tasks.push(
      db
        .collection('chatThreads')
        .where('familyId', '==', userId)
        .get()
        .then((s) => Promise.all(s.docs.map((d) => _deleteWithMessages(d.ref))))
    );
    tasks.push(
      db
        .collection('chatThreads')
        .where('nannyId', '==', userId)
        .get()
        .then((s) => Promise.all(s.docs.map((d) => _deleteWithMessages(d.ref))))
    );

    // Delete trials.
    tasks.push(
      db
        .collection('trials')
        .where('familyId', '==', userId)
        .get()
        .then((s) => _batchDelete(s.docs.map((d) => d.ref)))
    );
    tasks.push(
      db
        .collection('trials')
        .where('nannyId', '==', userId)
        .get()
        .then((s) => _batchDelete(s.docs.map((d) => d.ref)))
    );

    // Delete applications (both as nanny and as the target family).
    tasks.push(
      db
        .collection('applications')
        .where('nannyId', '==', userId)
        .get()
        .then((s) => _batchDelete(s.docs.map((d) => d.ref)))
    );
    tasks.push(
      db
        .collection('applications')
        .where('familyId', '==', userId)
        .get()
        .then((s) => _batchDelete(s.docs.map((d) => d.ref)))
    );

    // Delete shortlist entries (families keep nannies they shortlisted).
    tasks.push(
      db
        .collection('shortlists')
        .where('familyId', '==', userId)
        .get()
        .then((s) => _batchDelete(s.docs.map((d) => d.ref)))
    );
    tasks.push(
      db
        .collection('shortlists')
        .where('nannyId', '==', userId)
        .get()
        .then((s) => _batchDelete(s.docs.map((d) => d.ref)))
    );

    // Delete the family's job posts.
    tasks.push(
      db
        .collection('jobs')
        .where('familyId', '==', userId)
        .get()
        .then((s) => _batchDelete(s.docs.map((d) => d.ref)))
    );

    // Delete the user's notification inbox.
    tasks.push(
      db
        .collection('notifications')
        .where('userId', '==', userId)
        .get()
        .then((s) => _batchDelete(s.docs.map((d) => d.ref)))
    );

    // Delete disputes filed BY or ABOUT the user, plus their support-chat
    // messages (reporter description + chat are PII that must not survive the
    // account, and orphaned rows clutter the admin safety queue).
    tasks.push(
      db
        .collection('disputes')
        .where('reporterId', '==', userId)
        .get()
        .then((s) => Promise.all(s.docs.map((d) => _deleteWithMessages(d.ref))))
    );
    tasks.push(
      db
        .collection('disputes')
        .where('reportedUserId', '==', userId)
        .get()
        .then((s) => Promise.all(s.docs.map((d) => _deleteWithMessages(d.ref))))
    );

    // Delete support tickets the user opened, plus their message subcollection.
    tasks.push(
      db
        .collection('tickets')
        .where('openerId', '==', userId)
        .get()
        .then((s) => Promise.all(s.docs.map((d) => _deleteWithMessages(d.ref))))
    );

    // Delete employment (hire) records for either side.
    tasks.push(
      db
        .collection('hires')
        .where('familyId', '==', userId)
        .get()
        .then((s) => _batchDelete(s.docs.map((d) => d.ref)))
    );
    tasks.push(
      db
        .collection('hires')
        .where('nannyId', '==', userId)
        .get()
        .then((s) => _batchDelete(s.docs.map((d) => d.ref)))
    );

    // Delete free-contact accounting (profileViews) for either side.
    tasks.push(
      db
        .collection('profileViews')
        .where('familyId', '==', userId)
        .get()
        .then((s) => _batchDelete(s.docs.map((d) => d.ref)))
    );
    tasks.push(
      db
        .collection('profileViews')
        .where('nannyId', '==', userId)
        .get()
        .then((s) => _batchDelete(s.docs.map((d) => d.ref)))
    );

    // Delete gated phone-reveal events for either side.
    tasks.push(
      db
        .collection('contactReveals')
        .where('familyId', '==', userId)
        .get()
        .then((s) => _batchDelete(s.docs.map((d) => d.ref)))
    );
    tasks.push(
      db
        .collection('contactReveals')
        .where('nannyId', '==', userId)
        .get()
        .then((s) => _batchDelete(s.docs.map((d) => d.ref)))
    );

    // Delete family or nanny profile docs.
    tasks.push(db.collection('families').doc(userId).delete().catch(() => {}));
    tasks.push(db.collection('nannies').doc(userId).delete().catch(() => {}));

    // Best-effort delete Auth account (in case it survived the client side).
    tasks.push(admin.auth().deleteUser(userId).catch(() => {}));

    // Delete all Firebase Storage files under users/{userId}/ and nannies/{userId}/
    tasks.push(_deleteStorageFolder(`users/${userId}/`));
    tasks.push(_deleteStorageFolder(`nannies/${userId}/`));
    tasks.push(_deleteStorageFolder(`families/${userId}/`));

    await Promise.all(tasks);
  }
);

async function _deleteWithMessages(ref: FirebaseFirestore.DocumentReference) {
  const messages = await ref.collection('messages').get();
  await _batchDelete(messages.docs.map((d) => d.ref));
  await ref.delete().catch(() => {});
}

async function _deleteStorageFolder(prefix: string) {
  try {
    const bucket = getStorage().bucket();
    const [files] = await bucket.getFiles({ prefix });
    if (files.length === 0) return;
    await Promise.all(files.map((f) => f.delete().catch(() => {})));
  } catch {
    // Best-effort — don't block the cascade
  }
}

async function _batchDelete(refs: FirebaseFirestore.DocumentReference[]) {
  if (!refs.length) return;
  const db = admin.firestore();
  // Firestore batches max 500 ops.
  for (let i = 0; i < refs.length; i += 450) {
    const batch = db.batch();
    refs.slice(i, i + 450).forEach((r) => batch.delete(r));
    await batch.commit().catch(() => {});
  }
}
