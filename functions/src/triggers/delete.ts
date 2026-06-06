import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { getStorage } from 'firebase-admin/storage';

/// Per System Spec §6.9 — when a user document is deleted, cascade-delete
/// chats, trials, applications, and shortlists belonging to that user.
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
        .then((s) => Promise.all(s.docs.map((d) => _deleteThread(d.ref))))
    );
    tasks.push(
      db
        .collection('chatThreads')
        .where('nannyId', '==', userId)
        .get()
        .then((s) => Promise.all(s.docs.map((d) => _deleteThread(d.ref))))
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

    // Delete reviews authored by or about the user.
    tasks.push(
      db
        .collection('reviews')
        .where('reviewerId', '==', userId)
        .get()
        .then((s) => _batchDelete(s.docs.map((d) => d.ref)))
    );
    tasks.push(
      db
        .collection('reviews')
        .where('subjectId', '==', userId)
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

async function _deleteThread(ref: FirebaseFirestore.DocumentReference) {
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
