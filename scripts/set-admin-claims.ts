/**
 * Admin seed script — gives a Firebase Auth user the `admin: true` custom claim
 * and writes a matching `admins/{uid}` document, per System Spec §11.5 / §3.11.
 *
 * Run from project root:
 *
 *   GOOGLE_APPLICATION_CREDENTIALS=./service-account.json \
 *   npx ts-node scripts/set-admin-claims.ts admin@kafi.ae
 *
 * The first argument is the admin's email. The user must already exist in
 * Firebase Auth (e.g. created via the Firebase console).
 */
import * as admin from 'firebase-admin';

async function main() {
  const email = process.argv[2];
  if (!email) {
    console.error('Usage: ts-node scripts/set-admin-claims.ts <email>');
    process.exit(1);
  }

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
  }

  const user = await admin.auth().getUserByEmail(email);
  console.log(`Found user ${user.uid} (${user.email})`);

  await admin.auth().setCustomUserClaims(user.uid, {
    ...(user.customClaims || {}),
    admin: true,
    role: 'superAdmin',
  });
  console.log(`Set custom claim admin=true on ${user.uid}`);

  const db = admin.firestore();
  await db.collection('admins').doc(user.uid).set(
    {
      uid: user.uid,
      email: user.email,
      role: 'superAdmin',
      permissions: [
        'verifyNanny',
        'reviewDocuments',
        'manageFamily',
        'manageSubscription',
        'broadcast',
        'resolveDispute',
        'editSettings',
      ],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: null,
    },
    { merge: true }
  );

  console.log('Admin seed complete. The user will need to re-login for claims to take effect.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
