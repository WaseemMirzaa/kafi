/**
 * One-time C5 migration — move sensitive KYC document download URLs off the
 * world-readable `nannies/{id}` doc and into the private
 * `nannies/{id}/documents/{type}` subcollection (owner/admin only).
 *
 * For every nanny whose embedded `documents[]` array still carries a `url`, it:
 *   1. writes `{ type, url, updatedAt }` to `nannies/{id}/documents/{type}`, and
 *   2. rewrites the parent `documents[]` array with the `url` field stripped.
 *
 * The app already writes new uploads the correct way; this backfills pre-C5
 * data. Idempotent — safe to re-run (nannies with no embedded urls are skipped).
 *
 * Run from project root:
 *
 *   GOOGLE_APPLICATION_CREDENTIALS=./service-account.json \
 *   npx ts-node scripts/migrate-doc-urls.ts [--dry-run]
 */
import * as admin from 'firebase-admin';

interface DocEntry {
  type?: string;
  url?: string;
  [k: string]: unknown;
}

async function main() {
  const dryRun = process.argv.includes('--dry-run');

  if (!admin.apps.length) {
    admin.initializeApp({ credential: admin.credential.applicationDefault() });
  }
  const db = admin.firestore();

  const snap = await db.collection('nannies').get();
  let migrated = 0;
  let urlsMoved = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const docs: DocEntry[] = Array.isArray(data.documents) ? data.documents : [];
    const withUrls = docs.filter((d) => d.type && d.url);
    if (withUrls.length === 0) continue;

    if (dryRun) {
      console.log(`[dry-run] ${doc.id}: would move ${withUrls.length} url(s)`);
      migrated++;
      urlsMoved += withUrls.length;
      continue;
    }

    // 1. Write each url into the private subcollection.
    await Promise.all(
      withUrls.map((d) =>
        doc.ref.collection('documents').doc(d.type as string).set(
          { type: d.type, url: d.url, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
          { merge: true },
        ),
      ),
    );

    // 2. Strip `url` from the embedded array on the parent doc.
    const stripped = docs.map((d) => {
      const copy = { ...d };
      delete copy.url;
      return copy;
    });
    await doc.ref.update({ documents: stripped });

    migrated++;
    urlsMoved += withUrls.length;
    console.log(`${doc.id}: moved ${withUrls.length} url(s) to subcollection`);
  }

  console.log(
    `\nDone. ${migrated} nanny doc(s) ${dryRun ? 'would be' : ''} migrated, ${urlsMoved} url(s) moved.`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
