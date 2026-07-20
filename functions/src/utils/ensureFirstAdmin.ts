import * as admin from 'firebase-admin';

const DEFAULT_EMAIL = 'admin@kafi.ae';
const DEFAULT_DISPLAY = 'Kafi Admin';

const ADMIN_PERMISSIONS = [
  'verifyNanny',
  'reviewDocuments',
  'manageFamily',
  'manageSubscription',
  'broadcast',
  'resolveDispute',
  'editSettings',
];

function resolvePassword(): string {
  const fromEnv = process.env.KAFI_ADMIN_BOOTSTRAP_PASSWORD?.trim();
  if (fromEnv && fromEnv.length >= 8) return fromEnv;
  return 'Kafi@Admin2026!';
}

export async function ensureFirstAdmin(): Promise<{
  created: boolean;
  email: string;
  password?: string;
  uid?: string;
}> {
  const db = admin.firestore();
  const auth = admin.auth();

  const existing = await db.collection('admins').limit(1).get();
  if (!existing.empty) {
    const doc = existing.docs[0].data();
    return {
      created: false,
      email: (doc.email as string) ?? DEFAULT_EMAIL,
      uid: existing.docs[0].id,
    };
  }

  const email = process.env.KAFI_ADMIN_BOOTSTRAP_EMAIL?.trim() || DEFAULT_EMAIL;
  const password = resolvePassword();
  const displayName =
    process.env.KAFI_ADMIN_BOOTSTRAP_NAME?.trim() || DEFAULT_DISPLAY;

  let user: admin.auth.UserRecord;
  try {
    user = await auth.getUserByEmail(email);
    user = await auth.updateUser(user.uid, { password, displayName, emailVerified: true });
  } catch {
    user = await auth.createUser({
      email,
      password,
      displayName,
      emailVerified: true,
    });
  }

  await auth.setCustomUserClaims(user.uid, {
    ...(user.customClaims || {}),
    admin: true,
    role: 'superAdmin',
  });

  await db.collection('admins').doc(user.uid).set(
    {
      uid: user.uid,
      email: user.email,
      displayName,
      role: 'superAdmin',
      permissions: ADMIN_PERMISSIONS,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: null,
      bootstrappedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { created: true, email, password, uid: user.uid };
}
