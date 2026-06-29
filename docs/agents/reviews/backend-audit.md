---
slug: backend-audit
project: kafi (mobile backend)
title: Mobile backend issues & broken flows — audit + fixes
owner: reviewer
status: PARTIAL_FIX
updated: 2026-06-22
---

# Kafi mobile backend — audit findings

From three parallel audits (data round-trips, Cloud Functions, end-to-end flows),
live mode (`useMock=false`). ✅ = fixed in this branch; ☐ = still open.

## Critical
- ✅ **#3 Job-post parser dropped 18 written fields.** `_jobFromMap` now parses
  schedule/startDate/duration/experienceYears/languages*/skills/nationality/
  religion prefs/visaSponsorship/trial duration+rate/notes/counts/commitment, with
  Timestamp-tolerant dates; `saveJobPost` now sets `createdAt`/`expiresAt`/`updatedAt`
  server-side. (`firestore_job_service.dart`)
- ✅ **#4 Admin read wrong collection (`jobPosts` vs `jobs`).** Admin `JobPostService`
  now reads `jobs`. (`admin-panel/src/services/firestore.ts`)
- ✅ **#8 Targeted broadcasts matched zero users (`userType` vs `type`).** Fixed query
  field. (`functions/src/triggers/broadcast.ts`)
- ✅ **#9 Timestamp/String mismatches.** (a) `saveFamily` no longer writes the
  `subscription` sub-map → profile edits can't reset a paid family to free / clobber
  `endDate`. (b) `FamilySubscription.fromMap` now accepts Timestamp + ISO string.
  (c) trial `startDate` written as Timestamp so the "starts tomorrow" reminder matches.
- ☐ **#1 Notification inbox dead.** Nothing writes `notifications` docs (only FCM push).
  Fix: have `sendNotification` (or each trigger) also persist a `notifications/{id}`
  doc per recipient. (`functions/src/utils/notifications.ts`)
- ☐ **#2 Push deep-links don't navigate.** App routes off `data['route']` (mock-only);
  functions send `data:{type, trialId/threadId/applicationId}`. Fix the payload or the
  handler mapping. (`notification_controller.dart` / `functions/.../*.ts`)
- ☐ **#5 Family can't see received applications** — `ApplicationController.receivedApplications`
  is rendered by no screen. Needs a family "Applicants" view.
- ☐ **#6 Application never reaches `trialOffered`/`hired`** — `offerTrial()` has no callers;
  hire writes only the trial doc. Wire `offerTrial`/set `ApplicationStatus.hired`.
- ☐ **#7 In-app `subscribe()` grants `active` with no payment** (monetization bypass).
  Gate purchases behind the RevenueCat webhook; make the client write request-only.

## Major
- ✅ **#12 Family read dropped 5 fields** — `getFamily` now parses `profilePhoto`,
  `specialNeedsDetails`, `nannyReligionPreference`, `activeTrialNannyIds`, `stats`.
- ✅ **#14 Shortlist counter** — increments `stats.shortlists` (the field the dashboard
  reads) and uses a deterministic doc id (idempotent add/remove).
- ☐ **#10 Chat/trial pushes show no sender name** — functions read `users.fullName`
  (absent); name lives on `families`/`nannies`. Read the profile doc.
- ✅ **#11 Rejected nanny is a dead end** — `NannyModel` now parses
  `rejectionReason`/`rejectedAt`/`introVideoStatus`/`introVideoRejectionReason`
  (admin-owned, read-only — not in `toMap`). The pending screen renders a rejected
  state (reason card + per-doc reasons + intro-video verdict + **Resubmit**), the
  watch reacts to live rejection, login routes rejected nannies to the pending
  screen, and `submitNannyForReview` clears the reason on resubmit. The dead
  "profile submitted" push moved from `onCreate` to the draft→pending transition
  in `onDocumentReviewed` (`onNannySubmitted` removed).
- ☐ **#13 No one-application-per-job guard** — `apply()` never checks existing apps.
- ☐ **#15 Free contact reveal enforced only by UI routing** — `contactsHidden` is false
  for free users; gate in the controller/rules too.
- ☐ **#16 Active subs never expire client-side** (relies on the hourly enforcer) and chat
  gates are client-only — verify `firestore.rules`.
- ☐ **#17 Trial dispute/cancel detail lost** — `cancelReason`/`paymentIssueDescription`
  written but never read; admin reads a trial `rating` nothing writes.
- ☐ **#18 `recordProfileView` is dead + would crash** (`tx.update` on a missing doc) —
  the live path uses a different transaction; delete or fix the dead copy.

## Minor / cross-cutting (open)
- Admin applications list shows blank job/nanny/family names (apply never writes the
  denormalized names). Broadcast status guard non-atomic. Spec-drift comments.

## QA traps (mock hides these)
Mock subscription defaults `active` (free-view + chat gates never exercised); mock
shortlist ignores the counter (dashboard hardcoded `12`); mock auto-approves nannies
after 30s (hides unhandled rejection). Test the above against **live**.
