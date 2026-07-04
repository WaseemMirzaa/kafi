# Kafi Mobile App — Screen Gallery (mock mode)

Every screen of the Flutter mobile app, **grouped by user flow** (37 screens). Captured in
**mock mode** with a seeded demo session, so data-rich screens (browse, shortlist,
applicants, messages, notifications, subscribed nanny profile) show real content.
Images are content-cropped so scrollable screens show every field with no wasted space.

> A few screens are only reachable mid-flow or need an approved-nanny/live backend —
> these are noted inline and will be fully populated when we run in **live mode**.

## Onboarding & Auth

### 01-welcome
Welcome — choose role (Nanny vs Family).

![01-welcome](./01-welcome.png)

### 02-login-nanny
Nanny phone login (country code + OTP notice).

![02-login-nanny](./02-login-nanny.png)

### 03-login-family
Family phone login.

![03-login-family](./03-login-family.png)

### 04-otp-verify
OTP verification — 6-digit, resend, expiry timer.

![04-otp-verify](./04-otp-verify.png)

### 05-create-password
Create password (post-OTP) — strength + confirm.

![05-create-password](./05-create-password.png)

### 06-password-reset
Password reset.

![06-password-reset](./06-password-reset.png)

## Nanny journey

### 07-nanny-info
Onboarding — About you (all required fields).

![07-nanny-info](./07-nanny-info.png)

### 08-nanny-media
Onboarding — Photos & intro video.

![08-nanny-media](./08-nanny-media.png)

### 09-nanny-exp
Onboarding — Work experience.

![09-nanny-exp](./09-nanny-exp.png)

### 10-nanny-refs
Onboarding — References.

![10-nanny-refs](./10-nanny-refs.png)

### 11-nanny-docs
Onboarding — Documents (passport/visa/EID…).

![11-nanny-docs](./11-nanny-docs.png)

### 12-nanny-pending
Review/approval status + per-document status.

![12-nanny-pending](./12-nanny-pending.png)

### 13-nanny-home
Dashboard (Home tab). _(note: stats show defaults in mock — populated once the nanny is approved in live mode)_

![13-nanny-home](./13-nanny-home.png)

### 36-nanny-jobs
Jobs tab (matching job posts).

![36-nanny-jobs](./36-nanny-jobs.png)

### 33-nanny-job-detail
Job detail. _(note: opens from a job card in-flow; direct route shows a placeholder)_

![33-nanny-job-detail](./33-nanny-job-detail.png)

### 16-smart-match
Smart match (pre-apply check). _(note: opens from a job in-flow)_

![16-smart-match](./16-smart-match.png)

### 14-nanny-applications
My applications. _(note: populated in live mode once the nanny is approved)_

![14-nanny-applications](./14-nanny-applications.png)

### 15-nanny-edit-profile
Edit profile.

![15-nanny-edit-profile](./15-nanny-edit-profile.png)

### 38-nanny-settings
Profile / Settings tab.

![38-nanny-settings](./38-nanny-settings.png)

## Family journey

### 17-family-form
Onboarding — Job & family form (all required fields).

![17-family-form](./17-family-form.png)

### 19-browse
Browse nannies (Home tab) — ranked match cards.

![19-browse](./19-browse.png)

### 24-profile-unlocked
Nanny profile — contact unlocked (subscribed): number, WhatsApp/Call/CV, trial offer.

![24-profile-unlocked](./24-profile-unlocked.png)

### 22-profile-locked
Nanny profile — contact locked (paywall).

![22-profile-locked](./22-profile-locked.png)

### 23-profile-relocked
Nanny profile — contact re-locked.

![23-profile-relocked](./23-profile-relocked.png)

### 21-shortlist
Shortlist (Shortlisted tab).

![21-shortlist](./21-shortlist.png)

### 32-compare
Compare nannies. _(note: opens with two nannies selected in-flow)_

![32-compare](./32-compare.png)

### 34-family-messages
Messages (chat threads).

![34-family-messages](./34-family-messages.png)

### 20-family-applicants
Applicants inbox — received applications + actions.

![20-family-applicants](./20-family-applicants.png)

### 25-trial
Trial.

![25-trial](./25-trial.png)

### 26-trial-offer
Trial offer.

![26-trial-offer](./26-trial-offer.png)

### 27-pricing
Pricing / subscription plans.

![27-pricing](./27-pricing.png)

### 35-family-settings
Profile / Settings tab.

![35-family-settings](./35-family-settings.png)

### 18-family-edit
Edit family profile.

![18-family-edit](./18-family-edit.png)

## Shared

### 28-notifications
Notifications inbox.

![28-notifications](./28-notifications.png)

### 29-terms
Terms & Conditions.

![29-terms](./29-terms.png)

### 30-privacy
Privacy Policy.

![30-privacy](./30-privacy.png)

### 31-delete-account
Delete account.

![31-delete-account](./31-delete-account.png)

