# Kafi Mobile — Backend Implementation Plan (screen‑by‑screen, both flows)

Purpose: a concrete, evidence‑based plan to make **every screen of both journeys work end‑to‑end against live Firebase**. It maps each screen (anchored to `docs/screenshots/mobile/{nanny,family}/`) to its inputs, its **validations** (present vs. to‑add), and its **backend logic** — marking what is already **wired** vs. **stubbed / TODO / blocked** — then gives the cross‑cutting workstreams and a prioritized build order.

**How to read the status tags**

| Tag | Meaning |
|---|---|
| ✅ **WIRED** | Real Firebase op, works in live mode |
| 🟡 **PARTIAL** | Works but missing validation / fields / correctness |
| 🔴 **BLOCKED** | Client op is **denied by `firestore.rules`** in live → throws |
| 🔧 **TODO / STUB** | Not implemented / mock‑only / hardcoded placeholder |

Architecture recap: GetX controllers (`lib/controllers/*`) → interface services (`lib/services/interfaces/i_*.dart`) with **`firebase/*` (live)** and **`mock/*`** impls; `AppConfig.useMock=false`; `InitialBinding` binds the Firebase impls. Server logic lives in `functions/` (Cloud Functions). Rules in `firestore.rules`.

---

## 0. Executive summary

**A lot is genuinely wired**: phone‑OTP + password auth, account delete + cascade, nanny/family/job persistence, applications (idempotent `applications/{jobId}_{nannyId}`), trials + disputes, chat threads/messages + image upload, settings, FCM token registration, the deterministic `MatchService`, and the server‑side subscription webhook + expiry/reminder schedulers.

**But eight systemic issues break "both flows fully work" in live** and must anchor the plan (details in §1). In short: several client writes are **rejected by security rules**, the **payment path is a client flag with no SDK**, the **notification inbox is never written**, **`storage.rules` is missing**, **match scores/stats are faked**, **chat isn't realtime and over‑restricts free tier**, the **active‑trial unlock bypass never engages**, and **nanny privilege‑escalation / private‑data exposure** exist at the rules layer.

---

## 1. Critical cross‑cutting findings (fix these first — they touch many screens)

- **C1 — Security rules deny core client writes (live‑breaking).** `firestore.rules:68‑71` forbids a family write that touches `subscription`, `freeContactsUsed`, `activeTrialNannyIds`, or `viewedProfiles`; `nannies` update is owner/admin‑only (`:54`); `notifications` create is admin‑only (`:165`). Yet the client writes all of these:
  - `subscribe()` writes `families/{id}.subscription` (`firestore_subscription_service.dart:76‑92`) → **denied**.
  - `recordView()` writes `viewedProfiles`+`freeContactsUsed` (`firestore_subscription_service.dart:51‑73`; also dead `firestore_user_service.dart:106‑122`) → **denied**.
  - Shortlist add/remove writes `nannies/{id}.stats.shortlists` (`firestore_shortlist_service.dart:51,64`) → **denied**.
  - **Fix:** move these to Cloud Functions / callables (server writes as admin); make the client **request‑only**. Wrap current calls in try/catch until then.

- **C2 — Storage upload paths don't match `storage.rules` → most uploads are denied in live.** `storage.rules` **exists and is well‑scoped** (owner/admin writes; size caps 5/25/10/8 MB; content‑type checks; **documents read owner/admin‑only**, `storage.rules:14‑42`). But the client writes to paths the rule patterns don't match, so the writes fall through to default‑deny in live:
  - ✅ photos `nannies/{uid}/photos/{uuid}.jpg` matches `photos/{file}` (`nanny_profile_controller.dart:436`).
  - ❌ **video** `nannies/{uid}/video.mp4` (`:468`) — rule expects `nannies/{uid}/videos/{file}` → **denied**.
  - ❌ **documents** `nannies/{uid}/docs/{type}.{ext}` (`:619`) — rule expects `nannies/{uid}/documents/{file}` → **denied**.
  - ❌ **chat image** `chats/{threadId}/{uid}/{uuid}.jpg` (`chat_controller.dart:233`) — rule `chats/{threadId}/{file}` matches only a **single** segment, not the extra `{uid}/…` → **denied**.
  - **Fix:** align the client paths to the rule patterns (rename `video.mp4`→`videos/…`, `docs/`→`documents/`, drop the `{uid}` segment in chat or make the rule `{file=**}`). Add **client‑side** size/type pre‑checks for friendly errors (rules already enforce server‑side).

- **C3 — Notification inbox is never written.** The bell/Notification Center reads the `notifications` collection (`fcm_notification_service.dart:129`), but Cloud Functions only send FCM push (`functions/src/utils/notifications.ts`) and never create a `notifications/{}` doc (and clients can't — `rules:165`). **The inbox is always empty in live. Fix:** each Function that pushes also writes an inbox doc `{userId,type,title,body,data,read:false,createdAt}`.

- **C4 — No real payment (monetization bypass).** No `purchases_flutter`/RevenueCat SDK in `pubspec.yaml`; `subscribe()` just flips a flag (and is rules‑denied per C1). `restorePurchases`/`simulate*` are stubs. The **correct** server path already exists (`functions/src/triggers/webhook.ts:revenueCatWebhook` + `subscriptionExpiredEnforcer`). **Fix:** integrate RevenueCat native purchase → webhook sets `subscription` server‑side; remove client subscription writes.

- **C5 — Nanny privilege‑escalation + private‑data exposure (security).** Two issues at the Firestore‑rules layer:
  1. **Self‑approval:** `firestore.rules:54` lets a nanny update **any** field of her own doc and `NannyModel.toMap` serializes `status/isVerified/verifiedAt/profileScore` (`nanny_model.dart:473‑476`) → a client can set `approved/isVerified=true`.
  2. **World‑readable private data:** `firestore.rules:50‑52` makes the **entire** approved‑nanny **Firestore doc** readable by any signed‑in user — including embedded document **download URLs**, DOB, health, and emergency contact (spec §13.2). (Note: the document **files** in Storage are already private — `storage.rules:24‑26` restricts read to owner/admin — but a **tokenized `getDownloadURL()`** stored in the world‑readable Firestore doc would bypass that. Once C2's document path is fixed, store a non‑tokenized ref and reveal via a callable, not a public URL.)
  - **Fix:** rules reject client writes to admin‑owned fields; move documents/health/DOB/emergency to a private subcollection or separate doc; app stops serializing admin fields.

- **C6 — Fake match scores & empty stats.** Application `matchScore` hardcoded `80` (`firestore_application_service.dart:64`); jobs‑list card `85` (`jobs_home_screen.dart:265`); dashboard preview `92‑i*3` (`nanny_dashboard_screen.dart:391`); browse base card `85` until a job is selected (`firestore_job_service.dart:37`). Nanny `stats.profileViews/shortlists/rating` are never incremented by anything. **Fix:** compute real `MatchService` scores at apply/list time; add Functions to maintain `nannies/{id}.stats.*`.

- **C7 — Chat not realtime + free‑tier over‑restricted.** `firestore_chat_service` uses one‑shot `.get()` (no `snapshots()`), so new messages need a manual refresh. And `rules:109‑141` require active subscription/trial to create a thread/message, but spec §4.2/§6.6/§11.2 allow **free‑tier chat after a profile view** — so the client's free‑tier `openThreadForNanny` path hits `permission‑denied`. **Fix:** switch to streams; reconcile rules ↔ spec for free‑tier chat.

- **C8 — Active‑trial unlock bypass never engages.** `families/{id}.activeTrialNannyIds` (the key that keeps chat/contacts open during a trial while otherwise expired/free) is only recomputed when a trial goes **terminal** (`functions/src/triggers/trial.ts:onTrialEnded`), never on accept/active, and the client can't write it (C1). **Fix:** a trial `onUpdate` Function adds the nanny to `activeTrialNannyIds` on `accepted`/`active`.

---

## 2. Service‑readiness matrix

| Service (`lib/services/firebase/…`) | Method(s) | Status |
|---|---|---|
| `firebase_auth_service` | sendOtp/verifyOtp/finalizePhoneRegistration; createPassword/loginWithPassword; reset‑OTP/verify/reset; logout; deleteAccount(+audit) | ✅ WIRED |
| `firestore_user_service` | getFamily/getNanny; saveNanny/submitNannyForReview/watchNanny; getSettings/updateSettings; isUserBlocked | ✅ WIRED |
| ″ | saveFamily (strips `subscription` to avoid clobber) | 🟡 PARTIAL |
| ″ | recordProfileView (writes family‑protected fields, txn on maybe‑missing doc; no live callers) | 🔴 BLOCKED / dead |
| `firebase_storage_service` | uploadBytes/deleteFile (real put/URL); photos path OK | 🟡 PARTIAL — **video/docs/chat paths don't match `storage.rules` → denied (C2)**; no client size/type pre‑check (rules enforce server‑side); no progress/resume |
| `fcm_notification_service` | initialize/token save+remove; loadNotifications/mark/delete (read side) | ✅ WIRED — but **inbox never populated** (C3) |
| `firestore_job_service` | saveJobPost; getJobsByFamily/browseJobs/getJob/updateJobStatus | ✅ WIRED |
| ″ | browseNannies (`status=='approved'` only, no `isVerified`; matchPercent hardcoded 85) | 🟡 PARTIAL / rules‑fragile |
| `firestore_application_service` | queries; withdraw/markViewed/shortlist/decline | ✅ WIRED |
| ″ | apply (matchScore hardcoded 80; no coverMessage; no counters) | 🟡 PARTIAL |
| ″ | offerTrial (no callers), no `hired` writer | 🔧 TODO |
| `firestore_shortlist_service` | getShortlist/add/remove/updateNotes | ✅ WIRED (shortlist doc) |
| ″ | `nannies/{id}.stats.shortlists` increment inside add/remove | 🔴 BLOCKED (C1) |
| `firestore_chat_service` | listThreads/loadMessages/sendMessage/findOrCreateThread/markThreadRead/linkTrial | ✅ WIRED — but one‑shot `.get()` (C7) |
| `firestore_trial_service` | sendOffer/updateStatus/respond/cancel/confirmPayment/reportIssue/recordOutcome/counter | ✅ WIRED (48h auto‑decline missing) |
| `firestore_dispute_service` | fileDispute/getMyDisputes | ✅ WIRED |
| `firestore_subscription_service` | getPlans/getState/getActivePlanId/freeViewsUsed (reads) | ✅ WIRED |
| ″ | recordView; subscribe; setState; simulate* (writes protected keys) | 🔴 BLOCKED + 🔧 no payment (C1,C4) |

**Server already owns (do NOT duplicate client‑side):** subscription state (`revenueCatWebhook`) + `subscriptionExpiredEnforcer`/`subscriptionExpiringReminder`; trial pushes + `activeTrialNannyIds` recompute + `trialStartingReminder`; `onNewApplication`/`onNewMessage`/`onDocumentReviewed`/`onBroadcastCreated`/`onUserDeleted`. **Bug:** these read `users.fullName` (nonexistent) for sender names → pushes say "Someone"/"A nanny"; read the `families`/`nannies` name instead (`functions/src/triggers/chat.ts:28`, `trial.ts:18`).

---

## 3. Shared / Auth screens (both flows; themed per role)

> Screenshots: nanny `01‑04,17,20‑23` · family `01‑04,14,20‑23`.

### S1 — Welcome / role select · `views/auth/welcome_screen.dart` — ✅
- Inputs: two role cards + returning‑user links. Validations: n/a.
- Backend: `AuthController.prepareNannyLogin/prepareFamilyLogin` set in‑memory role (no write pre‑auth). ✅ correct.
- Task: none.

### S2 — Login (phone) · `login_nanny_screen.dart` / `login_family_screen.dart` — ✅ / ➕
- Inputs: country code + national phone; returning password sign‑in.
- Validations: ✅ `Validators.phone` (6–12 digits). ➕ **Add per‑country length rules (§1.5)**; ➕ login "no account found" is error‑mapping only.
- Backend: ✅ real `sendOtp` (`verifyPhoneNumber`); `finalizePhoneRegistration` writes `users/{uid}` + role skeleton (`nannies`/`families`) idempotently.
- Task: add country‑aware phone validation; keep everything else.

### S3 — OTP verify · `otp_verify_screen.dart` — 🟡
- Inputs: 6 boxes, resend, change‑number.
- Validations: ✅ length gate, ✅ expiry blocks verify, ✅ resend after timer. ➕ **Missing §14.1: wrong‑attempt counter (A8), 5‑attempt/30‑min lockout (A9), rate‑limit countdown (A6)**; the `otpResendCooldownSeconds=60` constant is **unused** (resend only unlocks after full 300s).
- Backend: ✅ Firebase phone verify/expiry.
- Task: add attempt counter + lockout + 60s resend cooldown.

### S4 — Create password (post‑OTP) · `create_password_screen.dart` — 🟡
- Inputs: new + confirm, live strength meter.
- Validations: ✅ length≥8 + match. ➕ **Enforce §14.1 A12: ≥1 uppercase + ≥1 number** (strength is computed but not enforced — an 8‑char all‑lowercase saves).
- Backend: ✅ `createPassword` links a synthetic‑email credential (`<digits>@kafi.local`) and sets `users/{uid}.hasPassword=true`.
- Task: tighten the `canSavePassword` predicate.

### S5 — Password reset · `password_reset_screen.dart` — 🟡
- Inputs: phone → OTP → new+confirm. Country code hardcoded `+971`.
- Validations: phone step only `isEmpty`; ➕ **use `Validators.phone`**; ➕ enforce A12 on new password; ➕ **§6.7 "account exists" pre‑check** (OTP is currently sent to any number); ➕ add country picker.
- Backend: ✅ reset‑OTP/verify/reset (unlink+relink credential).
- Task: add existence check + stronger validation + country picker.

### S6 — Notifications · `notifications_screen.dart` + `notification_controller.dart` — 🔴/🔧
- Inputs: list; mark‑all, swipe‑delete, tap‑to‑navigate.
- Backend: ✅ read/mark/delete + FCM token wiring. 🔴 **C3: inbox never written → always empty.** 🔧 **deep‑link broken:** handler reads `data['route']` but Functions send `data['type']` → taps no‑op. ➕ per‑category settings (§7.2) ignored server‑side.
- Task: (Functions) write inbox docs + standardize `data` payload; (client) map `type`→route; honor `settings.*`.

### S7 — Legal (Terms/Privacy) · `legal_screen.dart` — 🔧 (static)
- Fully hardcoded, no fetch/versioning. Task (optional §): fetch versioned legal docs + record acceptance if spec requires.

### S8 — Delete account · `delete_account_screen.dart` — 🟡
- Inputs: reason radio → type `DELETE`.
- Backend: ✅ writes `deletionAudits/{uid}`, `user.delete()`, deletes `users/{uid}` → `onUserDeleted` cascade.
- Validations/logic ➕ **§14.12 missing:** block during active trial (D2/D3), cancel‑sub‑first (D1), pending payments (D4), archive‑vs‑hard‑delete open chats (D5), **30‑day re‑register cooldown (D6)** (audit written but never consulted); remove FCM token before delete.
- Task: add pre‑delete guards + cooldown check on re‑register.

---

## 4. NANNY flow — screen‑by‑screen

> Screenshots `docs/screenshots/mobile/nanny/` (05–19; shared 01–04,17,20–23 above).

### N05 — Onboarding "About you" · `nanny_info_screen.dart` — 🟡
- Inputs: name, DOB(+age), nationality, languages, visa, EID toggle, transfer, emirates, relocate, area, job‑type, salary min/max, availability(+from), marital, children(+count), health/meds/allergies, comfort toggles, religion(+note), emergency name/rel/phone, bio≤300.
- Validations: ✅ `_validatePersonalInfo` (name, DOB≥18, nationality, ≥1 language, visa, ≥1 emirate, area, salary min≤max, available‑from, children count, emergency, bio). ➕ bio‑300 is UI‑only (re‑validate on save); ➕ **emergency‑contact country code is a dead control** (`onChanged:(_){}`) → only national number stored; ➕ religion free‑text (spec enumerates).
- Backend: ✅ `saveNanny` → `nannies/{uid}` merge. 🔴 **C5:** `toMap` writes admin fields (`status/isVerified/...`) — stop serializing them.
- Task: fix emergency country code; re‑validate bio; drop admin‑field serialization (paired with rules).

### N06 — Photos & intro video · `nanny_media_screen.dart` — 🟡
- Inputs: 1–5 photos (first=cover) + intro video.
- Validations: ✅ requires ≥3 photos + video (stricter than spec's "≤5 photos, 60s video, video optional"); picker caps 60s. ➕ add **client‑side** size/type pre‑checks for friendly errors (Storage rules already cap photo ≤5MB / video ≤25MB and enforce content‑type); no true 60s enforcement; "remove video" can't null `introVideoUrl` (`copyWith` uses `??`).
- Backend: ✅ photo upload path OK. 🔴 **C2: video uploads to `nannies/{uid}/video.mp4` but the rule is `nannies/{uid}/videos/{file}` → denied in live.**
- Task: fix the video path to `nannies/{uid}/videos/…`; add client pre‑checks; allow clearing the video; reconcile min‑photo rule with spec.

### N07 — Experience · `nanny_exp_screen.dart` — 🟡
- Inputs: repeating experience cards.
- Validations: **NONE** (`saveExpAndNext` saves empty list). ➕ add "≥1 experience or explicit none"; empty experience silently lowers real match.
- Backend: ✅ persisted in `experiences[]`. Task: add validation.

### N08 — References · `nanny_refs_screen.dart` — 🔴(lossy)
- Inputs: has‑references toggle, reference cards, commitment checkbox.
- Backend: 🔧 **`hasReferences` and `commitsToShare` are dropped** on save (`copyWith(references:…)` only) → the "Has callable references" badge families rely on is never stored true; `numberOfReferences` never set. Validations: none.
- Task: persist `hasReferences`/`numberOfReferences`/commitment; gate the checkbox.

### N09 — Documents · `nanny_docs_screen.dart` — 🟡
- Inputs: passport(req), visa(req), EID(conditional), training/police(opt).
- Validations: ✅ passport+visa required; picker limited to pdf/jpg/png (Storage rules also cap ≤10MB + image/pdf). ➕ add client size pre‑check.
- Backend: 🔴 **C2: uploads to `nannies/{uid}/docs/{type}.{ext}` but the rule is `nannies/{uid}/documents/{file}` → denied in live** (so document upload currently fails). Then `submitNannyForReview` sets `status:'pending'`, clears rejection; `onDocumentReviewed` pushes. 🔴 **C5:** doc URLs are stored as an array on the **world‑readable** nanny Firestore doc.
- Task: fix the path to `…/documents/…`; move the doc URL array to a private subcollection/doc (or reveal via callable).

### N10 — Pending / review · `nanny_pending_screen.dart` — ✅
- Shows pending/rejected hero + per‑doc status + resubmit.
- Backend: ✅ realtime `watchNanny` (`nannies/{uid}.snapshots()`) auto‑navigates on approve, shows rejection reason. Admin owns `status`/reasons.
- Task: none (once C3 lands, add a persistent "approved/rejected" inbox record).

### N11 — Dashboard · `nanny_dashboard_screen.dart` — 🔴(stats)/🟡
- Shows stats (shortlists/views/rating), profile‑quality score, "Jobs for you".
- Backend: 🔧 **C6: stats never populate (always 0/0/—)**; "Jobs for you" match % faked (`92‑i*3`); quality checklist ad‑hoc (not spec §3.2 weights); the **Profile tab opens Settings, not a profile view**.
- Task: Functions to maintain `nannies/{id}.stats.*`; real match ranking; spec‑weighted quality score.

### N12 — Jobs tab · `jobs_home_screen.dart` — 🟡
- Shows search, applied/viewed/offers stats, filter chips, job cards.
- Backend: ✅ `browseJobs` (`jobs where status=='active'`, +emirate, limit 50). 🔧 **card match % hardcoded 85**; jobType/duties/search filtering is client‑side over a 50‑doc page (won't scale; misses matches beyond 50); no match ranking.
- Task: rank jobs by real `MatchService`; push filtering server‑side w/ indexes.

### N13 — Job detail · `job_detail_screen.dart` — 🟡
- Shows family card, **real** match ring + factors, details, apply.
- Backend: ✅ real `MatchService.calculateJobMatch`. 🔧 hardcoded display values (schedule/start/duration/"member since 2024"/always‑"Verified"); `job.viewsCount` never incremented.
- Task: render real `JobPostModel`/family fields; increment `viewsCount`.

### N14 — Smart match (pre‑apply) · `smart_match_screen.dart` + `match_service.dart` — 🟡
- Shows score ring + 5 checks; Apply (≥70) vs Apply‑anyway.
- Backend: ✅ real match; `apply()` writes idempotent `applications/{jobId}_{nannyId}` with dup/active‑trial guards. 🔧 **C6: apply hardcodes `matchScore:80`**; **no cover‑message step (§6.3)** (`coverMessage` always null); no `applicationsCount` increment. Note: `MatchService` weights follow `MATCH_ALGORITHM.md` (deviates from spec §9.1 — reconcile).
- Task: compute real score at apply; add cover‑message step; increment counters.

### N15 — My applications · `my_applications_screen.dart` + `application_detail_screen.dart` — 🟡
- Shows list w/ status + match% + withdraw; detail: timeline + trial actions.
- Validations: ✅ dup/active‑trial guards; withdraw confirm; counter rate>0.
- Backend: ✅ `getApplicationsForNanny` (needs `nannyId+createdAt` index); withdraw; trial accept/counter/decline. 🔧 match% = the fake 80 (C6); detail's job lookup fails if job not in current browse page.
- Task: real match; robust job‑by‑id fetch.

### N16 — Messages (nanny) · `chat_screen.dart` + `chat_controller.dart` — 🟡
- Backend: ✅ real threads/messages. 🔴 **C2: image upload path `chats/{threadId}/{uid}/…` doesn't match rule `chats/{threadId}/{file}` → denied**; 🔧 **C7: one‑shot `.get()` (not realtime)**; new‑message push has no inbox record (C3); nanny can't initiate a thread (family‑gated by rules).
- Task: fix chat image path; streams; inbox docs; allow nanny‑initiated threads if spec requires.

### N18 — Edit profile · `nanny_edit_profile_screen.dart` — 🔴(lossy)
- Backend: 🔧 `saveProfileDraft` saves only a **subset** (salary/visa/availability/religion edits dropped); **language vocab mismatch** (`'Arabic'` here vs `'Arabic (basic)'` in onboarding) desyncs match/browse; **no validation**.
- Task: align language vocab; validate; persist full edited set (reuse `_validatePersonalInfo`).

### N19 — Settings (nanny) · `nanny_shell_screen.dart` + `settings_screen.dart` — 🟡
- Backend: ✅ `getSettings/updateSettings` → `users/{uid}.settings.*`; logout removes FCM token; delete cascades. 🔧 **notification toggles are write‑only** (Functions never read `settings.*`); editing docs correctly re‑enters `pending`.
- Task: honor `settings.*` server‑side before push.

---

## 5. FAMILY flow — screen‑by‑screen

> Screenshots `docs/screenshots/mobile/family/` (05–19; shared as §3).

### F05 — Job & family form · `family_form_screen.dart` — 🟡
- Inputs: family profile + job (name, city GPS, children+ages, languages, cameras, pets, religion+pref, house rules, about, roles, jobType, employmentType, schedule, duties, benefits, salary, trial days/rate, visa, commitment).
- Validations: ✅ `_validateFamily` (name/nationality/city, ages when children>0, ≥1 language/role/duty/benefit, schedule, salary min≤max&>0, trialDays>0, trialRate>0). ➕ no bio‑300 cap; ➕ no job‑post limit (J8); ➕ no salary "unrealistic" check (V9).
- Backend: ✅ `saveFamily` (subscription‑safe) + `saveJobPost` (`jobs/{id}`, +7d expiry). 🔧 **job post drops matching‑critical fields** (`jobTitle, experienceYears, languagesRequired/Preferred, skillsRequired, nationalityPreference, religionPreference, startDate, duration, additionalNotes`) → degrades `MatchService`; **family `profilePhoto` never captured/uploaded**; 7‑day auto‑expire has no scheduler (J9).
- Task: capture+persist the missing job fields; add family photo upload; expiry Function.

### F06 — Browse nannies · `browse_screen.dart` + `browse_controller.dart` — 🟡
- Shows search, filter pills, job‑ranked matches, nanny cards; free‑view hint.
- Backend: ✅ `browseNannies` (`status=='approved'`, limit 50) + `MatchService.rankCards` when a job is selected. 🔧 **C6: base match % hardcoded 85**; 🔴 **C1/rules‑fragile: query lacks `isVerified==true`** required by `rules:50‑52` → an approved‑but‑unverified doc fails the **whole** query; some filter pills have no server predicate (index gaps); `yearsExp` = experiences.length not real years.
- Task: add `isVerified` filter + indexes; real base match; correct years‑exp.

### F07 — Nanny profile: UNLOCKED · `profile_unlocked_screen.dart` — 🔧
- Shows phone/WhatsApp/Call/CV + shortlist + send‑trial.
- Backend: 🔧 **no real contact data** — phone `+971 50 234 5678` hardcoded; WhatsApp/Call/CV → `mockContactAction` snackbar stubs; unlock decided purely client‑side; no "profile viewed" push to nanny (§6.4).
- Task: a callable that returns the real number/CV **only** for subscribed families / active trials; real `tel:`/`wa.me`/CV launch; viewed‑push.

### F08 — Nanny profile: LOCKED (paywall) · `profile_locked_screen.dart` — ✅(presentational)
- Blurred rows + subscribe → pricing; trial bypass banner. Correct as a paywall. Note: the free‑view consumption that gates reaching it is client‑side & rules‑blocked (C1).

### F09 — Nanny profile: RE‑LOCKED · `profile_relocked_screen.dart` — 🟡
- Expired banner + renew. Reached when `isExpired && wasViewed`. 🔧 stats hardcoded; depends on `viewedProfiles` which currently can't be persisted (C1) → "previously viewed" may not be recognized.
- Task: fix view persistence (C1) so re‑lock recognizes prior views.

### F10 — Shortlist · `shortlist_screen.dart` + `shortlist_controller.dart` — 🔴/🔧
- Backend: ✅ `shortlists/{familyId}_{nannyId}` idempotent. 🔴 **C1: add/remove also write `nannies/{id}.stats.shortlists` → denied** (throws after the shortlist doc write; no try/catch). 🔧 **renders mock data:** `resolveNannyCard` only searches `mockNannyCards` → real shortlisted nannies show a mock card.
- Task: move stat increment to a `shortlists` Function trigger; add real nanny fetch‑by‑id → card.

### F11 — Compare · `compare_screen.dart` — 🟡
- Compares first 2 shortlisted. 🔧 falls back to `mockNannyCards` on any browse error; match % is the base/hardcoded value.
- Task: real cards (shared fetch‑by‑id fix from F10); real match.

### F12 — Messages (family) · `chat_screen.dart` + `chat_controller.dart` — 🔴/🟡
- Backend: ✅ real threads/messages. 🔴 **C7: free‑tier thread/message creation denied by rules** (spec allows free‑tier chat after a view); 🔴 **C2: image upload path mismatch (as N16) → denied**; 🔧 contact strip Call/WhatsApp are mock stubs; optimistic `messages.add` before the awaited write leaves ghost bubbles on denial; one‑shot `.get()` (not realtime).
- Task: reconcile free‑tier chat rules; fix chat image path; real contact actions; await‑then‑insert; streams.

### F13 — Applicants inbox · `family_applicants_screen.dart` — 🟡
- Shows received apps + Decline/Shortlist; tap marks viewed.
- Backend: ✅ real queries + status updates (needs `familyId+createdAt` index). 🔧 match% = hardcoded 80 (C6); "Shortlist" here only flips app status (doesn't add to `shortlists` — divergent from the heart); no "send trial offer" action here.
- Task: real match; unify shortlist action; add trial‑offer entry.

### F15 — Trial · `trial_screen.dart` + `trial_controller.dart` — 🟡
- Backend: ✅ real `trials/{id}` reads/updates; `reportPaymentIssue` files a real `disputes/{id}`. 🔴 **C8: `activeTrialNannyIds` never set on accept** → the expired‑but‑active‑trial unlock bypass doesn't engage for a first/only trial. 🔧 nanny `availability→onTrial` (§6.5) not written; 48h auto‑decline (T8) absent.
- Task: trial `onUpdate` Function to set `activeTrialNannyIds` + nanny availability; add 48h auto‑decline scheduler.

### F16 — Trial offer · `trial_offer_screen.dart` — 🟡
- Inputs: duration, daily rate, start date, live‑in/out, location, notes, payment‑is‑direct ack.
- Validations: ✅ future start; ✅ `canSendOffer = hasActiveAccess && ack && rate>0`. ➕ **no nanny‑verified check (§14.6 T2)** ("Verified" badge hardcoded); ➕ no nanny‑on‑another‑trial block (T3).
- Backend: ✅ `sendOffer` → `trials/{id}` + links thread + posts bubble; push via `onTrialOffered`. 🔴 subscription requirement is **client‑only** (`rules:153` checks only ownership) → a free/expired family bypassing UI could write a trial.
- Task: enforce nanny‑verified + no‑active‑trial + subscription **in rules**; drop hardcoded badge.

### F17 — Pricing / subscription · `pricing_screen.dart` + `subscription_controller.dart` — 🔴/🔧 (highest‑value area)
- Shows 3 plans (Weekly 89 / Monthly 239 / 2‑Month 369, +VAT) matching §8.1.
- Backend: ✅ real reads of `families/{id}.subscription`. 🔴/🔧 **C4: no payment** — `subscribe()` flips a flag (and is **rules‑denied**, C1); `restorePurchases`/`simulate*` are stubs. Correct server path exists (`revenueCatWebhook` + `subscriptionExpiredEnforcer`) but is unreachable from the app.
- Task: integrate RevenueCat (native purchase → webhook sets state); make client request/read‑only; wire real restore.

### F18 — Edit family profile · `family_edit_screen.dart` — 🟡
- Same fields/validation as F05; updates existing job in place. Same missing job fields + no `profilePhoto` upload. "Change password" routes to reset‑OTP.
- Task: as F05; consider in‑place re‑auth password change.

### F19 — Settings (family) · `settings_screen.dart` + `family_shell(_screen).dart` — 🟡
- Backend: ✅ `getSettings/updateSettings`; logout; delete cascade. 🔧 **"Restore purchases" is a no‑op**; no in‑app cancel (spec §6.8 store deep‑link) — routes to pricing.
- Task: real restore; store‑managed cancel deep‑link; honor `settings.*` server‑side (shared with N19/C3).

---

## 6. Cross‑cutting backend workstreams

1. **Security rules (`firestore.rules`)** — reject client writes to admin‑owned nanny fields (`status/isVerified/verifiedAt/profileScore/introVideoStatus`); split private nanny data (documents/DOB/health/emergency) into a subcollection with owner/admin‑only read; reconcile free‑tier chat (C7); enforce trial preconditions (subscription/verified/no‑active‑trial) server‑side (F16); decide the family‑protected‑fields path (server‑write via Functions per C1).
2. **Storage paths (C2)** — `storage.rules` is already correct and well‑scoped; **align the client upload paths to it** (`nannies/{uid}/videos/…`, `nannies/{uid}/documents/…`, single‑segment `chats/{threadId}/…` or make the chat rule `{file=**}`). Add client‑side size/type pre‑checks for UX.
3. **Cloud Functions** — write **inbox docs** on every push (C3) + standardize `data.type` for deep‑links; fix sender names (read `families`/`nannies`, not `users.fullName`); maintain `nannies/{id}.stats.*` (views/shortlists/rating, C6); set `families/{id}.activeTrialNannyIds` + nanny `availability` on trial accept/active (C8); server view‑accounting + max‑5 free views (C1); 48h trial auto‑decline + 7‑day job auto‑expire schedulers; keep RevenueCat webhook as the sole subscription‑state writer (C4).
4. **Firestore indexes** — ensure composites exist for `applications(nannyId+createdAt)`, `applications(familyId+createdAt)`, browse filter combos (`nannies status+isVerified+jobTypePreference/nationality`). (The current index set was just fixed for deploy; extend as queries are added.)
5. **Client match correctness (C6)** — compute real `MatchService` scores at apply and for list cards; rank jobs for nannies and cards for families; reconcile `MATCH_ALGORITHM.md` weights vs spec §9.1.
6. **RevenueCat (C4)** — add `purchases_flutter`; wire purchase/restore; entitlement → webhook.
7. **Realtime (C7)** — convert chat (and optionally applications/trials) to `snapshots()` streams.

---

## 7. Prioritized build order

**Phase 0 — Correctness & security (unblock live; do first)**
- C1 move subscription/view/stat writes server‑side (rules + Functions) — fixes pricing, browse free‑views, shortlist, re‑lock.
- C2 fix Storage upload paths to match the (already‑correct) `storage.rules` — restores video/document/chat‑image uploads. · C5 rules: nanny self‑approve + private‑data exposure. · C3 notification inbox docs + deep‑link payload.

**Phase 1 — Make both journeys functional**
- C4 RevenueCat payment → real subscription. · F07/F12 real contact reveal (callable) + real `tel:`/`wa.me`/CV. · C8 active‑trial unlock. · C7 free‑tier chat rules + realtime streams. · F10/F11 real nanny‑by‑id (kill mock resolver).

**Phase 2 — Match, stats & completeness**
- C6 real match at apply/list + nanny stats Functions. · F05 capture missing job fields + family photo. · N06/N09 upload size/format validation. · N08 persist references. · N18 edit‑profile field loss + language vocab. · Trial/job schedulers (48h/7‑day).

**Phase 3 — Validation polish & spec parity**
- OTP hardening (S3) + password policy (S4/S5) + reset account‑check (S5). · Delete‑account guards + cooldown (S8). · Notification settings honored server‑side (N19/F19). · Job‑detail real fields + counters. · Legal versioning (S7). · Blocked‑user mid‑session enforcement.

---

_Evidence: this plan is synthesized from a full read of the mobile app (views/controllers/services/models), `firestore.rules`, `functions/`, and `KAFI_SYSTEM_SPECIFICATION.md`; a companion audit lives at `docs/agents/reviews/backend-audit.md`. File:line references above point to the exact code to change._
