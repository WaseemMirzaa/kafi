# Admin Panel — Go Live

The admin panel already supports **both mock and live Firebase**; going live is
**configuration, not code**. Block/unblock, document approve/reject, intro-video
review, full nanny profile display, subscription overrides, free-contact reset,
broadcasts, disputes, and revenue are all already implemented for live mode.

## 1. Firebase config (`.env`)

Create `admin-panel/.env` (see `.env.example`):

```
VITE_USE_MOCK=false
VITE_FIREBASE_API_KEY=...
VITE_FIREBASE_AUTH_DOMAIN=...
VITE_FIREBASE_PROJECT_ID=...
VITE_FIREBASE_STORAGE_BUCKET=...
VITE_FIREBASE_MESSAGING_SENDER_ID=...
VITE_FIREBASE_APP_ID=...
```

- `npm run dev` defaults to **mock** unless `VITE_USE_MOCK=false`.
- `vite build` (production) defaults to **live** automatically (`useMock = !DEV`).

## 2. Seed an admin (credentials in Firestore + custom claim)

Admin accounts are authorized against the Firestore **`admins/{uid}`** record
(`src/hooks/useAuth.ts` reads it and rejects anyone without one). The password
lives in Firebase Auth; the admin record (email, role, permissions) lives in
Firestore. The `admin: true` custom claim is also set because the
Firestore/Storage rules require it for approve/reject/block writes.

Create everything in one step (creates the Auth account **and** the Firestore
record + claim), with service-account credentials:

```
GOOGLE_APPLICATION_CREDENTIALS=./service-account.json \
  npx ts-node scripts/create-admin.ts admin@kafi.ae 'StrongPassword123!' 'Kafi Admin'
```

**Automatic first-time setup (no service account):** deploy Cloud Functions, then
open the admin login page in live mode (`VITE_USE_MOCK=false`). It calls
`bootstrapFirstAdmin`, which creates the first admin only when `admins` is empty
and shows the credentials on screen once.

Default bootstrap credentials (unless overridden by env on the function):

- Email: `admin@kafi.ae`
- Password: `Kafi@Admin2026!`

Or run locally with a service account:

```
GOOGLE_APPLICATION_CREDENTIALS=./scripts/service-account.json \
  npx ts-node --project functions/tsconfig.json scripts/bootstrap-admin.ts
```

Then sign in to the panel with that email/password. (`scripts/set-admin-claims.ts`
still exists for granting admin to an already-created Auth user.) After the first
run the user may need to sign out/in once so the claim propagates.

## 3. Deploy rules/indexes

```
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## 4. Features already wired for live

- **Verify documents** — approve/reject per document and approve the whole
  profile; the mobile app reflects it live via `watchNanny`. Documents render
  by format: images inline, videos in a `<video>` player, PDFs in a viewer, and
  other formats as a download card (`components/nanny/DocFilePreview.tsx`).
- **Block / unblock** nannies + families — writes `blocked` on the doc. The
  mobile app **enforces** this live: a blocked user is routed to a logout-only
  "account disabled — contact admin" screen (via `IUserService.watchBlocked`),
  both at startup and mid-session, and gets an FCM "account disabled" push.
- Full nanny profile (all fields), intro-video review, subscription override,
  free-contact reset, broadcasts, disputes, revenue dashboards.

## App side

The mobile app runs live when `kafi_app/lib/config/app_config.dart` has
`useMock = false` (already set) and the platform Firebase config files are
present — see `kafi_app/FIREBASE_SETUP.md`.
