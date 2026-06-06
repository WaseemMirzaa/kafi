# KAFI — Complete AI Knowledgebase

> One-stop reference for any AI continuing work on this project.
> Read the three source-of-truth docs for full detail:
> - `KAFI_APP_DOCUMENTATION.md` — screens, UX, functional flows
> - `KAFI_SYSTEM_SPECIFICATION.md` — business rules, data models, system flows
> - `KAFI_TECHNICAL_ARCHITECTURE.md` — Flutter/GetX, Firebase, admin, services

---

## 1. WHAT IS KAFI

A UAE mobile marketplace connecting **nannies/domestic helpers** (free) with **families** (subscription-based). Not an agency — Kafi only facilitates discovery and direct hiring.

**Business model:** RevenueCat subscriptions for families (Weekly AED 89, Monthly AED 239, 2-Month AED 369). Nannies use the platform 100% free.

---

## 2. PROJECT STRUCTURE

```
Nannies app/
├── kafi_app/              # Flutter mobile app (GetX state management)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/        # routes, app_config (USE_MOCK flag), firebase_config
│   │   ├── bindings/      # GetX dependency injection
│   │   ├── controllers/   # 15 GetX controllers
│   │   ├── models/        # 14 Dart models
│   │   ├── services/
│   │   │   ├── interfaces/  # Abstract service contracts
│   │   │   ├── mock/        # Mock implementations (dev mode)
│   │   │   └── firebase/    # Real Firebase implementations
│   │   ├── views/
│   │   │   ├── auth/       # Welcome, login, OTP, password screens
│   │   │   ├── nanny/      # Dashboard, onboarding, jobs, profile
│   │   │   ├── family/     # Browse, chat, trial, pricing, settings
│   │   │   ├── shared/     # Theme, placeholders, delete account
│   │   │   ├── legal/      # Terms, privacy
│   │   │   └── widgets/    # Reusable widget kit (kafi_*)
│   │   ├── l10n/          # Localization (app_strings.dart + locales/)
│   │   └── utils/         # Constants, smart_match, helpers
│   └── pubspec.yaml
├── admin-panel/           # React admin dashboard (Vite + Tailwind + Zustand)
│   └── src/
│       ├── pages/         # 11 page components
│       ├── components/    # Layout, UI primitives
│       ├── services/      # Firestore service layer
│       ├── hooks/         # useAuth
│       ├── config/        # app.ts (useMock), firebase.ts
│       └── stores/        # Zustand stores
├── functions/             # Firebase Cloud Functions (v2)
│   └── src/
│       ├── index.ts       # Export barrel
│       └── triggers/      # chat, trial, nanny, scheduled, webhook, broadcast, delete
├── KAFI_APP_DOCUMENTATION.md
├── KAFI_SYSTEM_SPECIFICATION.md
├── KAFI_TECHNICAL_ARCHITECTURE.md
├── firestore.rules
├── storage.rules
├── firebase.json
└── firestore.indexes.json
```

---

## 3. TECH STACK

| Layer | Technology |
|-------|------------|
| Mobile | Flutter 3.35.7 (via FVM) + Dart |
| State | GetX (controllers, routes, DI, l10n) |
| Backend | Firebase (Firestore, Auth, Storage, FCM) |
| Subscriptions | RevenueCat SDK |
| Admin Panel | React 18 + TypeScript + Vite + TailwindCSS + Zustand |
| Cloud Functions | Firebase Functions v2 (TypeScript) |
| Maps/Location | Google Maps Flutter + Places API + Geolocator |

**Mode switching:** `USE_MOCK` flag in `main.dart` switches between real Firebase and local mock data. Admin panel uses `VITE_USE_MOCK` env var.

---

## 4. USER ROLES

| Role | Access | Revenue |
|------|--------|---------|
| **Nanny** | 100% free forever. Create profile, browse jobs, apply, chat, accept trials. | None |
| **Family (Free)** | Browse nannies, 5 free profile views, limited chat after view. Phone/CV/trial locked. | None |
| **Family (Subscribed)** | Unlimited views, phone numbers, CV, chat, trial offers, Call/WhatsApp. | Subscription fees |
| **Family (Expired)** | Lockdown: chats hidden, phones re-blurred, trials blocked. Data preserved, restored on renewal. Exception: active trial keeps access. | Renewal target |
| **Admin** | Web dashboard. Verify docs, review videos, manage users, revenue, broadcasts. | — |

---

## 5. WHAT IS BUILT (Implementation Status)

### 5.1 Flutter Mobile App — DONE

**Auth (Screens 1–5):**
- Welcome/role selection, nanny login, family login, OTP verify (mock OTP: 1234), create password, password reset
- Phone auth via Firebase, returning user password login, forgot password OTP flow

**Nanny (Screens 6–12, 24, 25, 27A):**
- 6-step onboarding: personal info, media upload, experience, references, documents, pending review
- Dashboard with profile quality score
- Jobs home, job detail with match score, advanced filters
- My applications (statuses: pending, viewed, trial offered, declined, withdrawn)
- Edit profile (all fields hydrated: DOB, nationality, languages, visa, EID, emirates, area, marital, children, health, comfort, religion, emergency, bio)
- Nanny shell (bottom nav: Home, Jobs, Messages, Profile)

**Family (Screens 13–19, 26, 27B, 31, 32):**
- Job post form (family info, religion, role, duties, benefits, salary, trial, visa)
- Browse nannies with filter pills, search, nanny cards
- Profile: locked view, unlocked view, re-locked view (expired subscription)
- Chat: full messaging, image attachments, system messages, trial offer bubbles (accept/decline/counter)
- Trial: create offer, send, nanny response, active trial screen with countdown, evaluation, hire/pass
- Pricing screen (3 plans + VAT breakdown)
- Shortlist, compare nannies (side-by-side)
- Family edit profile (Screen 27B)
- Family shell (bottom nav: Home, Search, Messages, Profile)
- Settings (notifications, privacy, subscription, language, support, legal)
- Notifications center

**Shared:**
- Smart match scoring (5 criteria: language 25%, experience 20%, role 20%, visa 15%, salary 20%)
- Uber-style Google Places location picker (UAE-biased, GPS + autocomplete)
- Delete account (2-step: reason + type DELETE confirmation)
- Terms & conditions, privacy policy
- 90-day inactivity auto-logout (SessionMonitor)
- Connectivity service
- Full permission handling (camera, photos, mic, location, notifications, contacts)
- FCM: foreground, background, onTokenRefresh, deep-link navigation
- Error handling: AppError hierarchy, ErrorHandler with snackbars

**Localization:**
- English (en_us.dart) — complete
- Arabic stubs (ar_ae.dart) — key UI strings, not fully translated
- GetX `.tr` pattern used throughout

### 5.2 Admin Panel — DONE

11 pages running on Vite (port 3001):
- Login (Firebase auth + admin custom claim check; mock: `admin@kafi.ae` / `admin123`)
- Dashboard (live stats from services, nanny/family tables, nationality/city breakdown)
- All Nannies, Nanny Detail
- Verify Documents (per-document approve/reject)
- Review Videos (separate from profile approval; patches `introVideoStatus` only)
- All Families, Family Detail
- Subscriptions
- Revenue (CSV export)
- Broadcast (FCM dispatch, audience targeting: all/nannies/families/subscribers)
- Disputes (resolve flow)
- Settings

Service layer: `admin-panel/src/services/firestore.ts` — covers Nanny/Family/Subscription/Disputes/Broadcast/Settings/Revenue with mock fallback.

### 5.3 Cloud Functions — DONE

| Trigger | File | Purpose |
|---------|------|---------|
| onNewMessage | chat.ts | FCM push to recipient |
| onTrialOffered | trial.ts | FCM to nanny |
| onTrialEnded | trial.ts | Recomputes family `activeTrialNannyIds` |
| onDocumentReviewed | nanny.ts | FCM to nanny (approved/rejected) |
| onUserDeleted | delete.ts | Cascade: chats, trials, applications, shortlists, jobs, notifications, reviews, Storage files |
| onBroadcastQueued | broadcast.ts | Dispatches FCM to target audience, writes deliveryStats |
| scheduledTrialReminder | scheduled.ts | 1-day-before and 2-days-before-end reminders (idempotent) |
| scheduledSubscriptionEnforcer | scheduled.ts | Expires ACTIVE/CANCELLED subscriptions past endDate |
| revenueCatWebhook | webhook.ts | Handles INITIAL_PURCHASE, RENEWAL, CANCELLATION, BILLING_ISSUE, EXPIRATION, PRODUCT_CHANGE; shared-secret auth |

### 5.4 Infrastructure — DONE

- `firestore.rules` — role-based access, admin elevated
- `storage.rules` — user-scoped file access
- `firebase.json` — hosting/functions config
- `firestore.indexes.json` — 12+ composite indexes for all query patterns
- `scripts/set-admin-claims.ts` — seeds admin custom claim + admins collection doc

---

## 6. DATA MODELS (Firestore Collections)

| Collection | Key Fields | Notes |
|------------|-----------|-------|
| `users/{uid}` | phone, userType, password, fcmTokens[], settings | Base for both nanny & family |
| `nannies/{uid}` | fullName, nationality, languages[], visaStatus, documents{}, verificationStatus, profileScore, stats | Extended nanny profile |
| `families/{uid}` | fullName, nationality, city, childrenAges[], subscription{}, freeContactsUsed, viewedProfiles[] | Extended family profile |
| `jobs/{id}` | familyId, jobTitle, rolesNeeded[], duties[], salaryMin/Max, trialDuration, trialDailyRate, status | 7-day auto-expiry |
| `applications/{id}` | jobPostId, nannyId, familyId, status, matchScore, coverMessage | Links nanny to job |
| `trials/{id}` | familyId, nannyId, status, durationDays, dailyRate, startDate, counterOffer?, evaluation? | Full lifecycle: pending→active→completed |
| `chatThreads/{id}` | participants{familyId, nannyId}, lastMessage, unreadCount{}, trialId?, trialStatus? | Thread metadata |
| `chatThreads/{id}/messages/{id}` | senderId, senderType, type, content, attachments[] | Subcollection |
| `notifications/{id}` | userId, type, title, body, data{}, read | Deep-link routing |
| `shortlists/{id}` | familyId, nannyId, addedAt | Favorites |
| `disputes/{id}` | reporterId, reportedUserId, category, relatedTrialId, status | Payment issues, reports |
| `broadcasts/{id}` | title, body, targetAudience, status, deliveryStats | Admin broadcasts |
| `admins/{uid}` | email, name, role, permissions[] | Admin access control |
| `deletionAudits/{uid}` | reason, deletedAt | GDPR audit trail |

---

## 7. KEY BUSINESS FLOWS

### 7.1 Nanny Registration
Welcome → Phone/OTP → Create Password → 6-step onboarding (info, media, experience, refs, docs, pending) → Admin review → Approved → Dashboard visible

### 7.2 Family Registration
Welcome → Phone/OTP → Create Password → Job Post Form → Browse Nannies (5 free views)

### 7.3 Family Browsing & Contact
Browse cards (free) → Tap = use 1 free view → Profile locked (free tier) or unlocked (subscribed) → Chat/Call/WhatsApp/Trial (subscribed only)

### 7.4 Subscription Lockdown (Expired)
Status → EXPIRED → phones re-hidden, chats hidden behind paywall, trials/CV/call blocked → Active trial exception keeps its chat open → Re-subscribe = instant restore

### 7.5 Trial Flow
Family sends offer → Nanny: accept/decline/counter → If accepted: ACTIVE, phones revealed, countdown starts → During trial: evaluation checklist → After trial: Hire or Pass → Nanny confirms payment (or reports issue → dispute created)

### 7.6 Chat
Thread created on first message or profile view → Family: full access when subscribed, locked when expired → Nanny: always has access, sees banner if family expired → Trial offer rendered as special bubble with Accept/Counter buttons → Deep-link from notifications

### 7.7 Smart Match
5 weighted factors: language (25%), experience (20%), role (20%), visa (15%), salary (20%) → Score displayed on browse cards, job details, pre-application check

### 7.8 Account Deletion
Settings → Delete Account → Select reason → Type "DELETE" → Cascade trigger deletes: profile, chats, trials, applications, shortlists, jobs, notifications, reviews, Storage files, Firebase Auth

---

## 8. WHAT IS MISSING / NOT YET IMPLEMENTED

### 8.1 Production Integration (NOT wired — app uses mock mode)

| Item | Status | Notes |
|------|--------|-------|
| **RevenueCat SDK** | Not integrated | Subscription logic exists but uses mock purchases; need real RevenueCat product IDs and SDK initialization |
| **Firebase project** | Config placeholder | `google-services.json` / `GoogleService-Info.plist` need real project credentials |
| **Google Maps API key** | Placeholder | `AppConstants.googleMapsApiKey` needs a real billable key |
| **App Store / Play Store** | Not set up | No store listings, screenshots, or review submissions |
| **Firebase Auth (real SMS)** | Mock OTP only | Real phone auth works but hasn't been tested with production Firebase project |

### 8.2 Features Specified but Not Fully Built

| Feature | Spec Location | Gap |
|---------|--------------|-----|
| **Reviews/Ratings** | §3.10 Review Model | Model exists but no UI for leaving/viewing reviews after trial |
| **Block/Report user** | §14.13 Reporting & Safety | No block/unblock or report-user UI in the mobile app |
| **Content moderation** | §14.14 | No auto-detection of phone numbers in chat/bio |
| **Search & advanced filters (Family browse)** | Screen 14, 24C | Basic filter pills exist; full advanced filter bottom sheet (salary range slider, children ages, visa requirement, start date) not fully built |
| **Nanny compare feature** | Screen 26B | `compare_screen.dart` exists but may be a basic stub |
| **Video call/interview** | Mentioned in notifications | Not in scope |
| **Hiring outcome (post-trial)** | §6.5 | Hire/pass buttons exist but downstream effects (nanny status update, profile changes) may be incomplete |
| **CSV export** | Admin §12.3 | Service has export logic; actual download triggering may need polish |
| **Analytics events** | §12.4 | Firebase Analytics events not explicitly wired in Flutter code |
| **Data export (GDPR)** | §14.20 | No "Export my data" feature for users |
| **App version check / force update** | §14.17 L7 | Not implemented |
| **Maintenance mode** | §14.9 N7 | Not implemented |
| **Arabic RTL layout** | §14.15 I1 | Strings exist but full RTL testing/layout adaptation not done |

### 8.3 UI Polish / UX Gaps

| Area | Notes |
|------|-------|
| Theme matching v8 HTML mockup | Screens built functionally but pixel-perfect match to the HTML mockup not audited for every screen |
| Empty states | Some screens may lack proper empty-state illustrations |
| Loading skeletons | Not consistently applied |
| Animations | Minimal; spec mentions pulsing clock, green checkmark, etc. |
| Responsive/tablet | Not addressed |
| Dark mode | Not in scope |

### 8.4 Testing

| Type | Status |
|------|--------|
| Unit tests | Not written |
| Widget tests | Not written |
| Integration tests | Not written |
| Admin panel tests | Not written |
| Cloud Function tests | Not written |
| E2E / device testing | Manual only (debug mode on Android device) |

### 8.5 Deployment & CI/CD

| Item | Status |
|------|--------|
| CI pipeline (GitHub Actions, etc.) | Not set up |
| Fastlane / app signing | Not set up |
| Firebase Hosting (admin panel) | Not deployed |
| Cloud Functions deployment | Not deployed (local emulator only) |
| App bundle / IPA build | Not generated |

---

## 9. CODING CONVENTIONS & RULES

### 9.1 Flutter (kafi_app)

- **State:** GetX controllers with `Rx` observables; no UI logic in controllers
- **DI:** GetX Bindings (`InitialBinding` registers services based on `USE_MOCK`)
- **Routing:** Named routes in `config/routes.dart`; `Get.toNamed()` / `Get.offAllNamed()`
- **L10n:** All UI text via `AppStrings.key.tr` (never hardcoded); keys in `app_strings.dart`, copy in `locales/en_us.dart`
- **Constants:** Domain constants in `utils/constants/` (not magic numbers in controllers)
- **Services:** Interface → Mock + Firebase implementations; swap via DI
- **Widgets:** Reusable `kafi_*` prefix widgets in `views/widgets/`
- **Theme:** `KafiTheme` + `KafiColors` in `views/shared/`

### 9.2 Admin Panel

- Vite + React 18 + TypeScript
- TailwindCSS for styling
- Zustand for global state
- `AppConfig.useMock` toggle (reads `VITE_USE_MOCK` or defaults to `true` in dev)
- Service layer abstracts Firestore calls with mock fallback
- Firebase Auth + custom claim `admin==true` for access control

### 9.3 Cloud Functions

- Firebase Functions v2 (TypeScript)
- Firestore triggers (`onDocumentCreated`, `onDocumentUpdated`, `onDocumentDeleted`)
- Scheduled functions (`onSchedule`)
- HTTP function for RevenueCat webhook
- Shared `utils/notifications.ts` for FCM dispatch

### 9.4 Documentation Workflow

Per `.cursor/rules/kafi-doc-sync.mdc`:
1. Search docs → confirm scope with user → update docs → then code → log history
2. Never code features that conflict with docs without user approval
3. Append to `## Implementation History` table after each task

---

## 10. HOW TO RUN

### Mobile App (Flutter)
```bash
cd kafi_app
fvm flutter run -d <device-id>   # Android/iOS device
fvm flutter run -d chrome         # Web (limited)
```
Mock mode is default (`USE_MOCK = true` in `main.dart`).

### Admin Panel (React)
```bash
cd admin-panel
npm run dev    # Starts on http://localhost:3001
```
Login: `admin@kafi.ae` / `admin123` (mock mode)

### Cloud Functions (local)
```bash
cd functions
npm run build
firebase emulators:start
```

---

## 11. KEY FILES TO READ FIRST

| Purpose | File |
|---------|------|
| App entry + mock flag | `kafi_app/lib/main.dart` |
| All routes | `kafi_app/lib/config/routes.dart` |
| DI setup | `kafi_app/lib/bindings/initial_binding.dart` |
| Auth flow | `kafi_app/lib/controllers/auth_controller.dart` |
| Subscription/lockdown | `kafi_app/lib/controllers/subscription_controller.dart` |
| Chat logic | `kafi_app/lib/controllers/chat_controller.dart` |
| Trial lifecycle | `kafi_app/lib/controllers/trial_controller.dart` |
| Smart match | `kafi_app/lib/services/match_service.dart` |
| Nanny model | `kafi_app/lib/models/nanny_model.dart` |
| Family model | `kafi_app/lib/models/family_model.dart` |
| L10n keys | `kafi_app/lib/l10n/app_strings.dart` |
| English copy | `kafi_app/lib/l10n/locales/en_us.dart` |
| Admin routes | `admin-panel/src/App.tsx` |
| Admin services | `admin-panel/src/services/firestore.ts` |
| Functions index | `functions/src/index.ts` |
| Firestore security | `firestore.rules` |

---

## 12. SUBSCRIPTION STATE MACHINE

```
FREE ──(purchase)──→ ACTIVE ──(endDate passes)──→ EXPIRED
                       ↑                              │
                       │←──────(re-subscribe)─────────┘
                       │
                       ├──(cancel)──→ CANCELLED ──(endDate)──→ EXPIRED
                       │
                       └──(billing fail)──→ PAYMENT_FAILED (grace)──→ EXPIRED
```

**Lockdown triggers:** EXPIRED or PAYMENT_FAILED (past grace)
**Lockdown effects:** chats hidden, phones blurred, trials/CV/call blocked
**Exception:** ACTIVE trial keeps its specific chat + contacts accessible
**Restore:** Re-subscribing instantly restores all access

---

## 13. TRIAL STATE MACHINE

```
PENDING ──→ ACCEPTED ──→ ACTIVE ──→ COMPLETED ──→ HIRED / NOT_HIRED
   │            ↑
   ├──→ DECLINED
   │
   └──→ COUNTERED ──→ ACCEPTED (family accepts counter)
            │
            └──→ DECLINED (family declines counter)

Any pre-start state ──→ CANCELLED
```

---

## 14. PRIORITY NEXT STEPS (Suggested)

1. **UI polish pass** — Match all screens to v8 HTML mockup (use the skill at `.cursor/skills/kafi-ui-reference/SKILL.md`)
2. **RevenueCat integration** — Wire real SDK, product IDs, entitlement checks
3. **Firebase production project** — Real credentials, deploy functions, test real SMS auth
4. **Reviews UI** — Post-trial review submission and display
5. **Advanced filters** — Full filter bottom sheet for family browse and nanny jobs
6. **Block/Report** — User safety features
7. **Arabic RTL** — Full translation + layout testing
8. **Testing** — Unit tests for controllers/services, widget tests for key flows
9. **CI/CD** — GitHub Actions, Fastlane, automated builds
10. **Store submission** — Screenshots, metadata, first release

---

## 15. ERROR HANDLING REFERENCE

The system spec (§14) documents **250+ error scenarios** across 28 categories:
- Authentication (20 cases)
- Permissions (8 cases)
- File uploads (14 cases)
- Profile validation (15 cases)
- Jobs & applications (10 cases)
- Trials (13 cases)
- Chat (15 cases)
- Subscriptions (20 cases)
- Network (11 cases)
- Free tier restrictions (12 cases)
- Admin panel (8 cases)
- Account deletion (7 cases)
- Reporting & safety (7 cases)
- Content moderation (8 cases)
- i18n (10 cases)
- Accessibility (6 cases)
- App lifecycle (9 cases)
- Deep links (8 cases)
- Search/filter (7 cases)
- Data privacy (5 cases)
- Multi-device (8 cases)
- Input/form (10 cases)
- Trial-specific (10 cases)
- Subscription-specific (10 cases)
- Image/video (10 cases)
- Chat-specific (10 cases)
- Admin-specific (10 cases)
- Recovery/resume (10 cases)

Most are handled in code; some (content moderation, version check, maintenance mode) are not yet implemented.

---

## 16. NOTIFICATION EVENTS

| Category | Events | Recipient |
|----------|--------|-----------|
| Messages | New message | Both |
| Applications | New app, viewed, declined | Nanny / Family |
| Trials | Offer, accepted, declined, counter, starting soon, ending soon, completed | Both |
| Hiring | Hired | Nanny |
| Profile | Viewed, docs approved/rejected, verified | Nanny |
| Subscription | Expiring, renewed, expired, low contacts | Family |
| System | Broadcast announcements | All |

All implemented via Cloud Functions FCM triggers + scheduled jobs.

---

*Last updated: May 26, 2026*
