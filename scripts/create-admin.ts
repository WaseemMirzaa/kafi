/**
 * Creates (or updates) a Kafi admin end-to-end:
 *   1. a Firebase Auth account with an email + password,
 *   2. a matching `admins/{uid}` record in Firestore — the source of truth the
 *      admin panel authorizes against (see admin-panel/src/hooks/useAuth.ts),
 *   3. the `admin: true` custom claim the Firestore/Storage rules require for
 *      approve/reject/block writes.
 *
 * The password lives in Firebase Auth (never stored in plaintext); the admin
 * *record* (email, role, permissions) lives in Firestore.
 *
 * Run from the project root with a service-account key:
 *
 *   GOOGLE_APPLICATION_CREDENTIALS=./service-account.json \
 *   npx ts-node scripts/create-admin.ts admin@kafi.ae 'StrongPassword123!' 'Kafi Admin'
 */
import * as admin from 'firebase-admin';

async function main() {
  const email = process.argv[2];
  const password = process.argv[3];
  const displayName = process.argv[4] ?? 'Kafi Admin';

  if (!email || !password) {
    console.error(
      "Usage: ts-node scripts/create-admin.ts <email> <password> [displayName]",
    );
    process.exit(1);
  }
  if (password.length < 8) {
    console.error('Password must be at least 8 characters.');
    process.exit(1);
  }

  if (!admin.apps.length) {
    admin.initializeApp({ credential: admin.credential.applicationDefault() });
  }
  const auth = admin.auth();
  const db = admin.firestore();

  // Create the Auth account, or update the password if it already exists.
  let user: admin.auth.UserRecord;
  try {
    user = await auth.getUserByEmail(email);
    user = await auth.updateUser(user.uid, { password, displayName });
    console.log(`Updated existing user ${user.uid} (${email})`);
  } catch {
    user = await auth.createUser({ email, password, displayName, emailVerified: true });
    console.log(`Created user ${user.uid} (${email})`);
  }

  await auth.setCustomUserClaims(user.uid, {
    ...(user.customClaims || {}),
    admin: true,
    role: 'superAdmin',
  });
  console.log(`Set custom claim admin=true on ${user.uid}`);

  await db.collection('admins').doc(user.uid).set(
    {
      uid: user.uid,
      email: user.email,
      displayName,
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
    { merge: true },
  );

  console.log('Admin ready. Sign in to the admin panel with these credentials.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
