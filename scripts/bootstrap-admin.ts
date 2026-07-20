/**
 * Creates the first Kafi admin when the `admins` collection is empty.
 *
 *   GOOGLE_APPLICATION_CREDENTIALS=./scripts/service-account.json \
 *   npx ts-node --project functions/tsconfig.json scripts/bootstrap-admin.ts
 */
import * as admin from 'firebase-admin';
import { ensureFirstAdmin } from '../functions/src/utils/ensureFirstAdmin';

async function main() {
  if (!admin.apps.length) {
    admin.initializeApp({ credential: admin.credential.applicationDefault() });
  }

  const result = await ensureFirstAdmin();
  if (!result.created) {
    console.log(`Admin already exists (${result.email}, uid=${result.uid}).`);
    console.log('Use scripts/create-admin.ts to reset a password.');
    return;
  }

  console.log('\n=== Kafi admin ready ===');
  console.log(`Email:    ${result.email}`);
  console.log(`Password: ${result.password}`);
  console.log(`UID:      ${result.uid}`);
  console.log('\nSign in at http://localhost:3001/ (admin panel, live mode).');
  console.log('Change this password in Firebase Console → Authentication.\n');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
