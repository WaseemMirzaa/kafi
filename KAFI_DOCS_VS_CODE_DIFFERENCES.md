# Kafi — Docs vs Code Differences

All differences between the three specification documents (`KAFI_APP_DOCUMENTATION.md`, `KAFI_SYSTEM_SPECIFICATION.md`, `KAFI_TECHNICAL_ARCHITECTURE.md`) and the actual codebase.

---

## Admin Panel

| # | What the docs say | What the code actually has |
|---|-------------------|---------------------------|
| 1 | No disputes section mentioned anywhere | Full `/disputes` route in `App.tsx` + `DisputeService` (`list`, `resolve`) in `firestore.ts` + sidebar link — completely undocumented feature |
| 2 | No admin override capabilities mentioned | `FamilyService.overrideSubscription()` lets admin manually set plan/status/endDate; `FamilyService.resetFreeContacts()` resets free contact count back to 0 |
| 3 | Video review bundled with document review | `introVideoStatus` is a separate field (`'pending' \| 'approved' \| 'rejected'`) with its own distinct workflow via `NannyService.reviewVideo()` |
| 4 | Revenue trend data described as live from Firestore | Sparkline/trend chart data is a hardcoded static array (Jan–Jun percentages) in `RevenueService.summary()` regardless of live or mock mode |

---

## Mobile App — Navigation & Screens

| # | What the docs say | What the code actually has |
|---|-------------------|---------------------------|
| 5 | Each screen has its own dedicated route | `/chat` and `/settings` both resolve to `FamilyShellScreen` (tab-based shell). Same for `/nanny-home` and `/nanny-jobs` → `NannyShellScreen` |
| 6 | 38 screens documented with individual routes | Several screens are tabs inside shell screens, not standalone routes — `FamilyShellController` and `NannyShellController` manage the active tab index |

---

## Mobile App — Models & Data

| # | What the docs say | What the code actually has |
|---|-------------------|---------------------------|
| 7 | Documents stored as Firestore subcollection: `nannies/{nannyId}/documents/{docId}` | Documents are an **embedded array** on the nanny document. `reviewDocument()` patches the array in-place and writes back the parent doc |
| 8 | No lightweight browse card model mentioned | `nanny_card_model.dart` exists as a separate lightweight model for the browse screen (id, name, nationality, yearsExp, matchPercent, tags, etc.) — distinct from the full `NannyModel` |
| 9 | 5 subscription states: `free, active, cancelled, expired, payment_failed` | `SubscriptionState` enum in `family_model.dart` has **6 states**: `free, trial, active, cancelledInPeriod, expired, paymentGrace` — `trial` and `paymentGrace` are additions. `paymentGrace` grants access but shows a warning |
| 10 | `DocumentStatus` implied as `pending, approved, rejected` | Actual `DocumentStatus` enum has **5 values**: `notUploaded, pending, reviewing, approved, rejected` — `reviewing` and `notUploaded` are additions |
| 11 | `DisputeModel` fields: `reporterId, reportedUserId, category, description, status, resolution` | Code also has `relatedTrialId` field — disputes can be linked to a specific trial |

---

## Mobile App — Controllers & Business Logic

| # | What the docs say | What the code actually has |
|---|-------------------|---------------------------|
| 12 | Expired family subscription hides the chat thread list entirely | `ChatController.visibleThreads` returns **all threads** regardless of subscription state. Thread opening (not listing) is gated — expired families are redirected to the paywall when they try to open a thread |
| 13 | Browse nannies uses `IUserService` | `BrowseController` calls `IJobService.browseNannies()` — browse is part of the job service, not user service |
| 14 | `ISubscriptionService` described with rich interface: `watchSubscription()`, `cancelSubscription()`, `restoreSubscription()`, `checkEntitlement()`, etc. | Actual interface is much simpler: `getPlans, getState, freeViewsUsed, recordView, subscribe, setState` — several methods from the spec don't exist |
| 15 | No debug/testing utilities mentioned | `SubscriptionController` has `simulateExpire()` and `simulateRestore()` debug methods (left in the production controller) |
| 16 | Expired family who previously viewed a profile cannot re-view it | `SubscriptionController.recordViewIfAllowed()` lets expired families re-view profiles they had already unlocked (uses stored view history) |

---

## Firestore Collections & Structure

| # | What the docs say | What the code actually has |
|---|-------------------|---------------------------|
| 17 | Collection named `jobPosts` | Code uses `jobs` everywhere (Flutter services, Cloud Functions `delete.ts`, `firestore_job_service.dart`) |
| 18 | Notifications stored as per-user subcollection: `notifications/{userId}/items/{notifId}` | Flat top-level `notifications` collection with a `userId` field — `fcm_notification_service.dart` writes/queries by `userId` field |
| 19 | Shortlists stored as per-user subcollection: `shortlists/{userId}/items/{nannyId}` | Flat top-level `shortlists` collection with `familyId` field. Also side-effect: increments `nannies/{id}.shortlists` counter directly on the nanny document |
| 20 | Security rules reference `nannies/{nannyId}/documents/{docId}` as subcollection | Rules need to be updated — documents are an embedded array, so there is no subcollection to secure separately |

---

## Cloud Functions

| # | What the docs say | What the code actually has |
|---|-------------------|---------------------------|
| 21 | Documented Cloud Functions: `onNewMessage, onNewApplication, onTrialOffered, onTrialResponse, onTrialEnded, onDocumentReviewed, subscriptionExpiredEnforcer, subscriptionExpiringReminder, trialStartingReminder, revenueCatWebhook` | Three **undocumented** functions also exist: `onNannySubmitted` (sends "profile submitted" confirmation push when nanny creates a pending doc), `onBroadcastCreated` (Firestore-triggered broadcast dispatcher), `onUserDeleted` (comprehensive cascade delete) |
| 22 | Broadcast is described as an HTTP function or admin-triggered call | `onBroadcastCreated` is a **Firestore trigger** — admin panel writes a document to `broadcasts` with `status: 'queued'`, which fires the function. It writes `deliveryStats` (including `audienceSize`) back to the document |
| 23 | Broadcast delivery stats: `sent, delivered, opened` | Code writes `audienceSize` in `deliveryStats` — a field not in the spec |
| 24 | Cascade delete on user account deletion described at a high level | `onUserDeleted` is far more comprehensive: deletes Firestore docs across `nannies`, `families`, `jobs`, `applications`, `trials`, `chats`, `messages`, `shortlists`, `notifications`, `reviews`, `disputes` collections, **plus** Firebase Storage files under `users/{id}/`, `nannies/{id}/`, `families/{id}/` paths |
| 25 | `onDocumentReviewed` listens to the documents subcollection | Function listens to the parent **nanny doc** (`nannies/{nannyId}`) — consistent with embedded array approach, not the subcollection path the spec describes |

---

## State Management & Infrastructure

| # | What the docs say | What the code actually has |
|---|-------------------|---------------------------|
| 26 | "Redux Toolkit OR Zustand" for admin panel state management | Admin panel uses **Zustand only** via `useAuthStore` in `hooks/useAuth.ts` |
| 27 | "Offline Mode: Not Supported" | `connectivity_service.dart` exists and monitors network state — used for UX error display when offline |
| 28 | Localization not mentioned in spec | Full bilingual support implemented: `l10n/locales/en_us.dart` + `ar_ae.dart`, `AppTranslations` class fed into `GetMaterialApp` |

---

## Summary

| Category | Count |
|----------|-------|
| Admin Panel | 4 |
| Navigation & Screens | 2 |
| Models & Data Structures | 5 |
| Controllers & Business Logic | 5 |
| Firestore Collections | 4 |
| Cloud Functions | 5 |
| Infrastructure / Other | 3 |
| **Total** | **28** |
