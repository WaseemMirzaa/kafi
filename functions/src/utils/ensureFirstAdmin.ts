import * as admin from 'firebase-admin';
import { Locale, tn } from '../i18n/notifications';

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

/// The first admin's password MUST be supplied out-of-band via the
/// `KAFI_ADMIN_BOOTSTRAP_PASSWORD` env var. There is deliberately no fallback:
/// `bootstrapFirstAdmin` is a public endpoint, so a hardcoded default would let
/// anyone who reaches it while `admins` is empty create a superAdmin with a
/// publicly-known password. If the env var is missing/weak the bootstrap fails
/// loudly (surfaced as a 500 to the caller) rather than minting a weak admin.
function resolvePassword(locale: Locale): string {
  const fromEnv = process.env.KAFI_ADMIN_BOOTSTRAP_PASSWORD?.trim();
  if (!fromEnv || fromEnv.length < 8) {
    throw new Error(tn('error.bootstrapPasswordMissing', locale));
  }
  return fromEnv;
}

export async function ensureFirstAdmin(locale: Locale = 'en'): Promise<{
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
  const password = resolvePassword(locale);
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
