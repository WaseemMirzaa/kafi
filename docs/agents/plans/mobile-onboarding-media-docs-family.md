---
slug: mobile-onboarding-media-docs-family
project: kafi (Flutter app + admin panel)
title: Nanny media/docs overhaul, deferred uploads, family jobs, admin go-live, remaining-screens plan
owner: architect
status: IN_PROGRESS
updated: 2026-06-22
branch: claude/quirky-goldberg-7jxx5a
---

# Plan — onboarding media/docs, family jobs, admin go-live, remaining screens

Constraint: no Flutter toolchain here → all changes static; user runs
`flutter analyze`/device test. Admin go-live needs the user's Firebase project.

## A. Nanny onboarding (Flutter) — IMPLEMENTING

### A1. Step 1 "About You" — all fields required
- Add `currentArea` to `_validatePersonalInfo` (only real field with an empty
  state still optional). Name/DOB/nationality/languages/visa/emirates/marital/
  children/emergency/bio/salary/availability already required (Phases 2 & 4).
- Booleans/enums (relocate, comfort*, transferVisa) always carry a value.
  `religion`/health-details stay optional (labelled "(optional)", spec §3.2).

### A2. Step 2 media — min 3 photos + video mandatory, cover card, +fix
- `NannyConstants.minPhotos` 1 → 3.
- `saveMediaAndNext`: require `photoUrls.length >= 3` AND `introVideoUrl != null`
  (localized errors). New keys: `nannyPhotosMin3`, `nannyVideoRequired`.
- **Cover card:** the pink "tap to add" container shows the **first photo** as a
  cover (with a "Cover" badge) once added; empty → the add prompt. Whole card
  clickable to add more.
- **Thumbnail row:** every "+" tile adds a photo (fix: today only the first works
  — `i == 0 && photos.isEmpty`); each photo keeps the × remove control.
- **Video preview:** replace the hardcoded `My intro video · 0:47/1:00` with a
  real `video_player`-backed preview (play/pause, position/duration, scrubbable
  progress, remove). Store picked file name.
- Photos/video keep immediate upload (only **docs** are deferred per request).
- Experiences (`saveExpAndNext`) + family jobs (`_persist`) already persist via
  `saveNanny`/`saveJobPost` — verified.

### A3. Step 5 documents — defer upload to submit, blocking loader, errors
- Tap each doc tile → file picker (already), but **store bytes locally** instead
  of uploading immediately; mark the tile "selected".
- Wait until all required (passport+visa) are selected; user may also add
  optional ones; EID "No EID" button wired (sets not-needed).
- On **Submit**: show a **blocking** loader overlay, upload ALL selected docs to
  Firebase Storage, collect URLs, set status `reviewing`, `saveNanny` +
  `submitNannyForReview`, then go to pending. Per-file try/catch → localized
  error, abort on failure (no partial submit). New keys: `docUploading`,
  `docUploadFailed`.

### A4. Nanny profile editing (from profile tab) — IMPLEMENTING (lighter)
- Photos & video, personal info, experience already editable via the same
  screens in `editMode` (`savePersonalInfoAndNext(advance:false)` etc.).
- **Documents replace requires admin re-verification:** when a nanny re-uploads
  a doc from the profile, set that doc back to `reviewing` (not `approved`) and
  keep the old URL live until approved. Implement in the edit-docs path.

## B. Family (Flutter) — IMPLEMENTING

### B1. Post-a-job: all fields mandatory + localized
- Extend `_validateFamily` to cover every input (already covers most: name,
  nationality, city, children-ages, languages, roles, schedule, duties,
  benefits, salary order, trial). Add: childrenCount ≥ 1, visa sponsorship is
  always an enum. All messages already localized (EN+AR).

### B2. One full-time + one part-time active job; repost after hire
- `JobPostModel` has `jobType` (liveIn/liveOut) — NOT full/part-time. The job
  duration (`duration: permanent|contract`) is the FT/PT axis per spec §3.4.
- Logic: a family may have **one active full-time and one active part-time** job
  at once. On create, block a second active job of the same kind (localized
  message). When a job's trial → hired, mark job `closed`/`hired`; a **Repost**
  action reopens/clones it. Enforce in `FamilyProfileController` create path +
  `JobPostController`.

### B3. Edit family profile — IMPLEMENTING
- `family_edit_screen.dart` + `saveEdit()` exist. Verify it covers all family
  fields (religion, about, house rules, schedule were omitted per earlier audit)
  and reuses validation. Fill the gaps so edit == create coverage.

## C. Admin panel — GO-LIVE (mostly config, already built)
Audit confirms the admin panel already implements, for both mock + live:
- Live Firebase Auth admin login + `admin` custom claim check (`useAuth.ts`);
  `scripts/set-admin-claims.ts` seeds claims + `admins/{uid}`.
- `NannyService.approve/reject/reviewDocument/reviewVideo/block/unblock`,
  `FamilyService.block/unblock/overrideSubscription/resetFreeContacts`.
- `NannyProfileView` shows ALL profile fields; `VerifyDocuments` approve/reject;
  app already reacts live via `watchNanny` (pending → approved/rejected).
**Action (no app code):** document go-live — set `VITE_USE_MOCK=false` +
`VITE_FIREBASE_*` in `admin-panel/.env`, run `set-admin-claims`, deploy rules.
The Flutter app must enforce `blocked` on auth/session (see C1).

### C1. App-side `blocked` enforcement (Flutter) — IMPLEMENTING
- Admin sets `blocked:true` on nanny/family docs. App currently ignores it.
- On login + via `SessionMonitor`/profile watch, if the user's doc has
  `blocked == true`, sign out and show a localized "account blocked" screen/
  message. Add a `blocked` read to the user/nanny/family models + a guard.

## D. Remaining screens — PLAN ONLY (home / shortlist / messages, both roles)
Backend/logic/flows to wire from mock → live and complete details:

- **Nanny home/dashboard:** live profile-score, stats (views/shortlists/apps),
  recommended jobs (`browseJobs` + match), notifications badge. Pending/blocked
  gating. Source: `nanny_dashboard_screen`, `NannyProfileController.stats`.
- **Nanny jobs / applications:** `browseJobs` live, one-application-per-job,
  status timeline (pending→viewed→shortlisted→trialOffered→hired), trial
  accept/counter/decline (already in chat). 
- **Family browse/shortlist:** `IJobService.browseNannies` live, free-view
  counter + subscription gate (`recordProfileView` transaction exists),
  shortlist add/remove (`IShortlistService`) + compare.
- **Messages (both):** `IChatService` live threads/messages, image send
  (picker wired), trial-offer bubbles, subscription-expired gating on open.
- **Notifications:** FCM deep-links (implemented) → ensure live token save.
- For each: replace any remaining mock-only data, add empty/error/loading
  states, and localize remaining literals. Detailed per-screen task list to
  follow once A–C land.

## Sequencing / commits
1. A1+A2 (Step1 + media)  2. A3 (docs deferral)  3. A4+C1 (edit-docs reverify +
blocked guard)  4. B1+B2+B3 (family)  5. Admin go-live doc  6. D plan expansion.

## Risks
- Media cover card + video_player preview + docs-deferral are UI/stateful and
  unverified here — need a device pass.
- FT/PT job semantics: confirm "full/part-time" maps to job `duration`
  (permanent/contract), not `jobType` (live-in/out).
