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

## 2. Seed an admin (Firebase Auth + custom claim)

Admin login uses Firebase Auth and requires an `admin: true` custom claim
(checked in `src/hooks/useAuth.ts`).

1. Create the admin user in Firebase Auth (email/password).
2. Run `scripts/set-admin-claims.ts` with service-account credentials — it sets
   the `admin` claim and creates `admins/{uid}` (role + permissions).
3. The admin signs out/in once so the new claim takes effect.

## 3. Deploy rules/indexes

```
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## 4. Features already wired for live

- **Verify documents** — approve/reject per document; the mobile app reflects it
  live via `watchNanny` (pending → approved/rejected screen).
- **Block / unblock** nannies + families — writes `blocked` on the doc. The
  mobile app now **enforces** this: a blocked user is signed out at login with a
  localized "account blocked" message (`IUserService.isUserBlocked`).
- Full nanny profile (all fields), intro-video review, subscription override,
  free-contact reset, broadcasts, disputes, revenue dashboards.

## App side

The mobile app runs live when `kafi_app/lib/config/app_config.dart` has
`useMock = false` (already set) and the platform Firebase config files are
present — see `kafi_app/FIREBASE_SETUP.md`.
