# Kafi - The Right One
## Complete Functional & Screen Documentation

**Platform:** UAE Nanny/Domestic Helper Marketplace  
**Business Model:** Free for nannies, Subscription-based for families  
**Target Market:** UAE (Dubai, Abu Dhabi, Sharjah, other Emirates)

---

## TABLE OF CONTENTS

1. [App Overview](#app-overview)
2. [User Roles](#user-roles)
3. [Authentication Flow](#authentication-flow)
4. [Nanny Mobile App Screens](#nanny-mobile-app-screens)
5. [Family Mobile App Screens](#family-mobile-app-screens)
6. [Shared Features](#shared-features)
7. [Admin Panel](#admin-panel)
8. [Pricing & Subscription](#pricing--subscription)
9. [Missing Screens](#missing-screens)
10. [Clarification Questions](#clarification-questions)

---

## APP OVERVIEW

Kafi is a mobile-first marketplace connecting:
- **Nannies/Helpers** (100% free forever)
- **Families** (Subscription required after 5 free contacts)

### Core Features
- OTP-based phone authentication
- Profile verification by admin
- Smart matching algorithm (percentage-based)
- In-app chat with privacy protection
- Paid trial system
- Multi-payment support (Apple Pay, Google Pay, Samsung Pay, Card)

---

## USER ROLES

### 1. Nanny/Helper (Free Users)
- Create profile with photos, video, documents
- Get verified by admin
- Browse job postings
- Apply to jobs
- Chat with families
- Accept/decline trial offers
- 100% free forever

### 2. Family (Paying Users)
- Post job requirements
- Browse verified nannies
- 5 free contacts, then subscription required
- View full profiles (phone, CV, video) when subscribed
- Send trial offers
- Chat with nannies
- Call/WhatsApp nannies directly

**Post-Subscription Behavior:**
- When subscription ENDS (expired/payment-failed/cancelled past end-date), the family enters **lockdown**:
  - Nanny contact info hidden again (phone numbers blurred everywhere)
  - Chat threads become inaccessible (list hidden, threads locked, sending blocked)
  - CV downloads, trial offers, Call/WhatsApp all disabled
  - Browsing still works; data is preserved
  - Re-subscribing restores all access instantly
  - **Exception:** Active trials keep their chat/contact access until the trial ends

### 3. Admin (Web Dashboard)
- Verify nanny documents
- Approve/reject nanny videos
- Manage all users
- View revenue & analytics
- Monitor active trials
- Broadcast messages

---

## AUTHENTICATION FLOW

**Authentication Provider:** Firebase Authentication (Phone Number Sign-In)

**Flow:**
1. User enters phone number
2. Firebase sends OTP via SMS (handled by Firebase, no separate SMS gateway)
3. User enters OTP
4. Firebase verifies and creates/signs in user
5. App checks if profile exists → route to dashboard or onboarding

---

### Screen 1: Welcome / Role Selection
**Purpose:** First entry point - user selects their role

**Elements:**
- Kafi logo & tagline
- "I am a Nanny/Helper" card (pink gradient)
  - Lists: 100% FREE, Upload profile & video, Get found by families
- "I am a Family" card (purple gradient)
  - Lists: Browse verified nannies, Smart match system, From 89 AED/week
- Subtext for returning users

**Flow:** Tap role → Navigate to respective login screen

---

### Screen 2: Nanny Login / Signup
**Purpose:** Phone entry for new or returning nanny

**Elements:**
- Header badge: "Nanny / Helper Sign Up - 100% free"
- Country code dropdown (UAE, Philippines, India, Sri Lanka, Nepal, Indonesia, Ethiopia, Kenya, Ghana, Nigeria, Pakistan, Bangladesh, Uganda)
- Phone number input
- "Send OTP code" button
- Divider: "Already have an account?"
- Terms & Privacy links

**Returning User Variant:**
- Same phone input
- "Send OTP to sign in" button
- Password field with show/hide toggle
- "Sign in with password" button
- "Forgot password?" link

---

### Screen 3: Family Login / Signup
**Purpose:** Phone entry for new or returning family

**Elements:**
- Purple theme (different from nanny)
- Header badge: "Family Registration - From 89 AED/week"
- Country code dropdown (UAE, UK, US, India, Pakistan, France, Germany, Canada, Australia)
- Phone number input
- "Send OTP code" button
- Terms & Privacy links

---

### Screen 4: OTP Verification
**Purpose:** Verify phone number with 4-digit code

**Elements:**
- SMS preview mockup showing received OTP
- 4 individual OTP input boxes
- Timer: "Code expires in X:XX"
- "Verify & continue" button
- "Resend OTP" / "Change number" links
- Security notice

**Success State:**
- Green checkmark animation
- "Phone verified!" message
- "What happens next" steps list
- "Create my password" button

---

### Screen 5: Create Password
**Purpose:** Set account password after OTP verification

**Elements:**
- Password input with show/hide toggle
- Password strength indicator (bar)
- Strength label (Weak/Medium/Strong)
- Requirements checklist:
  - At least 8 characters
  - Contains a number
  - Contains uppercase letter
  - Contains special character (optional)
- Confirm password input
- "Passwords match" indicator
- "Save & start my profile" button

---

## NANNY MOBILE APP SCREENS

### Screen 6: Personal Info (Step 1 of 6)
**Purpose:** Collect basic personal information

**Sections:**

**A. Basic Information**
- Full name (as per passport)
- Date of birth (date picker)
- Age (auto-calculated, read-only)
- Nationality (dropdown with common nanny nationalities)
- Languages spoken (multi-select chips: English, Arabic, Hindi, Tagalog, Urdu, French, Swahili, Amharic)

**B. Visa & Legal Status**
- Info banner explaining purpose
- Visa status radio options:
  - Visit Visa (needs sponsorship)
  - Residence Visa (employed, active work permit)
  - Own Residence Visa / Freelance / Investor
  - Cancelled / Grace Period
  - Outside UAE — applying from abroad
- Emirates ID conditional section:
  - "Do you have valid EID?" Yes/No toggle
  - Note: Not required for visit visa/new arrivals
- Visa transfer willingness:
  - Yes - open to sponsorship
  - No - self-sponsored
  - Depends on offer

**C. Work Location Preferences**
- Emirate selection (multi-select grid):
  - Dubai, Abu Dhabi, Sharjah, Ajman, RAK, Fujairah, UAQ, Al Ain
- Relocation willingness toggle
- Current area/neighbourhood (optional text)

**D. Personal Status**
- Marital status (Married, Single, Divorced, Widowed)
- Children: Yes/No
- If yes: Number of children, Their ages

**E. Health & Wellbeing**
- Privacy notice
- Health conditions: Yes/No + details field
- Regular medication: Yes/No + details field
- Allergies: Yes/No + details field

**F. Personal Comfort & Preferences**
- Cameras at home: Comfortable / Not comfortable + note
- Pets: Yes (love pets) / No + which pets comfortable with
- Cooking: Yes / Childcare only + cuisines
- Night shifts: Yes / Day only

**G. Religion & Faith (Optional)**
- Religion selection: Muslim, Christian, Hindu, Buddhist, Jewish, Other
- Religious practices notes field
- Comfortable working with different faith: Yes / Depends

**H. Emergency Contact**
- Contact name
- Relationship dropdown
- Country code + phone number
- Privacy note

**I. Short Bio**
- 300-character bio textarea
- Tips & character counter

**Navigation:** "Next — Photos & Video" button

---

### Screen 7: Media Upload (Step 2 of 6)
**Purpose:** Upload photos and intro video

**A. Profile Photos**
- Upload area with instructions
- Min 1, max 5 photos
- Guidelines: No sunglasses, no heavy filters
- Tip: "Profiles with photos get 3× more views"
- Photo thumbnail row with delete buttons

**B. Intro Video**
- Video recording/upload area
- Rules:
  - Maximum 60 seconds (strict)
  - Speak clearly, smile, good lighting
  - Do NOT share phone number in video
- Tips on what to say:
  - Name, nationality, years experience
  - Children ages cared for
  - One thing families love about you
- Video preview with play button, duration, progress bar
- "Record or upload video" button

**Navigation:** "Next — Work experience" button

---

### Screen 8: Work Experience (Step 3 of 6)
**Purpose:** Document previous employment

**Each Experience Card Contains:**
- Card number header with delete button
- Job title dropdown (Live-in Nanny, Live-out Nanny, Babysitter, Newborn Specialist, Housekeeper & Nanny)
- Family/Employer name
- City & Country
- From/To dates
- Children cared for (description)
- Main duties (textarea)
- Reason for leaving dropdown (Family relocated, Contract ended, Children grew up)

**Features:**
- "+ Add another job" button
- Multiple experience cards supported

**Navigation:** "Next — References" button

---

### Screen 9: References (Step 4 of 6)
**Purpose:** Declare callable references

**How References Work Banner:**
1. Declare you have callable references (no names/numbers on app)
2. Families see "✓ Has callable references" on profile
3. Share contact directly during interview/trial
4. Must follow through

**Elements:**
- "Do you have callable references?" Yes/No
- Number of references dropdown
- For each reference:
  - Relationship (Previous employer, Agency supervisor, etc.)
  - City
  - Years worked
  - What they can confirm
  - Note: "You will share this contact directly during interview"
- "+ Add another reference" button
- Commitment checkbox

**Navigation:** "Next — Documents" button

---

### Screen 10: Document Upload (Step 5 of 6)
**Purpose:** Upload verification documents

**Warning Banner:** "Your profile stays hidden until admin approves all mandatory documents"

**Mandatory Documents:**
- Passport Copy (bio page, JPG/PDF)
- Visa Page (current stamp/digital visa)
- Emirates ID (conditional - only if you have one)
  - "I have EID — upload" / "No EID (visit visa)" toggle

**Optional Documents (builds trust, ranks higher):**
- Training Certificates (First Aid, CPR, Childcare, Cooking)
- Police Clearance

**Status Indicators:** Required, Uploaded, Missing, Conditional, Optional

**Navigation:** "Submit for admin review" button

---

### Screen 11: Pending Review (Step 6 of 6)
**Purpose:** Waiting state after profile submission

**Elements:**
- Pulsing clock animation
- "Profile submitted! 🌸" title
- "Admin is reviewing... Usually 1-24 hours"
- While you wait info box
- Document Status List:
  - Passport Copy: Reviewing
  - Visa Page: Reviewing
  - Emirates ID: Missing (with upload prompt)
  - Intro Video: Reviewing
- Upload Emirates ID button (if missing)

---

### Screen 12: Nanny Dashboard (Approved)
**Purpose:** Home screen after approval

**Hero Section:**
- Profile avatar with verified badge
- Name, role, location
- "Kafi Verified ✓" status
- Stats row: Shortlists, Profile views, Rating

**Profile Quality Card:**
- Score percentage (e.g., 78%)
- Progress bar
- Checklist:
  - ✓ Profile 100% complete
  - ✓ Kafi Verified badge
  - ✓ Video introduction uploaded
  - ✓ Multiple photos added
  - + Add police clearance → +10pts
  - + Add training certificate → +7pts
  - + Log in within 7 days → +5pts

**Jobs Section:**
- "Jobs for you" title with "See all" link
- Job cards with:
  - Family avatar
  - Job title, location
  - Family nationality, salary, children info
  - Match percentage badge
  - Tags (English, Live-in, Newborn, Trial paid)

**Bottom Navigation:**
- Home (active), Jobs, Messages, Profile

---

## FAMILY MOBILE APP SCREENS

### Screen 13: Family Job Post Form
**Purpose:** Create job requirements

**Progress:** Step 2 of 4 (assumes Step 1 is registration)

**A. Your Family Section:**
- Full name
- Nationality (comprehensive dropdown by region)
- City/Emirate dropdown
- Number of children
- Children's ages
- Languages at home (multi-select chips)
- Home cameras: Yes/No
- Pets: Dog/Cat toggles

**B. Religion & Household Culture:**
- Privacy explanation
- Family religion (optional grid selection)
- Nanny religious requirements:
  - No preference
  - Prefer Muslim nanny
  - Prefer same religion
  - Open but must respect home rules
- Faith-related house rules (optional textarea)

**C. Role & Job Type:**
- Roles needed (multi-select: Nanny, Maid, Caregiver, Cook, Babysitter, Helper, Pet Caretaker)
- Job type: Live-in / Live-out
- Working schedule

**D. Duties Checklist:**
- Grid of duties: Newborn, Childcare, Cook family, Light cleaning, Laundry, Pet care, Driving, Tutoring, First Aid

**E. Benefits You Offer:**
- Grid: Meals provided, Private room, Yearly flight, Health insurance, Phone provided, Days off weekly

**F. Salary, Trial & Visa:**
- Min/Max salary range (AED/month)
- Paid trial period dropdown
- Trial daily rate

**Visa Sponsorship Section (Key):**
- Options:
  - Yes — full sponsorship (we cover all costs)
  - Yes — nanny shares some costs
  - Only for nannies with valid UAE residence
  - No — nanny must have own visa
- Info note: Sponsorship attracts more qualified nannies
- Commitment checkbox

**Navigation:** "Find my perfect nanny" button

---

### Screen 14: Browse Nannies (Family Home)
**Purpose:** Discover and filter nannies

**Hero Section:**
- Logo, notifications icon (with badge)
- Greeting with family name
- Search bar

**Filter Pills:** All, Live-in, Newborn, Arabic, Filipino, Indian

**Nanny Cards (Featured & Regular):**
- Avatar
- Name with "Verified ✓" badge
- Nationality, years exp, job type, location, availability
- Match percentage badge
- Tags (languages, skills, Video indicator)

**Bottom Navigation:** Home, Search, Messages, Profile

---

### Screen 15: Nanny Profile - Locked View
**Purpose:** Profile view when family not subscribed

**Profile Header:**
- Back button, favorite button
- Avatar with verified badge
- Name, role, location, nationality
- Match percentage

**Stats Row:** Years exp, Rating, Reviews

**Skills Tags:** Verified items shown

**Locked Content Box:**
- "Contact & full profile locked 🔒"
- Blurred items:
  - Phone number
  - Full CV
  - Intro video
- Subscribe CTA:
  - Price: 89 AED/week
  - "Subscribe now" button
  - Perks list

---

### Screen 16: Nanny Profile - Unlocked View (Subscription ACTIVE)
**Purpose:** Full profile access for subscribed families

**Same header as locked, plus:**

**Subscription Badge:** "Monthly plan active · Full access unlocked"

**Contact Section (Green Box):**
- Direct phone number displayed
- WhatsApp button (large)
- Call button (large)
- In-app chat button
- Full CV button

**Additional Contact Cards:**
- WhatsApp with Chat action
- Email with Email action
- "Download Sarah's full CV" button

**Action Buttons:**
- Shortlist
- Send trial offer

---

### Screen 16A: Nanny Profile - Re-Locked View (Subscription EXPIRED)
**Purpose:** Profile when family subscription has ended (previously had access)

**Header Banner (Orange/Amber):**
- ⚠️ "Your subscription expired"
- "Renew to view contact details and chat"
- "Renew Now" CTA button

**Profile Content (Limited):**
- Avatar, name, basic intro: ✅ Visible
- Photos and intro video: ✅ Visible
- Match score: ✅ Visible
- Bio: ⚠️ Truncated with "Subscribe to read full bio"
- Experience: ⚠️ Limited preview

**Contact Section (Blurred/Locked):**
- 🔒 Phone number: Blurred ("••• ••• ••••" with lock icon)
- ❌ WhatsApp button: Removed
- ❌ Call button: Removed
- ❌ In-app chat button: Replaced with "Renew to chat"
- 🔒 CV download: Greyed out with lock icon

**Action Buttons:**
- ❌ Send trial offer: Disabled with subscribe CTA
- ✅ Shortlist: Still available (preview only)
- "Renew Subscription" prominent CTA

**Exception:**
- If an active trial exists with this nanny → full access remains until trial ends
- Shown as: "Active trial · Contact info available"

---

### Screen 16B: Chat List - Subscription Expired State
**Purpose:** Empty state shown when family's subscription has ended

**UI Elements:**
- Lock icon (large, grey)
- Heading: "Your subscription has expired"
- Subtext: "Renew your subscription to access your chats and nanny contacts"
- Body text: "All your messages, shortlists, and contacts are saved and will be restored instantly when you renew"
- "Renew Subscription" prominent CTA button (full-width)
- "View Plans" secondary link

**Special Case - Active Trials:**
- If active trial(s) exist:
  - Show banner: "You have 1 active trial - chat below"
  - Display only active-trial chat threads below the lock UI
  - All other threads remain hidden

---

### Screen 17: In-App Chat
**Purpose:** Messaging between family and nanny

**Family View (Subscribed - ACTIVE):**
- Top bar with nanny avatar, name, status (Online)
- WhatsApp direct button, Call button
- Contact strip: "Subscribed · Direct contacts unlocked" with Call/WhatsApp buttons
- Message bubbles (sender aligned right, receiver left)
- Date separators
- System messages
- Trial offer message card with Accept/Counter buttons
- Trial accepted confirmation message
- Input area with attach button, text input, send button

**Family View (EXPIRED Subscription):**
- Chat thread hidden from chat list entirely
- If accessed via deep link (push notif): Land on paywall
- Full-screen lock overlay: "🔒 Your subscription expired"
- Subtext: "Renew to view this chat and contact details"
- "Renew Subscription" CTA button
- Back button returns to chat list (empty)
- No message history visible, no send capability
- Exception: If chat thread has an ACTIVE trial → full access remains until trial ends

**Family View (Free Tier - Never Subscribed):**
- Limited: can send text messages after viewing profile
- Phone/WhatsApp buttons hidden
- "Subscribe for direct contact" CTA in chat header

**Nanny View:**
- Purple theme
- Top bar with family avatar (first name only + "Family")
- Contact strip: "Family number is private · Chat is your connection"
- Same message bubbles
- Trial offer received card
- If family's subscription expired:
  - Banner: "Family's subscription has expired - they may not see new messages"
  - Nanny CAN still send messages (queued; delivered when family renews)
  - System message visible: "Family lost access on [date]"

**Chat List Screen (Family View):**
- IF subscription ACTIVE / CANCELLED-IN-PERIOD:
  - Search conversations
  - Thread cards showing:
    - Avatar
    - Name
    - Last message preview
    - Time
    - Status badges (ON TRIAL, unread count)
    - Trial day progress
  - Privacy note explaining contact rules
- IF subscription EXPIRED / PAYMENT_FAILED:
  - Empty state with lock icon
  - Heading: "Your subscription has expired"
  - Subtext: "Renew to view your chats and contacts"
  - "Renew Subscription" CTA button
  - **Exception:** Active-trial threads still appear (with badge: "Trial Active")

**Chat List Screen (Nanny View):**
- Always full access (free tier users)
- All threads visible regardless of family's subscription state
- Threads with expired families show subtle indicator: "Family subscription expired"

---

### Screen 18: Smart Match
**Purpose:** Show compatibility before nanny applies

**Low Match (46%) Warning:**
- Red score ring
- "Not quite the right match" message
- Failure checklist (what doesn't match)
- "Go back" / "Apply anyway" buttons

**High Match (91%) Success:**
- Green score ring
- "You're a great fit! 🌸" message
- Success checklist (what matches)
- Warning items (minor issues)
- "Send application now" button

**Checklist Items Evaluated:**
- Language requirements
- Years of experience
- Specific skills (e.g., newborn)
- Job type (live-in/out)
- Salary range

---

### Screen 19: Trial System
**Purpose:** Manage active paid trials

**Trial Active Screen (Family View):**
- Green theme
- Status badge: "Trial Active"
- Timer: "5d 14h 22m" remaining
- Trial details: duration, daily rate, end date
- Party cards showing both family and nanny with "Revealed" phone status

**Evaluation Checklist:**
- Child interaction & patience ✓
- Punctuality & reliability ✓
- Following instructions ✓
- Communication & Arabic (unchecked)
- Cooking (unchecked)
- Honesty & trustworthiness ✓

**Outcome Buttons:**
- "Hire!" (green)
- "Not this time" (outline)

---

## SHARED FEATURES

### Screen 20: Pricing & Plans
**Purpose:** Display subscription options

**Free Tier Info:**
- 5 free profile views included (viewing a profile = using 1 contact)
- Progress bar showing usage (e.g., "3 of 5 used")
- List of free features
- Viewed nannies history

**Plan Selection:**
- Features banner (all plans include same features)
- Weekly: AED 89 (7 days)
- Monthly: AED 239 (30 days) - "Most popular"
- 2 Months: AED 369 (60 days) - "Save 129 AED"
- VAT note: +5%
- Trust badges: SSL, UAE trusted, 5-star

**Payment Screen:**
- Order summary
- Native payment sheet (Apple Pay on iOS / Google Pay on Android)
- Handled entirely by App Store / Play Store
- RevenueCat manages subscription state
- No custom card form needed

**Note:** Payment UI is the native iOS/Android subscription purchase flow. User taps "Subscribe" → native payment sheet appears → confirms with Face ID/fingerprint → subscription activated.

---

### Screen 21: Terms & Conditions
**Purpose:** Legal terms

**Key Points:**
1. Platform is marketplace only
2. Kafi does NOT employ, sponsor, or act as recruitment agency
3. User eligibility: 18+, accurate info, comply with UAE laws
4. Profile accuracy requirements
5. Verification limitations
6. Communication monitoring
7. Payment & VAT terms
8. Liability limitations
9. Termination rights
10. UAE governing law

---

### Screen 22: Privacy Policy
**Purpose:** Data handling policy

**Key Points:**
1. Data collected: Personal, documents, profile, media, technical
2. Usage purposes
3. Consent
4. Data sharing rules
5. Phone privacy (nanny visible, family private)
6. Data protection measures
7. User rights
8. Age restriction (18+)

---

## ADMIN PANEL

### Screen 23: Admin Dashboard (Web)
**Purpose:** Owner-only management interface

**Sidebar Navigation:**
- Dashboard
- All nannies (142)
- Verify docs (8)
- Review videos (14)
- All families (87)
- Subscriptions (54)
- Revenue
- Broadcast
- Settings

**Top Stats Cards:**
- Total users: 229
- Active subs: 54
- This month revenue: AED 10,800
- VAT collected: AED 540

**Revenue by Plan:**
- Weekly AED 89: 25 active, AED 2,225
- Monthly AED 239: 30 active, AED 7,170
- 2 months AED 369: 10 active, AED 3,690
- VAT: AED 654

**Nannies Column:**
- Stats: Active (134), Pending docs (8), Videos to review (14)
- Document verification queue with Approve/Reject buttons
- All nannies list with status
- Nationality breakdown chart
- City breakdown chart

**Families Column:**
- Stats: Subscribed (54), Free users (33), New today (8)
- Recent family accounts
- Subscription breakdown
- Family nationality breakdown
- Active trials monitoring

---

## PRICING & SUBSCRIPTION

### Subscription Plans (via RevenueCat)

| Plan | Duration | Price | Notes |
|------|----------|-------|-------|
| Weekly | 7 days | AED 89 | Auto-renews weekly |
| Monthly | 30 days | AED 239 | Auto-renews monthly (Most Popular) |
| 2 Months | 60 days | AED 369 | Auto-renews every 2 months |

**Note:** Prices are set in App Store Connect and Google Play Console. VAT/taxes handled by Apple/Google based on user location.

### Free Tier (No Subscription - Never Subscribed)
- Browse all verified nanny profiles
- Watch all intro videos
- See match scores
- **5 free profile views** (each view counts as 1 contact)
- In-app chat (after viewing profile)

### Subscribed Features (Status: ACTIVE)
- **Unlimited profile views**
- Download full CVs
- Send trial offers
- Call/WhatsApp nannies directly
- Full chat access (read history + send messages)
- See nanny phone numbers
- Priority support

### Post-Subscription Lockdown (Status: EXPIRED / PAYMENT_FAILED)
When a family's subscription **ends** (expires, billing fails, or cancellation reaches end date), the app enters **lockdown mode**:

- ❌ **Nanny phone numbers** → re-hidden (blurred) on all profiles
- ❌ **Chat list** → hidden behind paywall
- ❌ **Individual chat threads** → cannot open, history hidden, cannot send messages
- ❌ **Call / WhatsApp buttons** → removed
- ❌ **CV downloads** → disabled
- ❌ **Trial offers** → cannot send new ones
- ❌ **Full profile views** → blocked (even profiles previously viewed)
- ✅ **Browse cards / intro videos / match scores** → still accessible
- ✅ **Active trial chat & contacts** → exception: remains accessible until trial ends
- ✅ **Data preserved** → chats, shortlist, history all retained (just hidden)
- 🔄 **On re-subscription** → everything restored instantly (chats reappear, phones unlocked)

### Subscription States Summary

| State | Description | Contacts | Chat |
|-------|-------------|----------|------|
| `free` | Never subscribed | Hidden | Limited (after view) |
| `active` | Paid + within period | ✅ Visible | ✅ Full access |
| `cancelled` | Cancelled but still in period | ✅ Visible | ✅ Full access |
| `expired` | Past end date | ❌ Hidden | ❌ Locked |
| `payment_failed` | Renewal failed | ❌ Hidden | ❌ Locked |

### Subscription Management
- **Platform:** RevenueCat SDK
- **Payment:** Apple Pay (iOS) / Google Pay (Android)
- **Auto-renewal:** Yes, by default
- **Cancel:** Via device's subscription settings (App Store / Play Store)
- **Restore:** "Restore Purchases" button in settings
- **Grace Period:** Standard Apple/Google grace periods apply
- **Re-subscription:** Restores all previously-locked features (chat history, contacts, shortlist)

---

## ADDITIONAL SCREENS - DETAILED SPECIFICATIONS

### Screen 24: Nanny Job Listings / Browse Jobs

**Purpose:** Allow nannies to discover and browse family job postings

**Access:** Bottom nav "Jobs" tab in Nanny app

---

#### 24A: Jobs Home Screen

**Header Section:**
- "Find your perfect job 🌸" title
- Subtitle: "X jobs matching your profile"
- Search bar: "Search by location, job type, salary..."

**Quick Stats Banner:**
```
┌─────────────────────────────────────────┐
│  📊 Your Job Stats                      │
│  ┌───────┐ ┌───────┐ ┌───────┐         │
│  │  12   │ │   5   │ │   2   │         │
│  │Applied│ │Viewed │ │ Offers│         │
│  └───────┘ └───────┘ └───────┘         │
└─────────────────────────────────────────┘
```

**Filter Pills (Horizontal Scroll):**
- All Jobs (active by default)
- Best Match (90%+)
- Live-in
- Live-out
- Newborn
- My Emirates (based on profile preferences)
- Urgent (family needs immediate start)

**Sort Dropdown:**
- Best Match (default)
- Newest First
- Highest Salary
- Nearest Location

**Job Cards List:**

```
┌─────────────────────────────────────────┐
│ 🔥 HOT MATCH                            │
│ ┌────┐                                  │
│ │ F  │  Live-in Nanny · Dubai Marina    │
│ └────┘  Emirati family · 2 children     │
│         AED 2,500 - 3,000/mo            │
│                                         │
│  ⭐ 94% match                           │
│                                         │
│  [Newborn] [English] [Arabic] [Live-in] │
│                                         │
│  ✓ Visa sponsorship offered             │
│  ✓ Private room · ✓ Yearly flight       │
│                                         │
│  Posted 2 hours ago                     │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ ┌────┐                                  │
│ │ J  │  Full-time Nanny · Abu Dhabi     │
│ └────┘  British family · 3 children     │
│         AED 2,200/mo                    │
│                                         │
│  ⭐ 78% match                           │
│                                         │
│  [Toddler] [English] [Live-out]         │
│                                         │
│  ⚠ Nanny must have own visa            │
│                                         │
│  Posted yesterday                       │
└─────────────────────────────────────────┘
```

**Card Elements:**
- Family avatar (initial, colored gradient)
- Job title + location
- Family nationality + number of children
- Salary range
- Match percentage badge (green >80%, orange 60-80%, red <60%)
- Skill/requirement tags
- Visa sponsorship indicator (✓ offered / ⚠ not offered)
- Benefits highlights
- Posted time
- "HOT MATCH" badge for 90%+ matches

**Empty State:**
- Illustration of job search
- "No jobs found matching your filters"
- "Try adjusting your filters or check back later"
- "Update your profile to get better matches" CTA

---

#### 24B: Job Detail Screen

**Header:**
- Back button
- Share button
- Save/Bookmark button (heart icon)

**Family Card:**
```
┌─────────────────────────────────────────┐
│  ┌──────┐                               │
│  │  F   │  Al Mansoori Family           │
│  │      │  Emirati · Dubai Marina       │
│  └──────┘  Member since 2024            │
│                                         │
│  [Verified ✓]  [5 hires on Kafi]        │
└─────────────────────────────────────────┘
```

**Match Score Section:**
```
┌─────────────────────────────────────────┐
│        ┌─────────┐                      │
│        │   94%   │                      │
│        │  MATCH  │                      │
│        └─────────┘                      │
│   "You're a great fit for this job!"   │
│                                         │
│  ✓ Languages match                      │
│  ✓ Experience exceeds requirement       │
│  ✓ Location preference matches          │
│  ✓ Job type matches                     │
│  ⚠ Salary slightly below expectation   │
└─────────────────────────────────────────┘
```

**Job Details Section:**

**Role & Schedule:**
- Job title: Live-in Nanny
- Job type: Live-in / Live-out
- Schedule: Sun-Thu, 7am-7pm
- Start date: Immediate / Specific date
- Duration: Permanent / Contract (X months)

**Children:**
- Number of children: 2
- Ages: 6 months, 3 years
- Special needs: None / Details

**Requirements:**
- Experience: 3+ years
- Languages: English (required), Arabic (preferred)
- Skills required: Newborn care, First aid
- Nationality preference: Any / Specific
- Religion preference: Any / Specific

**Duties Checklist:**
- ✓ Childcare
- ✓ Newborn care
- ✓ Light cooking (children's meals)
- ✓ Laundry (children's clothes)
- ✗ Full house cleaning
- ✗ Pet care

**Salary & Benefits:**
```
┌─────────────────────────────────────────┐
│  💰 Compensation                        │
│                                         │
│  Salary: AED 2,500 - 3,000/month        │
│                                         │
│  ✓ Meals provided                       │
│  ✓ Private room with bathroom           │
│  ✓ Yearly flight home                   │
│  ✓ Phone/SIM provided                   │
│  ✓ 1 day off per week                   │
│  ✓ Health insurance                     │
└─────────────────────────────────────────┘
```

**Visa & Sponsorship:**
```
┌─────────────────────────────────────────┐
│  🛂 Visa Sponsorship                    │
│                                         │
│  ✅ Full sponsorship offered            │
│                                         │
│  Family will sponsor your UAE residence │
│  visa after successful trial period.    │
│  All visa costs covered by family.      │
└─────────────────────────────────────────┘
```

**Trial Period:**
```
┌─────────────────────────────────────────┐
│  🤝 Trial Period                        │
│                                         │
│  Duration: 7 days (paid)                │
│  Daily rate: AED 150/day                │
│  Total trial pay: AED 1,050             │
│                                         │
│  Live-in during trial · Room provided   │
└─────────────────────────────────────────┘
```

**About the Family (Optional text from family):**
- "We are a loving Emirati family looking for..."

**Action Buttons:**
```
┌─────────────────────────────────────────┐
│  [    💬 Message Family    ]            │
│                                         │
│  [    ✨ Apply for this Job    ]        │
│         (green, primary CTA)            │
└─────────────────────────────────────────┘
```

**Already Applied State:**
```
┌─────────────────────────────────────────┐
│  ✅ Application Sent                    │
│  Applied on May 15, 2026                │
│                                         │
│  Status: Pending family review          │
│                                         │
│  [    💬 Message Family    ]            │
│  [    ❌ Withdraw Application  ]        │
└─────────────────────────────────────────┘
```

---

#### 24C: Advanced Filters Screen (Modal/Bottom Sheet)

**Location:**
- Emirates (multi-select checkboxes)
- Specific areas within emirate (optional)

**Job Type:**
- Live-in
- Live-out
- Both

**Salary Range:**
- Min slider: AED 1,000 - 5,000
- Max slider: AED 1,000 - 5,000

**Children Age Groups:**
- Newborn (0-12 months)
- Toddler (1-3 years)
- Preschool (3-5 years)
- School age (5-12 years)
- Teenager (12+)

**Family Nationality:**
- Any
- Specific nationalities (multi-select)

**Visa Sponsorship:**
- Required (must offer sponsorship)
- Not required

**Start Date:**
- Immediate
- Within 1 week
- Within 1 month
- Flexible

**Buttons:**
- "Clear All" (text button)
- "Apply Filters" (primary button)
- Show results count: "Show 24 jobs"

---

### Screen 25: Nanny Application Flow

**Purpose:** Apply to jobs with smart match feedback

---

#### 25A: Pre-Application Smart Match Screen

**Triggered:** When nanny taps "Apply for this Job"

**Header:**
- "Applying to this job?" title
- "We checked your profile first 🌸" subtitle

**Job Summary Card:**
- Job title + location
- Key requirements summary

**Match Score Ring:**
- Large circular progress (like existing Smart Match screen)
- Percentage in center
- Color: Green (>80%), Orange (60-80%), Red (<60%)

**Match Analysis:**

**High Match (80%+):**
```
┌─────────────────────────────────────────┐
│           ┌─────────┐                   │
│           │   91%   │                   │
│           └─────────┘                   │
│                                         │
│   "You're a great fit! 🌸"              │
│   Almost everything matches perfectly   │
│                                         │
│   ✓ Arabic + English — matches          │
│   ✓ 5 yrs exp — exceeds 3yr requirement │
│   ✓ Newborn experience — verified       │
│   ✓ Live-in availability — matches      │
│   ⚠ Salary slightly above range         │
│                                         │
│   [    ✨ Send Application    ]         │
│   (green button)                        │
└─────────────────────────────────────────┘
```

**Low Match (<60%):**
```
┌─────────────────────────────────────────┐
│           ┌─────────┐                   │
│           │   46%   │                   │
│           └─────────┘                   │
│                                         │
│   "Not quite the right match"           │
│   3 requirements don't match            │
│                                         │
│   ✗ Arabic required — not on profile    │
│   ✗ Needs 3+ years — you have 1 year    │
│   ⚠ Newborn experience — unclear        │
│   ✓ Live-in availability — matches      │
│   ✓ Salary range — within expectation   │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ ⚠ Low match warning             │   │
│   │ Families may not respond to     │   │
│   │ applications below 60% match.   │   │
│   │ Consider updating your profile. │   │
│   └─────────────────────────────────┘   │
│                                         │
│   [  ← Go Back  ] [  Apply Anyway  ]    │
└─────────────────────────────────────────┘
```

---

#### 25B: Application Message Screen

**Header:**
- "Send your application" title
- Job title as subtitle

**Cover Message:**
```
┌─────────────────────────────────────────┐
│  ✉️ Message to Family (optional)        │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ Write a brief message...          │  │
│  │                                   │  │
│  │ Tip: Mention why you're perfect   │  │
│  │ for this job and when you can     │  │
│  │ start.                            │  │
│  │                                   │  │
│  └───────────────────────────────────┘  │
│                              145 / 300  │
└─────────────────────────────────────────┘
```

**Quick Phrases (Chips):**
- "Available immediately"
- "Experienced with newborns"
- "Can speak Arabic"
- "Have references"
- "Flexible with hours"

**Profile Preview:**
```
┌─────────────────────────────────────────┐
│  👤 What family will see               │
│                                         │
│  ┌────┐ Sarah Reyes                     │
│  │ S  │ Filipino · 5 yrs exp · Dubai    │
│  └────┘ ⭐ 4.9 rating · Verified ✓      │
│                                         │
│  [Newborn] [English] [Arabic] [Video]   │
│                                         │
│  [ 👁 Preview full profile ]            │
└─────────────────────────────────────────┘
```

**Submit Button:**
- "Send Application" (green, primary)
- Checkbox: "Notify me when family views my application"

---

#### 25C: Application Sent Confirmation

**Success State:**
```
┌─────────────────────────────────────────┐
│                                         │
│           ✅                            │
│    Application Sent!                    │
│                                         │
│    Your application for                 │
│    "Live-in Nanny · Dubai Marina"       │
│    has been sent to the family.         │
│                                         │
│    ┌─────────────────────────────────┐  │
│    │ What happens next:              │  │
│    │                                 │  │
│    │ 1. Family reviews your profile  │  │
│    │ 2. If interested, they message  │  │
│    │    you or send a trial offer    │  │
│    │ 3. You'll get a notification    │  │
│    └─────────────────────────────────┘  │
│                                         │
│    Average response time: 1-3 days      │
│                                         │
│  [    Browse More Jobs    ]             │
│  [    View My Applications    ]         │
│                                         │
└─────────────────────────────────────────┘
```

---

#### 25D: My Applications Screen

**Access:** Profile tab → "My Applications" or Jobs tab → "Your Applications"

**Header:**
- "My Applications" title
- Filter: All / Pending / Accepted / Declined

**Stats Bar:**
```
┌───────────┬───────────┬───────────┐
│    12     │     3     │     2     │
│   Total   │  Pending  │  Offers   │
└───────────┴───────────┴───────────┘
```

**Application Cards:**

**Pending:**
```
┌─────────────────────────────────────────┐
│  ⏳ PENDING                             │
│                                         │
│  Live-in Nanny · Dubai Marina           │
│  Al Mansoori Family · Emirati           │
│                                         │
│  Applied: May 15, 2026                  │
│  Match: 94%                             │
│                                         │
│  [  Message  ]  [  Withdraw  ]          │
└─────────────────────────────────────────┘
```

**Viewed by Family:**
```
┌─────────────────────────────────────────┐
│  👁 VIEWED                              │
│                                         │
│  Full-time Nanny · Abu Dhabi            │
│  Johnson Family · British               │
│                                         │
│  Applied: May 14, 2026                  │
│  Viewed: 2 hours ago                    │
│                                         │
│  [  Message  ]  [  Withdraw  ]          │
└─────────────────────────────────────────┘
```

**Trial Offer Received:**
```
┌─────────────────────────────────────────┐
│  🎉 TRIAL OFFER                   NEW   │
│                                         │
│  Live-in Nanny · Sharjah                │
│  Ahmed Family · Emirati                 │
│                                         │
│  7-day trial · AED 150/day              │
│  Starts: May 20, 2026                   │
│                                         │
│  [  Decline  ]  [  ✓ Accept  ]          │
└─────────────────────────────────────────┘
```

**Declined:**
```
┌─────────────────────────────────────────┐
│  ❌ NOT SELECTED                        │
│                                         │
│  Part-time Babysitter · JLT             │
│  Smith Family · American                │
│                                         │
│  Applied: May 10, 2026                  │
│  Declined: May 12, 2026                 │
│                                         │
│  "Family chose another candidate"       │
└─────────────────────────────────────────┘
```

---

### Screen 26: Family Shortlist / Favorites

**Purpose:** Save and manage favorite nannies

**Access:** Bottom nav "Favorites" or Heart icon throughout app

---

#### 26A: Shortlist Home Screen

**Header:**
- "My Shortlist 💜" title
- "X nannies saved" subtitle
- Sort dropdown: Recently added / Best match / Name

**Empty State:**
```
┌─────────────────────────────────────────┐
│                                         │
│           💜                            │
│                                         │
│    Your shortlist is empty              │
│                                         │
│    Save nannies you like by tapping     │
│    the heart icon on their profile.     │
│                                         │
│    [    Browse Nannies    ]             │
│                                         │
└─────────────────────────────────────────┘
```

**Shortlist Cards:**
```
┌─────────────────────────────────────────┐
│  ┌────┐  Sarah Reyes                    │
│  │ S  │  Filipino · 5 yrs · Dubai       │
│  └────┘  ⭐ 94% match · Verified ✓       │
│                                         │
│  [Newborn] [English] [Arabic] [Video]   │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 📞 +971 50 234 5678               │  │
│  │ (or 🔒 Subscribe to view)         │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Added: May 15, 2026                    │
│                                         │
│  [  💬 Chat  ] [  📞 Call  ] [  ❌  ]   │
└─────────────────────────────────────────┘
```

**Bulk Actions Bar (when selecting):**
- Select all checkbox
- "X selected"
- "Send Trial Offer to All"
- "Remove Selected"

**Compare Feature:**
```
┌─────────────────────────────────────────┐
│  Compare nannies (select 2-3)           │
│                                         │
│  ☐ Sarah R.  ☑ Priya K.  ☑ Amara K.    │
│                                         │
│  [    Compare Selected (2)    ]         │
└─────────────────────────────────────────┘
```

---

#### 26B: Compare Nannies Screen

**Layout:** Side-by-side comparison table

```
┌─────────────────────────────────────────┐
│  Compare Nannies                    ✕   │
├─────────────────────────────────────────┤
│           │  Priya K.  │  Amara K.      │
│  ─────────┼────────────┼────────────    │
│  Photo    │    [P]     │    [A]         │
│  Match    │    82%     │    88%         │
│  ─────────┼────────────┼────────────    │
│  Exp      │   3 yrs    │   4 yrs        │
│  Age      │    28      │    31          │
│  Nation.  │   Indian   │  Ethiopian     │
│  ─────────┼────────────┼────────────    │
│  English  │     ✓      │     ✓          │
│  Arabic   │     ✗      │     ✓          │
│  Hindi    │     ✓      │     ✗          │
│  ─────────┼────────────┼────────────    │
│  Newborn  │     ✓      │     ✓          │
│  Cooking  │     ✓      │     ✗          │
│  Driving  │     ✗      │     ✗          │
│  ─────────┼────────────┼────────────    │
│  Live-in  │     ✓      │     ✓          │
│  Salary   │  2,200     │   2,500        │
│  ─────────┼────────────┼────────────    │
│  Rating   │   4.8★     │   4.9★         │
│  Video    │     ✓      │     ✓          │
│  Verified │     ✓      │     ✓          │
├─────────────────────────────────────────┤
│  [ View Profile ] [ View Profile ]      │
│  [    Send Trial Offer    ]             │
└─────────────────────────────────────────┘
```

---

### Screen 27: Profile Edit Screens

---

#### 27A: Nanny Profile Edit (My Profile Tab)

**Header:**
- Profile avatar (tap to change photo)
- "Edit Profile" title
- "Save" button (top right)

**Profile Completion Bar:**
```
┌─────────────────────────────────────────┐
│  Profile: 85% complete                  │
│  ████████████████░░░░                   │
│  + Add police clearance for +10%        │
└─────────────────────────────────────────┘
```

**Sections (Collapsible Accordions):**

**1. Basic Info** ▼
- Full name (editable)
- Date of birth (editable)
- Nationality (dropdown)
- Languages (multi-select)
- [Same fields as registration]

**2. Photos & Video** ▼
- Photo grid with add/delete
- Video preview with re-record option
- Upload progress indicator

**3. Visa Status** ▼
- Current status (radio options)
- EID availability
- Sponsorship preference

**4. Work Preferences** ▼
- Emirates (multi-select)
- Job type preference
- Expected salary range (NEW)
- Availability status (NEW):
  - Available now
  - Available from [date]
  - On trial with a family
  
**Note:** Profile remains visible in all statuses. No "hide profile" option.

**5. Experience** ▼
- List of experience cards
- Add/edit/delete

**6. References** ▼
- Reference declarations
- Add/edit/delete

**7. Documents** ▼
- Document status list
- Re-upload options
- Expiry date warnings

**8. Health & Preferences** ▼
- Health conditions
- Pet comfort
- Camera comfort
- Religion

**9. Bio** ▼
- Editable textarea
- Character count

**Danger Zone:**
```
┌─────────────────────────────────────────┐
│  ⚠️ Account Actions                     │
│                                         │
│  Your profile is always visible to      │
│  families while your account is active. │
│                                         │
│  [ 🗑 Delete My Account ]               │
│                                         │
└─────────────────────────────────────────┘
```
**Note:** Profile hiding/deactivation is NOT available. Nannies must delete account if they no longer want to be found.

---

#### 27B: Family Profile Edit (My Profile Tab)

**Header:**
- Family avatar
- "Edit Profile" title
- "Save" button

**Sections:**

**1. Family Info** ▼
- Full name
- Nationality
- City/Emirate
- Languages at home
- Home cameras (Yes/No)
- Pets

**2. Children** ▼
- Number of children
- Ages
- Special needs (if any)

**3. Religion & Culture** ▼
- Family religion
- Nanny religion preference
- House rules

**4. Active Job Posts** ▼
```
┌─────────────────────────────────────────┐
│  Live-in Nanny · Dubai Marina           │
│  Posted: May 10 · 15 applications       │
│  Status: Active                         │
│                                         │
│  [ Edit ] [ Pause ] [ Close ]           │
├─────────────────────────────────────────┤
│  [  + Create New Job Post  ]            │
└─────────────────────────────────────────┘
```

**5. Subscription** ▼
```
┌─────────────────────────────────────────┐
│  Current Plan: Monthly                  │
│  Renews: June 15, 2026                  │
│  Status: Active ✓                       │
│                                         │
│  [ Manage Subscription ]                │
│  [ View Payment History ]               │
└─────────────────────────────────────────┘
```

**6. Hiring History** ▼
- Past hires through Kafi
- Reviews given

**Danger Zone:**
- Pause all job posts
- Delete account

---

### Screen 28: Notification Center

**Purpose:** Centralized notification hub

**Access:** Bell icon in header (both apps)

---

#### 28A: Notifications List

**Header:**
- "Notifications" title
- "Mark all read" button
- Filter tabs: All | Messages | Jobs | Trials | System

**Notification Badge:** Red dot with count on bell icon

**Notification Types & Cards:**

**New Message:**
```
┌─────────────────────────────────────────┐
│  💬  New message from Sarah R.      •   │
│      "Thank you for the offer! I..."    │
│      2 minutes ago                      │
└─────────────────────────────────────────┘
```

**Profile Viewed (Nanny):**
```
┌─────────────────────────────────────────┐
│  👁  Your profile was viewed            │
│      Al Mansoori Family viewed your     │
│      profile                            │
│      1 hour ago                         │
└─────────────────────────────────────────┘
```

**New Application (Family):**
```
┌─────────────────────────────────────────┐
│  📝  New application received       •   │
│      Sarah R. applied for your          │
│      "Live-in Nanny" job                │
│      94% match                          │
│      3 hours ago                        │
└─────────────────────────────────────────┘
```

**Trial Offer Received (Nanny):**
```
┌─────────────────────────────────────────┐
│  🎉  Trial offer received!          •   │
│      Al Mansoori Family sent you        │
│      a 7-day trial offer                │
│      AED 150/day · Starts May 20        │
│      Just now                           │
│                                         │
│      [ Decline ] [ Accept ]             │
└─────────────────────────────────────────┘
```

**Trial Accepted (Family):**
```
┌─────────────────────────────────────────┐
│  ✅  Trial accepted!                    │
│      Sarah R. accepted your trial       │
│      Starting May 20 · 7 days           │
│      5 minutes ago                      │
│                                         │
│      [ View Trial Details ]             │
└─────────────────────────────────────────┘
```

**Trial Starting Soon:**
```
┌─────────────────────────────────────────┐
│  ⏰  Trial starts tomorrow!             │
│      Your trial with Sarah R.           │
│      starts tomorrow at 9:00 AM         │
│      12 hours ago                       │
└─────────────────────────────────────────┘
```

**Trial Ending:**
```
┌─────────────────────────────────────────┐
│  🤝  Trial ends in 2 days               │
│      Time to make your decision!        │
│      Your trial with Sarah R. ends      │
│      on May 27                          │
│      2 days ago                         │
│                                         │
│      [ Review & Decide ]                │
└─────────────────────────────────────────┘
```

**Document Approved (Nanny):**
```
┌─────────────────────────────────────────┐
│  ✅  Documents approved!                │
│      Your profile is now verified       │
│      and visible to families            │
│      Yesterday                          │
└─────────────────────────────────────────┘
```

**Document Rejected (Nanny):**
```
┌─────────────────────────────────────────┐
│  ❌  Document rejected                  │
│      Your passport photo was unclear.   │
│      Please re-upload a clear copy.     │
│      Yesterday                          │
│                                         │
│      [ Re-upload Document ]             │
└─────────────────────────────────────────┘
```

**Subscription Expiring (Family):**
```
┌─────────────────────────────────────────┐
│  💳  Subscription expiring soon         │
│      Your monthly plan expires in       │
│      3 days. Renew to keep access.      │
│      2 days ago                         │
│                                         │
│      [ Renew Now ]                      │
└─────────────────────────────────────────┘
```

**System Announcement:**
```
┌─────────────────────────────────────────┐
│  📢  New feature: Video calls!          │
│      You can now schedule video         │
│      interviews directly in the app     │
│      1 week ago                         │
└─────────────────────────────────────────┘
```

**Empty State:**
```
┌─────────────────────────────────────────┐
│                                         │
│           🔔                            │
│                                         │
│    No notifications yet                 │
│                                         │
│    When you have updates, they'll       │
│    appear here                          │
│                                         │
└─────────────────────────────────────────┘
```

---

### Screen 29: Settings Screen

**Purpose:** App preferences and account management

**Access:** Profile tab → Settings gear icon

---

#### 29A: Settings Main Screen

**Account Section:**
```
┌─────────────────────────────────────────┐
│  ACCOUNT                                │
│                                         │
│  📱 Phone Number                    >   │
│     +971 50 234 5678                    │
│                                         │
│  ✉️  Email                          >   │
│     sarah.reyes@email.com               │
│                                         │
│  🔑 Change Password                 >   │
│                                         │
│  🌐 Language                        >   │
│     English                             │
└─────────────────────────────────────────┘
```

**Notifications Section:**
```
┌─────────────────────────────────────────┐
│  NOTIFICATIONS                          │
│                                         │
│  Push Notifications              [ON ]  │
│                                         │
│  Messages                        [ON ]  │
│  Job matches                     [ON ]  │
│  Trial updates                   [ON ]  │
│  Profile views (nanny only)      [OFF]  │
│  Marketing & tips                [OFF]  │
│                                         │
│  Email Notifications             [ON ]  │
│  SMS Notifications               [OFF]  │
└─────────────────────────────────────────┘
```

**Privacy Section:**
```
┌─────────────────────────────────────────┐
│  PRIVACY                                │
│                                         │
│  Show online status              [ON ]  │
│                                         │
│  Show profile views count        [ON ]  │
│  (Nanny only)                           │
│                                         │
│  Allow families to message me    [ON ]  │
│  without applying first                 │
└─────────────────────────────────────────┘
```
**Note:** Profile deactivation/hiding is NOT available.

**Subscription Section (Family only):**
```
┌─────────────────────────────────────────┐
│  SUBSCRIPTION                           │
│                                         │
│  Status: ACTIVE                         │
│  Current Plan                       >   │
│  Monthly · Renews June 15               │
│  (Auto-renewal ON)                      │
│                                         │
│  Manage Subscription                >   │
│  (Opens App Store / Play Store)         │
│                                         │
│  Restore Purchases                  >   │
│                                         │
└─────────────────────────────────────────┘
```

**Subscription Section (EXPIRED state):**
```
┌─────────────────────────────────────────┐
│  ⚠️ SUBSCRIPTION EXPIRED                │
│                                         │
│  Status: EXPIRED                        │
│  Last plan: Monthly                     │
│  Ended: May 15, 2026                    │
│                                         │
│  Locked features:                       │
│   🔒 Chat access                         │
│   🔒 Nanny phone numbers                 │
│   🔒 CV downloads                        │
│   🔒 Trial offers                        │
│                                         │
│  ✨ Renew Subscription              >   │
│  (Restores all access instantly)        │
│                                         │
│  Restore Purchases                  >   │
│                                         │
└─────────────────────────────────────────┘
```

**Note:** Subscriptions managed via RevenueCat. Cancel/manage redirects to App Store or Play Store subscription settings. **When subscription ends, contacts hide and chats lock; data is preserved and restored on renewal.**

**Support Section:**
```
┌─────────────────────────────────────────┐
│  SUPPORT                                │
│                                         │
│  ❓ Help Center / FAQs              >   │
│                                         │
│  💬 Contact Support                 >   │
│                                         │
│  🐛 Report a Problem                >   │
│                                         │
│  ⚠️  Report a User                  >   │
└─────────────────────────────────────────┘
```

**Legal Section:**
```
┌─────────────────────────────────────────┐
│  LEGAL                                  │
│                                         │
│  📜 Terms & Conditions              >   │
│                                         │
│  🛡️  Privacy Policy                 >   │
│                                         │
│  ℹ️  About Kafi                     >   │
│     Version 1.0.0                       │
└─────────────────────────────────────────┘
```

**Danger Zone:**
```
┌─────────────────────────────────────────┐
│  ACCOUNT ACTIONS                        │
│                                         │
│  🚪 Log Out                             │
│                                         │
│  🗑  Delete Account                     │
│     (This cannot be undone)             │
└─────────────────────────────────────────┘
```

---

#### 29B: Delete Account Flow

**Step 1: Confirmation Screen**
```
┌─────────────────────────────────────────┐
│                                         │
│           ⚠️                            │
│                                         │
│    Delete your account?                 │
│                                         │
│    This will permanently delete:        │
│    • Your profile and all data          │
│    • Your photos and videos             │
│    • Your message history               │
│    • Your application history           │
│                                         │
│    This action cannot be undone.        │
│                                         │
│    ┌─────────────────────────────────┐  │
│    │ Why are you leaving? (optional) │  │
│    │ ▼ Select a reason              │  │
│    │   - Found a job                 │  │
│    │   - Not finding matches         │  │
│    │   - Privacy concerns            │  │
│    │   - Technical issues            │  │
│    │   - Other                       │  │
│    └─────────────────────────────────┘  │
│                                         │
│  [ Cancel ]  [ Delete Account ]         │
│              (red button)               │
│                                         │
└─────────────────────────────────────────┘
```

**Step 2: Re-authenticate**
- Enter password or request OTP
- "For security, please verify it's you"

**Step 3: Final Confirmation**
```
┌─────────────────────────────────────────┐
│                                         │
│    Type "DELETE" to confirm             │
│                                         │
│    ┌─────────────────────────────────┐  │
│    │                                 │  │
│    └─────────────────────────────────┘  │
│                                         │
│    [ Permanently Delete Account ]       │
│                                         │
└─────────────────────────────────────────┘
```

---

### Screen 30: Password Reset Flow

**Purpose:** Recover account access

---

#### 30A: Forgot Password Screen

**Access:** Login screen → "Forgot password?" link

**Elements:**
```
┌─────────────────────────────────────────┐
│                                         │
│    🔑 Reset your password               │
│                                         │
│    Enter the phone number linked        │
│    to your account. We'll send you      │
│    an OTP to verify it's you.           │
│                                         │
│    ┌─────────────────────────────────┐  │
│    │ 🇦🇪 +971 │ 50 234 5678          │  │
│    └─────────────────────────────────┘  │
│                                         │
│    [ Send OTP ]                         │
│                                         │
│    ─────── or ───────                   │
│                                         │
│    [ Back to Login ]                    │
│                                         │
└─────────────────────────────────────────┘
```

**Error State:**
- "No account found with this number"
- "Try a different number or sign up"

---

#### 30B: Verify OTP for Reset

**Same as registration OTP screen with context:**
- "Enter the code sent to +971 50 XXX XXX"
- 4 OTP boxes
- Timer
- Resend link

---

#### 30C: Create New Password

```
┌─────────────────────────────────────────┐
│                                         │
│    🔐 Create new password               │
│                                         │
│    Choose a strong password for         │
│    your account.                        │
│                                         │
│    New Password                         │
│    ┌─────────────────────────────────┐  │
│    │ ••••••••                    👁  │  │
│    └─────────────────────────────────┘  │
│    ████████░░ Strong                    │
│                                         │
│    ✓ At least 8 characters              │
│    ✓ Contains a number                  │
│    ✓ Contains uppercase                 │
│                                         │
│    Confirm Password                     │
│    ┌─────────────────────────────────┐  │
│    │ ••••••••                    👁  │  │
│    └─────────────────────────────────┘  │
│    ✓ Passwords match                    │
│                                         │
│    [ Reset Password ]                   │
│                                         │
└─────────────────────────────────────────┘
```

---

#### 30D: Password Reset Success

```
┌─────────────────────────────────────────┐
│                                         │
│           ✅                            │
│                                         │
│    Password updated!                    │
│                                         │
│    Your password has been changed       │
│    successfully. You can now sign       │
│    in with your new password.           │
│                                         │
│    [ Sign In Now ]                      │
│                                         │
└─────────────────────────────────────────┘
```

---

### Screen 31: Trial Offer Creation (Family)

**Purpose:** Family creates and sends trial offer to nanny

**Access:** Nanny profile → "Send Trial Offer" button

---

#### 31A: Create Trial Offer Screen

**Header:**
- "Send Trial Offer" title
- Nanny name and photo

**Nanny Summary Card:**
```
┌─────────────────────────────────────────┐
│  ┌────┐  Sarah Reyes                    │
│  │ S  │  Filipino · 5 yrs · Dubai       │
│  └────┘  ⭐ 94% match · Verified ✓       │
└─────────────────────────────────────────┘
```

**Trial Details Form:**

```
┌─────────────────────────────────────────┐
│  📅 Trial Duration                      │
│                                         │
│  ○ 1 day trial                          │
│  ○ 3 days trial                         │
│  ● 7 days trial (recommended)           │
│  ○ 14 days trial                        │
│  ○ Custom: [___] days                   │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  💰 Daily Rate (AED)                    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 150                             │    │
│  └─────────────────────────────────┘    │
│                                         │
│  💡 Average in Dubai: AED 120-180/day   │
│                                         │
│  Total trial payment: AED 1,050         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  📆 Start Date                          │
│                                         │
│  ○ As soon as possible                  │
│  ● Specific date: [May 20, 2026 ▼]      │
│                                         │
│  ⏰ Start time: [9:00 AM ▼]             │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  🏠 Trial Type                          │
│                                         │
│  ● Live-in during trial                 │
│    Room and meals provided              │
│                                         │
│  ○ Live-out during trial                │
│    Nanny commutes daily                 │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  📍 Location                            │
│                                         │
│  Trial location: Dubai Marina           │
│  (from your job post)                   │
│                                         │
│  [ Edit location ]                      │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  📝 Additional Notes (optional)         │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ Any special instructions or     │    │
│  │ things the nanny should know... │    │
│  │                                 │    │
│  └─────────────────────────────────┘    │
│                                  0/300  │
└─────────────────────────────────────────┘
```

**Trial Summary:**
```
┌─────────────────────────────────────────┐
│  📋 Trial Offer Summary                 │
│                                         │
│  Duration:     7 days                   │
│  Daily rate:   AED 150                  │
│  Total pay:    AED 1,050                │
│  Start date:   May 20, 2026 at 9:00 AM  │
│  Type:         Live-in                  │
│  Location:     Dubai Marina             │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ ⚠️ Payment is handled directly   │    │
│  │ between you and the nanny.      │    │
│  │ Kafi does not process trial     │    │
│  │ payments.                        │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ☑ I understand payment is direct      │
│                                         │
│  [ Cancel ]  [ Send Trial Offer ]       │
│              (green button)             │
└─────────────────────────────────────────┘
```

**Important:** Kafi only facilitates finding nannies. All trial payments are handled directly between family and nanny outside the app.

---

#### 31B: Trial Offer Sent Confirmation

```
┌─────────────────────────────────────────┐
│                                         │
│           ✅                            │
│                                         │
│    Trial offer sent!                    │
│                                         │
│    Sarah R. will receive your offer     │
│    and can accept or counter it.        │
│                                         │
│    ┌─────────────────────────────────┐  │
│    │ 7 days · AED 150/day            │  │
│    │ Starts: May 20, 2026            │  │
│    │ Live-in · Dubai Marina          │  │
│    └─────────────────────────────────┘  │
│                                         │
│    You'll be notified when she          │
│    responds.                            │
│                                         │
│  [ Message Sarah ]  [ Back to Browse ]  │
│                                         │
└─────────────────────────────────────────┘
```

---

### Screen 32: Nanny Trial View

**Purpose:** Nanny's view of active and pending trials

---

#### 32A: Trial Offer Received (Pending)

**Access:** Notification tap or Applications screen

```
┌─────────────────────────────────────────┐
│  ← Back                                 │
│                                         │
│           🎉                            │
│    Trial Offer Received!                │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  ┌────┐  Al Mansoori Family         ││
│  │  │ F  │  Emirati · Dubai Marina     ││
│  │  └────┘  Member since 2024          ││
│  │          5 hires on Kafi            ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  📋 Trial Details                   ││
│  │                                     ││
│  │  Duration:     7 days               ││
│  │  Daily rate:   AED 150              ││
│  │  Total pay:    AED 1,050            ││
│  │  Start date:   May 20, 2026         ││
│  │  Start time:   9:00 AM              ││
│  │  Type:         Live-in              ││
│  │  Location:     Dubai Marina         ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  📝 Family's note:                  ││
│  │  "We have a 6-month-old and a      ││
│  │  3-year-old. Looking forward to    ││
│  │  meeting you!"                      ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  🏠 About the job:                  ││
│  │  2 children (6 months, 3 years)     ││
│  │  Duties: Childcare, light cooking   ││
│  │  Benefits: Room, meals, flight      ││
│  │  Salary after trial: AED 2,500-3k   ││
│  │  Visa sponsorship: ✓ Offered        ││
│  └─────────────────────────────────────┘│
│                                         │
│  [ 💬 Message Family ]                  │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  Respond by: May 18, 2026 (2 days) ││
│  └─────────────────────────────────────┘│
│                                         │
│  [ Decline ]  [ 🔄 Counter ]  [ ✓ Accept ]│
│                                         │
└─────────────────────────────────────────┘
```

---

#### 32B: Counter Offer Screen

```
┌─────────────────────────────────────────┐
│  ← Back         Counter Offer           │
│                                         │
│  Original offer: 7 days @ AED 150/day   │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  💰 Your proposed daily rate        ││
│  │  ┌─────────────────────────────┐    ││
│  │  │ 180                         │    ││
│  │  └─────────────────────────────┘    ││
│  │  Original: AED 150                  ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  📅 Preferred start date            ││
│  │  ○ Keep original (May 20)           ││
│  │  ● Different date: [May 22 ▼]       ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  📝 Message to family (optional)    ││
│  │  ┌─────────────────────────────┐    ││
│  │  │ Explain your counter...     │    ││
│  │  └─────────────────────────────┘    ││
│  └─────────────────────────────────────┘│
│                                         │
│  New total: AED 1,260 (7 × 180)         │
│                                         │
│  [ Cancel ]  [ Send Counter Offer ]     │
│                                         │
└─────────────────────────────────────────┘
```

---

#### 32C: Active Trial Screen (Nanny View)

**Access:** Home screen banner or dedicated "My Trial" section

```
┌─────────────────────────────────────────┐
│  🤝 TRIAL IN PROGRESS                   │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────────┐│
│  │         ⏱ Time Remaining            ││
│  │                                     ││
│  │         5d 14h 22m                  ││
│  │                                     ││
│  │  Day 2 of 7 · Ends May 27           ││
│  │  ████████░░░░░░░░░░░░░░░░           ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  👨‍👩‍👧‍👦 Family                          ││
│  │                                     ││
│  │  ┌────┐  Al Mansoori Family         ││
│  │  │ F  │  Dubai Marina               ││
│  │  └────┘                             ││
│  │                                     ││
│  │  📞 Contact (revealed during trial) ││
│  │  ┌─────────────────────────────┐    ││
│  │  │ +971 50 123 4567            │    ││
│  │  │ [ 📞 Call ] [ 💬 WhatsApp ] │    ││
│  │  └─────────────────────────────┘    ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  💰 Trial Payment                   ││
│  │                                     ││
│  │  Daily rate:   AED 150              ││
│  │  Duration:     7 days               ││
│  │  Total agreed: AED 1,050            ││
│  │                                     ││
│  │  ⚠️ Payment is handled directly     ││
│  │  between you and the family.        ││
│  │  Kafi does not process payments.    ││
│  │  Discuss payment terms with family. ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  📍 Trial Location                  ││
│  │  Dubai Marina, Building Name        ││
│  │  [ Open in Maps ]                   ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  📋 Trial Tasks                     ││
│  │                                     ││
│  │  ☐ Childcare for 2 children         ││
│  │  ☐ Prepare children's meals         ││
│  │  ☐ Bath time routine                ││
│  │  ☐ Light laundry                    ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  💬 Chat with Family                ││
│  │  [ Open Chat ]                      ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  ⚠️ Having issues during trial?     ││
│  │  [ Report Problem to Kafi ]         ││
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

---

#### 32D: Trial Completion (Nanny View)

**Triggered:** When trial period ends

```
┌─────────────────────────────────────────┐
│                                         │
│           🎉                            │
│    Trial Complete!                      │
│                                         │
│    Your 7-day trial with                │
│    Al Mansoori Family has ended.        │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  💰 Payment Due                     ││
│  │                                     ││
│  │  Total: AED 1,050                   ││
│  │  (7 days × AED 150/day)             ││
│  │                                     ││
│  │  The family should pay you          ││
│  │  directly. If not received,         ││
│  │  contact Kafi support.              ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  What happens next?                 ││
│  │                                     ││
│  │  The family will decide whether     ││
│  │  to offer you permanent employment. ││
│  │  You'll be notified of their        ││
│  │  decision.                          ││
│  └─────────────────────────────────────┘│
│                                         │
│  [ Confirm Payment Received ]           │
│  (green button)                         │
│                                         │
│  [ Report Payment Issue ]               │
│  (text link)                            │
│                                         │
└─────────────────────────────────────────┘
```

---

#### 32E: Hired Confirmation (Nanny View)

```
┌─────────────────────────────────────────┐
│                                         │
│           🎊                            │
│    Congratulations!                     │
│    You're Hired!                        │
│                                         │
│    Al Mansoori Family has offered       │
│    you permanent employment!            │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  📋 Employment Details              ││
│  │                                     ││
│  │  Position: Live-in Nanny            ││
│  │  Salary: AED 2,800/month            ││
│  │  Start: Immediately                 ││
│  │  Visa: Sponsorship provided         ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  ⚠️ Next steps:                     ││
│  │                                     ││
│  │  1. Discuss final terms with family ││
│  │  2. Complete visa paperwork         ││
│  │  3. Sign employment contract        ││
│  │                                     ││
│  │  Kafi is not involved in the        ││
│  │  employment contract between you    ││
│  │  and the family.                    ││
│  └─────────────────────────────────────┘│
│                                         │
│  [ Message Family ]                     │
│                                         │
│  [ Update Profile Status ]              │
│  (Mark as "Currently Employed")         │
│                                         │
└─────────────────────────────────────────┘
```

---

### Screen 38: Subscription Expired Paywall (Family)

**Purpose:** Full-screen lock shown when a family with an expired subscription tries to access locked features (chat, contacts, CV, trial offers).

**Triggered By:**
- Tapping a chat thread (when status = EXPIRED / PAYMENT_FAILED)
- Tapping Call/WhatsApp button on a nanny profile
- Tapping CV download
- Tapping "Send Trial Offer"
- Tapping full profile view
- Opening app after subscription expiry (banner)
- Tapping push notification "Subscription expired"

**UI:**
```
┌─────────────────────────────────────────┐
│            🔒                            │
│                                         │
│   Your subscription has expired          │
│                                         │
│   Renew to access:                       │
│   ✓ All your chats and messages          │
│   ✓ Nanny contact numbers                │
│   ✓ Full profile views                   │
│   ✓ Trial offers                         │
│   ✓ CV downloads                         │
│                                         │
│   Your data is saved - chats, shortlist, │
│   and history are preserved.             │
│                                         │
│   ┌──────────────────────────────────┐  │
│   │   Renew Subscription              │  │
│   └──────────────────────────────────┘  │
│                                         │
│   View All Plans                         │
│                                         │
└─────────────────────────────────────────┘
```

**Behavior:**
- Tapping "Renew Subscription" → Plans screen → RevenueCat payment sheet
- On success → Status updates to ACTIVE, paywall closes, original target screen unlocks
- Closing without renewal → Returns to home / previous screen

---

## SUBSCRIPTION LIFECYCLE FLOW

```
[Family Subscribes - First Time]
         ↓
   Status: ACTIVE
   • Full chat access
   • Phone numbers visible
   • All features unlocked
         ↓
[Auto-Renewal Day]
   ├──→ Success → ACTIVE (extends end date)
   ├──→ Cancelled (still in period) → CANCELLED-IN-PERIOD
   │     (full access until endDate)
   └──→ Payment fails → PAYMENT_FAILED → [LOCKDOWN]
         ↓
[endDate Reached without Renewal]
   Status: EXPIRED → [LOCKDOWN]
         ↓
   ┌─────────────────────────────────┐
   │  LOCKDOWN MODE ACTIVATED        │
   │                                 │
   │  ❌ Chat list hidden             │
   │  ❌ Chat threads locked          │
   │  ❌ Nanny phones blurred         │
   │  ❌ CV downloads disabled        │
   │  ❌ Trial offers disabled        │
   │  ❌ Full profile views blocked   │
   │  ❌ Call/WhatsApp removed        │
   │                                 │
   │  ✅ Browse cards visible         │
   │  ✅ Intro videos play            │
   │  ✅ Match scores show            │
   │  ✅ Data preserved               │
   │                                 │
   │  EXCEPTION:                     │
   │  Active trials keep all access  │
   │  until trial ends               │
   └─────────────────────────────────┘
         ↓
   ⚡ Push: "Subscription expired"
   ⚡ Push (Day 3): "Your matches are waiting"
   ⚡ Push (Day 7): "Renew anytime"
         ↓
[User Renews]
   Status: EXPIRED → ACTIVE
         ↓
   ┌─────────────────────────────────┐
   │  ACCESS RESTORED                │
   │                                 │
   │  ✅ Chats reappear instantly     │
   │  ✅ Phone numbers unlock         │
   │  ✅ All features enabled         │
   │  ✅ Original target screen opens │
   │                                 │
   │  ⚡ Push: "Welcome back!"        │
   └─────────────────────────────────┘
```

---

## MISSING SCREENS (Updated)

### Medium Priority

11. **Search/Filter Screen**
    - Advanced filters for nannies
    - Save search preferences
    - Recent searches

12. **Reviews/Ratings System**
    - Leave review after trial/hire
    - View reviews on profiles
    - Rating breakdown

13. **Help/Support Screen**
    - FAQs
    - Contact support
    - Report issue
    - Report user

14. **Onboarding Screens**
    - Feature highlights
    - How it works walkthrough
    - Permission requests

15. **Family Job Edit Screen**
    - Edit existing job post
    - Pause/close job
    - Renew job post

16. **Payment History**
    - Past transactions
    - Receipts
    - Failed payments

17. **Trial Payment Flow**
    - How trial payment works
    - Payment after trial completion
    - Dispute resolution

18. **Nanny Availability Calendar**
    - Set available dates
    - Block dates
    - Show availability to families

### Low Priority (Nice to Have)

19. **Referral Program Screen**
    - Invite friends
    - Track referrals
    - Earn credits

20. **Video Call Feature**
    - Schedule video interview
    - In-app video call

21. **Document Expiry Alerts**
    - Visa expiry reminders
    - EID renewal alerts

22. **Multi-language Support**
    - Arabic version
    - Tagalog version
    - Hindi version

23. **App Store Screenshots/Marketing**
    - Feature graphics
    - Store listing content

### Admin Panel Missing

24. **User Detail View**
    - Full user profile in admin
    - Edit user data
    - Add notes

25. **Document Viewer**
    - Full-screen document view
    - Zoom/rotate
    - Rejection reason input

26. **Video Review Screen**
    - Play video in admin
    - Approve/reject with reason
    - Flag inappropriate content

27. **Revenue Reports**
    - Date range filter
    - Export to CSV/PDF
    - VAT report for FTA

28. **Broadcast Composer**
    - Select audience
    - Create message
    - Schedule send
    - Track delivery

29. **User Reports/Complaints**
    - View reported users
    - Take action
    - Communication log

30. **System Settings**
    - Pricing configuration
    - Commission settings
    - Feature toggles

---

## BUSINESS DECISIONS & TECHNICAL SPECIFICATIONS

### Payment & Financial

| Decision | Answer |
|----------|--------|
| **Trial Payment** | Direct between family and nanny. App only facilitates finding nannies (shown as trial user or normal user). No in-app payment for trials. |
| **Nanny Commission** | No commission taken by Kafi. Any commission handling done manually by owner. |
| **Subscription System** | RevenueCat integration with App Store Connect & Google Play Store |
| **Auto-renewal** | Yes, subscriptions auto-renew via RevenueCat |
| **Refund Policy** | Standard App Store / Play Store refund policies apply |
| **Payment Gateway** | None - App Store/Play Store subscriptions only |
| **Post-Expiration Access** | Contacts hidden, chat inaccessible. Data preserved. Re-subscription instantly restores all access. Active trials are the only exception. |

### Business Rules

| Decision | Answer |
|----------|--------|
| **Free Contact Usage** | Profile view counts as using 1 free contact (5 total) |
| **Multiple Roles** | No - one phone number = one account type only (nanny OR family) |
| **Profile Deactivation** | Not available - nannies cannot hide profile |
| **Visa Sponsorship Enforcement** | No enforcement - honor-based commitment |
| **Reference Verification** | Honor-based only - no admin verification |
| **Job Post Visibility** | 7 days default (dynamic, managed from database) |
| **Rehiring Process** | Same as new hire - family must view profile again (counts as contact if subscription expired) |

### Match Algorithm

**Factors (with suggested weights):**

| Factor | Weight | Logic |
|--------|--------|-------|
| **Location Match** | 25% | Nanny's preferred emirates vs family's emirate |
| **Language Match** | 20% | Required languages overlap |
| **Experience Match** | 15% | Years of experience vs requirement |
| **Job Type Match** | 15% | Live-in/Live-out preference alignment |
| **Skills Match** | 10% | Required skills (newborn, cooking, etc.) |
| **Salary Match** | 10% | Nanny expectation vs family budget |
| **Availability** | 5% | Immediate vs specific date |

**Match Score Calculation:**
```
Total Score = Σ (Factor Score × Weight)

Factor Score:
- Full match = 100%
- Partial match = 50%
- No match = 0%

Display:
- 80-100%: Green badge "Great Match"
- 60-79%: Orange badge "Good Match"  
- Below 60%: Red badge "Low Match"
```

### Push Notifications

**Events that trigger push notifications:**

| Category | Events |
|----------|--------|
| **Messages** | New message received, Message read (optional) |
| **Applications** | New application (family), Application viewed (nanny), Application declined |
| **Trials** | Trial offer received, Trial offer accepted/declined, Trial counter-offer, Trial starting soon (1 day before), Trial ending soon (2 days before), Trial completed |
| **Hiring** | Hired confirmation |
| **Profile** | Profile viewed (nanny), Documents approved, Documents rejected, Profile verified |
| **Subscription** | Subscription expiring (3 days before), Subscription renewed, Subscription expired, Free contacts running low (1 left) |
| **System** | New feature announcements, Important updates |

### Technical Stack

| Component | Technology |
|-----------|------------|
| **Authentication** | Firebase Auth (Phone Number only) |
| **Database** | Firebase Firestore |
| **File Storage** | Firebase Storage (documents, photos, videos) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **Subscriptions** | RevenueCat (App Store + Play Store) |
| **Analytics** | Firebase Analytics (events as per admin panel metrics) |
| **Offline Mode** | Not supported |

### Document Storage

| Document Type | Storage |
|---------------|---------|
| Passport | Firebase Storage (standard) |
| Visa | Firebase Storage (standard) |
| Emirates ID | Firebase Storage (standard) |
| Photos | Firebase Storage (standard) |
| Videos | Firebase Storage (standard, max 60 sec) |
| Training Certificates | Firebase Storage (standard) |

**Note:** Documents stored in Firebase Storage without additional encryption. Access controlled via Firebase Security Rules.

### Analytics Events (Admin Panel Metrics)

| Metric | Event to Track |
|--------|----------------|
| Total Users | `user_registered` |
| Active Subscriptions | `subscription_started`, `subscription_renewed`, `subscription_cancelled` |
| Revenue | RevenueCat dashboard (linked) |
| Nanny Signups | `nanny_profile_created` |
| Family Signups | `family_profile_created` |
| Document Submissions | `document_uploaded` |
| Video Submissions | `video_uploaded` |
| Profile Views | `profile_viewed` |
| Applications | `application_sent` |
| Trial Offers | `trial_offer_sent`, `trial_accepted`, `trial_declined` |
| Hires | `nanny_hired` |
| Messages | `message_sent` |

---

## SUMMARY

### App Overview
The Kafi app is a **marketplace-only platform** connecting nannies with families in the UAE. Key principles:

- **Kafi facilitates finding, not employment** - All payments, contracts, and visa matters are between family and nanny directly
- **Free for nannies** - 100% free forever, no commission
- **Subscription for families** - Via App Store / Play Store (RevenueCat)
- **5 free profile views** for families before subscription required

### User Flows

**Nanny Flow:**
```
Register (Firebase Auth) → Create Profile → Upload Documents → 
Admin Review → Approved → Browse Jobs → Apply → Chat → 
Accept Trial Offer → Complete Trial → Get Hired
```

**Family Flow:**
```
Register (Firebase Auth) → Post Job Requirements → Browse Nannies → 
View Profiles (5 free) → Subscribe (if needed) → Contact Nanny → 
Chat → Send Trial Offer → Evaluate Trial → Hire
```

### Technical Stack Summary
| Component | Technology |
|-----------|------------|
| Auth | Firebase Auth (Phone) |
| Database | Firebase Firestore |
| Storage | Firebase Storage |
| Push | Firebase Cloud Messaging |
| Subscriptions | RevenueCat |
| Analytics | Firebase Analytics |

### Screen Count
- **Original screens (from HTML):** 23
- **Additional screens (detailed):** 9
- **Total documented screens:** 32
- **Remaining medium/low priority:** 21

### Key Business Decisions
- No in-app payments for trials/salaries
- No visa enforcement
- No profile hiding feature
- One phone = one account type
- 7-day default job visibility (dynamic from DB)
- Match algorithm based on location, language, experience, job type, skills, salary

---

## Implementation History

| Date (YYYY-MM-DD) | Task | Status | Summary |
|-------------------|------|--------|---------|
| 2026-05-19 | Phase 0 scaffold | Done | Welcome + role-select mock auth (OTP 1234), nanny/family placeholder homes, Kafi theme tokens; admin panel routes per Screen 23 |
| 2026-05-19 | Auth UI foundation v8 | Done | HTML-matched welcome/login/OTP/create-pw screens; widget kit; GetX auth flow; mock OTP 1234 |
| 2026-05-19 | Restart Task 1 — auth flow | Done | Screens 1–5 rebuilt vs HTML; l10n keys; mock auth; placeholders for post-auth routes |
| 2026-05-19 | Task 2 — Nanny onboarding | Done | Screens 6–12 wired: info, media, exp, refs, docs, pending, dashboard; HTML structure + l10n; mock + Firebase backed |
| 2026-05-19 | Task 3 — Family flow | Done | Screens 13–22 wired: family-form, browse, profile locked/unlocked, chat (with expired-state lockdown + active-trial exception), smart match, trial, pricing, terms, privacy |
| 2026-05-19 | Task 4 — Admin + Functions | Done | React admin panel (11 pages: login, dashboard, nannies, docs verify, videos review, families, subscriptions, revenue, broadcast, settings); Cloud Functions (chat/trial/nanny triggers, scheduled jobs, RevenueCat webhook) |
| 2026-05-19 | Audit & Compliance Pass | Done | Added missing controllers (Notification, Application, Shortlist, Settings, Permission, JobPost); models (Application, Notification, Shortlist, Review); subscription lockdown logic per §3.8; nanny screens (Jobs Home, Job Detail, My Applications); family screens (Shortlist, Settings, Notifications, Trial Offer) |
| 2026-05-19 | Error Handling & Delete Account | Done | Implemented Screen 29B Delete Account flow with 2-step confirmation (reason selection + type DELETE); error handling UX with snackbars; l10n strings added |
| 2026-05-19 | Trial Offer Flow Completion | Done | Completed Screen 31/32 wiring: family send trial offer creates trial + chat offer bubble, links thread trialId for lockdown exception, and enables nanny accept/decline/counter responses with chat status messages |
| 2026-05-19 | Audit gap closure (end-to-end) | Done | Pricing screen now itemises base + 5% VAT + total per plan; locked profile shows trial-bypass banner when active trial exists; pending screen pulses + "Usually 1–24h" copy; trial screen exposes cancel + nanny payment-confirm + payment-issue actions; smart-match replaced hardcoded score with real 5-criteria scorer (`utils/smart_match.dart`); session monitor adds 90-day inactivity auto-logout |
| 2026-05-19 | Reaudit fix-pass (12 areas) | Done | (1) Critical bugs: `paymentFailed` enum aligned across webhook/Flutter/admin; grace period keeps access; per-key settings updates use dot-notation merge; duplicate `UserSettings` removed; thread `trialStatus` cached so trial bypass only triggers on ACTIVE trials; accept-trial now auto-promotes to active when start date reached; recordView dedupes by viewed nannyId. (2) Auth: OTP screen exposes tappable resend & change-number; create-password reached for new signups; locale toggle wired in settings. (3) Family: new Screen 16A Profile Re-Locked with `ImageFilter` blur; browse routes previously-viewed nannies to relocked when expired. (4) Chat/Trial: image + system bubbles render; family-side accept/decline of nanny counter offer added. (5) Nanny: Screen 27A Edit Profile (bio, languages, emergency, comfort) added; job detail uses real `MatchService` factors. (6) Admin/Functions: `onTrialEnded` recomputes `activeTrialNannyIds`; broadcast FCM dispatcher; user cascade-delete; `PRODUCT_CHANGE` event handled in RevenueCat webhook + shared-secret auth; admin seed script under `scripts/`. (7) Cross-cutting: settings exposes job-match/profile-view/marketing/email + language picker; Arabic locale extended with key UI strings; `useMock` env-driven in admin panel. |
| 2026-05-19 | Permissions, handlers & location picker | Done | (1) `PermissionService` implemented with real `permission_handler` calls (camera, photos, mic, location, notification, contacts); `openSettings()` uses `openAppSettings()`. (2) All media/upload entry points gated: `uploadPhoto`, `uploadVideo`, `uploadDocument` in `NannyProfileController`; `sendImage` in `ChatController`. (3) OTP verify button disabled + controller guard when timer expired (`otpSecondsLeft <= 0`); `otpExpiredMessage` string key added. (4) Duplicate trial offer blocked: `sendTrialOffer` checks `all` list for existing `pending/countered/accepted/active` trial for same nanny. (5) `markAsRead` wired from `openThread`; `IChatService.markThreadRead` added + implemented in both mock and Firestore services. (6) `calculateProfileScore()` called after `saveProfileDraft`; success snackbar shown. (7) Browse free-view feedback: snackbar shown on 0 views left before redirecting to pricing; "X free views remaining" hint shown at 1–2 left. (8) `KafiLocationPicker` widget created (UAE emirate + area two-column bottom sheet); wired into nanny current-area field (`nanny_info_screen`), trial offer location field (`trial_offer_screen`), and new family city field (`family_form_screen`). |
| 2026-05-19 | Audit round 2 fixes | Done | Counter-offer family Accept/Decline in chat bubble; lockdown keeps trial chats; contacts hidden when expired; thread bypass for accepted+active; transactional free-view dedupe; password-reset OTP verified via Firebase credential; trial deep-link by trialId; viewedProfiles hydrate on login; free-tier chat gated; compare uses browse API; trial pass/fail outcomes; apply blocked during active trial; disabled chat composer when expired. |
| 2026-05-19 | Broken flows + bug bash | Done | (1) Trial response chat: `_postTrialResponseMessage` now looks up threads by the **current user id** (was using nanny CARD id `n1`). (2) Trial bubble: now `Obx`-reactive on `TrialController.all`; Accept/Counter buttons only render when status == `pending`; rendered counter-offer rate + status chip (Accepted/Active/Declined/Counter sent/Completed/Cancelled). (3) Family acceptCounter: `ITrialService.applyCounterAndAccept` added so counter `dailyRate` + `startDate` overwrite the trial baseline. (4) Browse: removed full-screen "Renew" overlay when expired — list stays visible with a slim banner; expired families opening a previously-viewed nanny route to **Profile Re-Locked**, otherwise Profile Locked. (5) Chat list: removed the "X trial chats" partial banner; expired families see all threads with a tap-to-renew banner, paywall still enforced inside `openThread`. (6) Password reset OTP no longer hardcoded to `1234` — `IAuthService.verifyPasswordResetOtp` added + screen calls it. (7) Returning users keep their `hasPassword` flag through OTP — Firebase + mock auth preserve the value. (8) OTP send failure no longer navigates to verify screen. (9) Login screens (`LoginNannyScreen`, `LoginFamilyScreen`) call `prepare*Login` on initState. (10) Nanny onboarding now validates required fields per step + wraps each save in try/catch with snackbar; `submitForReview` enforces required docs. (11) Shortlist tap routes via `AppNavigation.openNannyProfile` so subscription/relocked rules apply. (12) Chat opens by thread id or nanny id from arguments / notification deep-link; new `ChatController.openThreadForNanny`. (13) Family shell shows grace banner on non-browse tabs. (14) FCM: foreground `onMessage`, `onMessageOpenedApp`, `getInitialMessage`, and `onTokenRefresh` handlers added; token re-registered on every user change. (15) SessionMonitor clears `AuthController.currentUser` on auth-state expiry. (16) `AppNotification.fromMap` tolerates Firestore Timestamps, ISO strings, ints, and missing fields. (17) New Screen 27B **Edit Family Profile** added; family settings exposes "Edit family profile" entry. (18) Nanny edit profile pre-fills every field (DOB, nationality, languages, visa, emirates, marital, children, health, preferences, religion, emergency contact, bio). |
| 2026-05-19 | P2 audit fixes | Done | Dashboard all-nannies/families/trials tables now use live `NannyService`/`FamilyService`/`TrialService` data (replaced hardcoded rows); nationality + city breakdown derived from loaded arrays. `NannyRow.introVideoStatus` field added; `NannyService.reviewVideo()` patches only the video status (not full profile approve/reject); `ReviewVideos.tsx` calls `reviewVideo` instead of `approve`. `IDisputeService` interface + mock + Firestore implementations created; `TrialController.reportPaymentIssue` now writes a `disputes` collection document with category `payment` alongside the trial flag. Storage cleanup on user delete: `onUserDeleted` Cloud Function now deletes all Storage files under `users/{uid}/`, `nannies/{uid}/`, `families/{uid}/` via `_deleteStorageFolder`. `firestore.indexes.json` extended with all missing composite indexes: applications by jobPostId, chatThreads by familyId+nannyId, notifications by userId+read, disputes by reporterId, shortlists by familyId+nannyId, jobs by status+city, subscriptions by status+endDate, trials by status+startDate and reminderSent, nannies by status+introVideoStatus. |

