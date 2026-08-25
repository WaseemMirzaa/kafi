# KAFI - Complete System Specification
## UAE Nanny/Domestic Helper Marketplace

---

# TABLE OF CONTENTS

1. [System Overview](#1-system-overview)
2. [Technical Stack](#2-technical-stack)
3. [Data Models](#3-data-models)
4. [User Roles & Permissions](#4-user-roles--permissions)
5. [Complete Screen List](#5-complete-screen-list)
6. [Functional Flows](#6-functional-flows)
7. [Push Notifications](#7-push-notifications)
8. [Payment & Subscription Handling](#8-payment--subscription-handling)
9. [Match Algorithm](#9-match-algorithm)
10. [Trial System](#10-trial-system)
11. [Free Tier Restrictions](#11-free-tier-restrictions)
12. [Admin Functions](#12-admin-functions)
13. [Security & Privacy](#13-security--privacy)

---

# 1. SYSTEM OVERVIEW

## 1.1 Platform Description
Kafi is a mobile-first marketplace connecting domestic helpers (nannies) with families in the UAE.

## 1.2 Business Model
| User Type | Cost | Revenue Source |
|-----------|------|----------------|
| Nanny | 100% Free Forever | None |
| Family | Subscription-based | App Store / Play Store subscriptions |

## 1.3 Key Principles
- **Marketplace only** - Kafi does NOT employ, sponsor, or act as agency
- **Direct payments** - All trial/salary payments are between family and nanny
- **Subscription revenue only** - Via RevenueCat (Apple/Google)
- **No commission** - Kafi takes no cut from nanny earnings

## 1.4 Target Market
- UAE (Dubai, Abu Dhabi, Sharjah, Ajman, RAK, Fujairah, UAQ, Al Ain)

## 1.5 Supported Country Codes (Phone Authentication)

### Nanny-Origin Countries
| Country | Code |
|---------|------|
| UAE | +971 |
| Philippines | +63 |
| India | +91 |
| Sri Lanka | +94 |
| Nepal | +977 |
| Indonesia | +62 |
| Ethiopia | +251 |
| Kenya | +254 |
| Ghana | +233 |
| Nigeria | +234 |
| Pakistan | +92 |
| Bangladesh | +880 |
| Uganda | +256 |

### Family Countries (Extended)
| Region | Countries |
|--------|-----------|
| Gulf | UAE, Saudi Arabia, Kuwait, Qatar, Bahrain, Oman |
| Arab | Egypt, Lebanon, Jordan, Syria, Iraq, Palestine, Yemen, Morocco, Algeria, Tunisia, Libya, Sudan |
| Europe | UK, Ireland, France, Germany, Italy, Spain, Portugal, Netherlands, Belgium, Switzerland, Austria, Sweden, Norway, Denmark, Finland, Greece, Romania, Poland, Bulgaria, Russia, Ukraine |
| Americas | USA, Canada, Mexico, Brazil, Argentina, Colombia |
| Asia | India, Pakistan, China, Japan, Korea, Singapore, Malaysia, Thailand |
| Africa | South Africa, Kenya, Nigeria, Ethiopia, Ghana |
| Oceania | Australia, New Zealand |

---

# 2. TECHNICAL STACK

| Component | Technology | Purpose |
|-----------|------------|---------|
| Authentication | Firebase Auth (Phone Number) | User login/signup |
| Database | Firebase Firestore | All app data |
| File Storage | Firebase Storage | Documents, photos, videos |
| Push Notifications | Firebase Cloud Messaging (FCM) | Real-time alerts |
| Subscriptions | RevenueCat | Payment processing |
| Analytics | Firebase Analytics | Usage tracking |
| Offline Mode | Not Supported | - |

---

# 3. DATA MODELS

## 3.1 User Model (Base)

```typescript
interface User {
  id: string;                    // Firebase UID
  phone: string;                 // +971XXXXXXXXX
  userType: 'nanny' | 'family';
  email?: string;
  password: string;              // Hashed
  createdAt: Timestamp;
  updatedAt: Timestamp;
  lastLoginAt: Timestamp;
  fcmTokens: string[];           // Push notification tokens
  settings: UserSettings;
}

interface UserSettings {
  pushNotifications: boolean;
  messageNotifications: boolean;
  jobMatchNotifications: boolean;
  trialNotifications: boolean;
  profileViewNotifications: boolean;  // Nanny only
  marketingNotifications: boolean;
  emailNotifications: boolean;
  showOnlineStatus: boolean;
  language: 'en' | 'ar';
}
```

## 3.2 Nanny Model

```typescript
interface Nanny extends User {
  // Basic Info
  fullName: string;
  dateOfBirth: Date;
  age: number;                   // Auto-calculated
  nationality: string;
  languages: string[];           
  // Available: 'English', 'Arabic', 'Hindi', 'Tagalog', 'Urdu', 
  // 'French', 'Swahili', 'Amharic', 'Indonesian', 'Russian'
  profilePhoto: string;          // URL
  photos: string[];              // Max 5 URLs
  introVideo?: string;           // URL, max 60 seconds
  bio: string;                   // Max 300 chars
  
  // Visa & Legal
  visaStatus: VisaStatus;
  hasEID: boolean;
  eidNumber?: string;
  visaTransferWilling: 'yes' | 'no' | 'depends';
  
  // Work Preferences
  preferredEmirates: string[];
  willingToRelocate: boolean;
  currentArea?: string;
  jobTypePreference: 'live-in' | 'live-out' | 'both';
  expectedSalaryMin: number;
  expectedSalaryMax: number;
  availability: AvailabilityStatus;
  availableFrom?: Date;
  
  // Personal Status
  maritalStatus: 'single' | 'married' | 'divorced' | 'widowed';
  hasChildren: boolean;
  numberOfChildren?: number;
  childrenAges?: string;
  
  // Health
  hasHealthConditions: boolean;
  healthConditionDetails?: string;
  takesMedication: boolean;
  medicationDetails?: string;
  hasAllergies: boolean;
  allergyDetails?: string;
  
  // Preferences
  comfortableWithCameras: boolean;
  cameraNote?: string;
  comfortableWithPets: boolean;
  petTypes?: string[];
  canCook: boolean;
  cuisines?: string[];
  canDoNightShifts: boolean;
  
  // Religion (Optional)
  religion?: string;
  religiousPracticesNote?: string;
  comfortableWithDifferentFaith: boolean;
  
  // Emergency Contact
  emergencyContact: EmergencyContact;
  
  // Experience
  experiences: WorkExperience[];
  
  // References
  hasReferences: boolean;
  numberOfReferences?: number;
  references: Reference[];
  
  // Documents
  documents: NannyDocuments;
  
  // Verification Status
  verificationStatus: VerificationStatus;
  isVerified: boolean;
  verifiedAt?: Timestamp;
  
  // Profile Quality
  profileScore: number;          // 0-100
  
  // Stats
  stats: NannyStats;
}

enum VisaStatus {
  VISIT_VISA = 'visit_visa',
  RESIDENCE_VISA = 'residence_visa',
  OWN_VISA = 'own_visa',
  CANCELLED = 'cancelled',
  OUTSIDE_UAE = 'outside_uae'
}

enum AvailabilityStatus {
  AVAILABLE_NOW = 'available_now',
  AVAILABLE_FROM = 'available_from',
  ON_TRIAL = 'on_trial'
}

interface EmergencyContact {
  name: string;
  relationship: string;
  phone: string;
}

interface WorkExperience {
  id: string;
  jobTitle: string;              // Options: 'Live-in Nanny', 'Live-out Nanny', 
                                 // 'Babysitter', 'Newborn Specialist', 
                                 // 'Housekeeper & Nanny'
  employerName: string;
  city: string;
  country: string;
  fromDate: Date;
  toDate: Date;                  // Or 'Current job'
  childrenCaredFor: string;      // e.g., "2 kids, ages 1 & 4"
  duties: string;
  reasonForLeaving: string;      // Options: 'Family relocated abroad', 
                                 // 'Contract ended', 'Children grew up'
}

interface Reference {
  id: string;
  relationship: string;
  city: string;
  yearsWorked: number;
  canConfirm: string;
}

interface NannyDocuments {
  passport: DocumentFile;
  visa: DocumentFile;
  eid?: DocumentFile;
  trainingCertificates?: DocumentFile[];
  policeClearance?: DocumentFile;
}

interface DocumentFile {
  url: string;
  uploadedAt: Timestamp;
  status: 'pending' | 'approved' | 'rejected';
  rejectionReason?: string;
  reviewedAt?: Timestamp;
  reviewedBy?: string;
}

enum VerificationStatus {
  PENDING = 'pending',
  UNDER_REVIEW = 'under_review',
  APPROVED = 'approved',
  REJECTED = 'rejected'
}

interface NannyStats {
  profileViews: number;
  shortlists: number;
  applicationsCount: number;
  trialsCount: number;
  hiresCount: number;
  averageRating?: number;
  reviewsCount: number;
}

interface ProfileQualityScore {
  totalScore: number;              // 0-100
  factors: {
    profileComplete: boolean;      // +20 points
    isVerified: boolean;           // +20 points
    hasVideo: boolean;             // +15 points
    hasMultiplePhotos: boolean;    // +10 points
    hasPoliceClearance: boolean;   // +10 points
    hasTrainingCert: boolean;      // +7 points
    recentlyActive: boolean;       // +5 points (login within 7 days)
    hasReferences: boolean;        // +8 points
    hasWorkExperience: boolean;    // +5 points
  };
  recommendations: string[];       // ["Add police clearance → +10pts", etc.]
}
```

## 3.3 Family Model

```typescript
interface Family extends User {
  // Family Info
  fullName: string;
  nationality: string;
  city: string;                  // Emirate
  languagesAtHome: string[];
  hasCameras: boolean;
  hasPets: boolean;
  petTypes?: string[];
  profilePhoto?: string;
  
  // Children
  numberOfChildren: number;
  childrenAges: string[];
  hasSpecialNeedsChild: boolean;
  specialNeedsDetails?: string;
  
  // Religion
  religion?: string;
  nannyReligionPreference: NannyReligionPreference;
  houseRules?: string;
  
  // Subscription
  subscription: FamilySubscription;
  
  // Free Tier Usage
  freeContactsUsed: number;      // Max 5
  viewedProfiles: string[];      // Nanny IDs
  
  // Stats
  stats: FamilyStats;
}

enum NannyReligionPreference {
  NO_PREFERENCE = 'no_preference',
  PREFER_MUSLIM = 'prefer_muslim',
  PREFER_SAME = 'prefer_same',
  OPEN_WITH_RESPECT = 'open_with_respect'
}

interface FamilySubscription {
  status: SubscriptionStatus;
  plan?: 'weekly' | 'monthly' | 'bimonthly';
  startDate?: Timestamp;
  endDate?: Timestamp;
  autoRenew: boolean;
  revenueCatId?: string;
  
  // History
  hasEverSubscribed: boolean;
  expiredAt?: Timestamp;          // Set when status becomes 'expired'
  lastRenewalAt?: Timestamp;
  
  // Lockdown flags (derived)
  // contactsHidden: true when status in [expired, cancelled-past-end]
  // chatLocked: true when status in [expired, cancelled-past-end]
}

enum SubscriptionStatus {
  FREE = 'free',                  // Never subscribed
  ACTIVE = 'active',              // Paid + within end date
  CANCELLED_ACTIVE = 'cancelled', // Cancelled but still within end date - full access
  EXPIRED = 'expired',            // Past end date - LOCKDOWN
  PAYMENT_FAILED = 'payment_failed' // Renewal failed - LOCKDOWN
}

interface FamilyStats {
  jobPostsCount: number;
  activeJobPosts: number;
  totalApplicationsReceived: number;
  trialsCount: number;
  hiresCount: number;
}
```

## 3.4 Job Post Model

```typescript
interface JobPost {
  id: string;
  familyId: string;
  status: 'active' | 'paused' | 'closed' | 'expired';
  createdAt: Timestamp;
  updatedAt: Timestamp;
  expiresAt: Timestamp;          // Default: 7 days from creation
  
  // Role
  jobTitle: string;
  rolesNeeded: string[];         
  // Available options:
  // - 'nanny'
  // - 'maid'
  // - 'caregiver'
  // - 'cook'
  // - 'babysitter'
  // - 'helper'
  // - 'pet_caretaker'
  jobType: 'live-in' | 'live-out';
  employmentType: 'fullTime' | 'partTime';  // max one active of each per family
  schedule: string;              // display label from selected weekdays (e.g. "Mon, Tue, Wed")
  workDays?: string[];           // Mon–Sun codes selected on the job form
  startDate: 'immediate' | Date;
  duration: 'permanent' | 'contract';
  contractMonths?: number;
  
  // Requirements
  experienceYears: number;
  languagesRequired: string[];
  languagesPreferred?: string[];
  skillsRequired: string[];
  nationalityPreference?: string[];
  religionPreference?: NannyReligionPreference;
  
  // Duties (checkboxes in UI)
  duties: string[];              
  // Available options:
  // - 'newborn'      (🍼)
  // - 'childcare'    (👶)
  // - 'cooking'      (🍳)
  // - 'light_cleaning' (🧹)
  // - 'laundry'      (👕)
  // - 'pet_care'     (🐾)
  // - 'driving'      (🚗)
  // - 'tutoring'     (📚)
  // - 'first_aid'    (🏥)
  
  // Compensation
  salaryMin: number;
  salaryMax: number;
  currency: 'AED';
  
  // Benefits (checkboxes in UI)
  benefits: string[];            
  // Available options:
  // - 'meals_provided'  (🍽️)
  // - 'private_room'    (🛏️)
  // - 'yearly_flight'   (✈️)
  // - 'health_insurance' (🏥)
  // - 'phone_provided'  (📱)
  // - 'days_off_weekly' (🗓️)
  
  // Visa
  visaSponsorshipType: VisaSponsorshipType;
  
  // Trial
  trialDuration: number;         // Days
  trialDailyRate: number;
  
  // Stats
  viewsCount: number;
  applicationsCount: number;
  
  // About
  additionalNotes?: string;
}

enum VisaSponsorshipType {
  FULL_SPONSORSHIP = 'full_sponsorship',
  SHARED_COSTS = 'shared_costs',
  EXISTING_VISA_ONLY = 'existing_visa_only',
  NO_SPONSORSHIP = 'no_sponsorship'
}
```

## 3.5 Application Model

```typescript
interface Application {
  id: string;
  jobPostId: string;
  nannyId: string;
  familyId: string;
  status: ApplicationStatus;
  matchScore: number;            // 0-100
  coverMessage?: string;
  createdAt: Timestamp;
  viewedAt?: Timestamp;
  respondedAt?: Timestamp;
  withdrawnAt?: Timestamp;
}

enum ApplicationStatus {
  PENDING = 'pending',
  VIEWED = 'viewed',
  SHORTLISTED = 'shortlisted',
  TRIAL_OFFERED = 'trial_offered',
  DECLINED = 'declined',
  WITHDRAWN = 'withdrawn',
  HIRED = 'hired'
}
```

## 3.6 Trial Model

```typescript
interface Trial {
  id: string;
  familyId: string;
  nannyId: string;
  jobPostId?: string;
  status: TrialStatus;
  
  // Offer Details
  durationDays: number;
  dailyRate: number;
  totalAmount: number;
  startDate: Date;
  startTime: string;
  endDate: Date;
  trialType: 'live-in' | 'live-out';
  location: string;
  notes?: string;
  
  // Timestamps
  offeredAt: Timestamp;
  respondedAt?: Timestamp;
  startedAt?: Timestamp;
  completedAt?: Timestamp;
  
  // Counter Offer (if any)
  counterOffer?: CounterOffer;
  
  // Evaluation (Family)
  evaluation?: TrialEvaluation;
  
  // Outcome
  outcome?: 'hired' | 'not_hired';
  outcomeAt?: Timestamp;
  
  // Payment Confirmation
  nannyConfirmedPayment: boolean;
  paymentIssueReported: boolean;
}

enum TrialStatus {
  PENDING = 'pending',
  COUNTERED = 'countered',
  ACCEPTED = 'accepted',
  DECLINED = 'declined',
  ACTIVE = 'active',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled'
}

interface CounterOffer {
  dailyRate: number;
  startDate: Date;
  message?: string;
  createdAt: Timestamp;
  status: 'pending' | 'accepted' | 'declined';
}

interface TrialEvaluation {
  childInteractionAndPatience: boolean;   // "Child interaction & patience"
  punctualityAndReliability: boolean;     // "Punctuality & reliability"
  followingInstructions: boolean;         // "Following instructions"
  communicationAndLanguage: boolean;      // "Communication & Arabic"
  cookingFamilyFood: boolean;             // "Cooking (family food)"
  honestyAndTrustworthiness: boolean;     // "Honesty & trustworthiness"
  additionalNotes?: string;
}
```

## 3.7 Chat & Message Models

```typescript
interface ChatThread {
  id: string;
  participants: {
    familyId: string;
    nannyId: string;
  };
  createdAt: Timestamp;
  lastMessageAt: Timestamp;
  lastMessage: string;
  unreadCount: {
    family: number;
    nanny: number;
  };
  trialId?: string;              // If trial active
  status: 'active' | 'archived';
}

interface Message {
  id: string;
  threadId: string;
  senderId: string;
  senderType: 'family' | 'nanny';
  type: MessageType;
  content: string;
  attachments?: Attachment[];
  trialOfferId?: string;         // If trial offer message
  createdAt: Timestamp;
  readAt?: Timestamp;
}

enum MessageType {
  TEXT = 'text',
  IMAGE = 'image',
  TRIAL_OFFER = 'trial_offer',           // Special bubble with Accept/Counter buttons
  TRIAL_ACCEPTED = 'trial_accepted',     // Green confirmation bubble
  TRIAL_DECLINED = 'trial_declined',
  TRIAL_COUNTERED = 'trial_countered',
  SYSTEM = 'system'                      // Chat opened, Trial started, etc.
}

// Trial Offer Bubble Content (displayed in chat for family AND nanny)
interface TrialOfferBubble {
  title: string;                         // "🤝 Trial Offer Sent/Received"
  duration: string;                      // "📅 Duration: 7 days paid trial"
  rate: string;                          // "💰 Rate: AED 150 per day"
  total: string;                         // "💵 Total: AED 1050"
  startFrom: string;                     // "🗓 Starting from: May 20, 2026"
  type: string;                          // "🏠 Live-in · Meals & room included"
  location: string;                      // "📍 Location: Dubai Marina"
  notes?: string;                        // "📝 Notes: …" (optional Additional Notes from Screen 31)
  actions: ['Accept', 'Counter', 'Decline'];  // Nanny pending; family sees Accept/Decline on counter
}

interface Attachment {
  type: 'image' | 'document';
  url: string;
  name: string;
}
```

## 3.8 Notification Model

```typescript
interface Notification {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  data: Record<string, any>;     // Deep link data
  read: boolean;
  createdAt: Timestamp;
  readAt?: Timestamp;
}

enum NotificationType {
  // Messages
  NEW_MESSAGE = 'new_message',
  
  // Applications
  NEW_APPLICATION = 'new_application',
  APPLICATION_VIEWED = 'application_viewed',
  APPLICATION_DECLINED = 'application_declined',
  
  // Trials
  TRIAL_OFFER_RECEIVED = 'trial_offer_received',
  TRIAL_ACCEPTED = 'trial_accepted',
  TRIAL_DECLINED = 'trial_declined',
  TRIAL_COUNTERED = 'trial_countered',
  TRIAL_STARTING_SOON = 'trial_starting_soon',
  TRIAL_ENDING_SOON = 'trial_ending_soon',
  TRIAL_COMPLETED = 'trial_completed',
  
  // Hiring
  HIRED = 'hired',
  
  // Profile
  PROFILE_VIEWED = 'profile_viewed',
  DOCUMENTS_APPROVED = 'documents_approved',
  DOCUMENTS_REJECTED = 'documents_rejected',
  PROFILE_VERIFIED = 'profile_verified',
  
  // Subscription
  SUBSCRIPTION_EXPIRING = 'subscription_expiring',
  SUBSCRIPTION_RENEWED = 'subscription_renewed',
  SUBSCRIPTION_EXPIRED = 'subscription_expired',
  FREE_CONTACTS_LOW = 'free_contacts_low',
  
  // System
  SYSTEM_ANNOUNCEMENT = 'system_announcement'
}
```

## 3.9 Shortlist Model

```typescript
interface Shortlist {
  id: string;
  familyId: string;
  nannyId: string;
  addedAt: Timestamp;
  notes?: string;
}
```

## 3.10 Review Model

```typescript
interface Review {
  id: string;
  reviewerId: string;
  reviewerType: 'family' | 'nanny';
  revieweeId: string;
  revieweeType: 'family' | 'nanny';
  trialId?: string;
  rating: number;                // 1-5
  comment?: string;
  createdAt: Timestamp;
  isPublic: boolean;
}
```

## 3.11 Admin Models

```typescript
interface AdminUser {
  id: string;
  email: string;
  name: string;
  role: 'owner' | 'admin' | 'moderator';
  permissions: AdminPermission[];
  createdAt: Timestamp;
  lastLoginAt: Timestamp;
}

enum AdminPermission {
  VIEW_USERS = 'view_users',
  EDIT_USERS = 'edit_users',
  VERIFY_DOCUMENTS = 'verify_documents',
  REVIEW_VIDEOS = 'review_videos',
  VIEW_REVENUE = 'view_revenue',
  SEND_BROADCASTS = 'send_broadcasts',
  MANAGE_SETTINGS = 'manage_settings'
}

interface Broadcast {
  id: string;
  title: string;
  body: string;
  targetAudience: 'all' | 'nannies' | 'families' | 'subscribers';
  sentBy: string;
  sentAt: Timestamp;
  deliveryStats: {
    sent: number;
    delivered: number;
    opened: number;
  };
}

interface SystemSettings {
  jobPostVisibilityDays: number; // Default: 7
  subscriptionPlans: SubscriptionPlan[];
  freeContactLimit: number;      // Default: 5
  matchAlgorithmWeights: MatchWeights;
  /** When true, family Browse/search hides nannies inactive for 14+ days (or missing lastActiveAt). */
  hideInactiveNannies: boolean;  // Default: false
}

interface SubscriptionPlan {
  id: string;
  name: string;
  durationDays: number;
  priceAED: number;
  revenueCatProductId: string;
}
```

---

# 4. USER ROLES & PERMISSIONS

## 4.1 Nanny (Free User)

| Feature | Access |
|---------|--------|
| Create profile | ✅ Full |
| Upload photos/video | ✅ Full (max 5 photos, 60s video) |
| Upload documents | ✅ Full |
| Browse job posts | ✅ Full |
| Apply to jobs | ✅ Full |
| Receive trial offers | ✅ Full |
| Accept/decline/counter trials | ✅ Full |
| In-app chat | ✅ Full |
| View family phone | ❌ Hidden (revealed only during active trial) |
| Call/WhatsApp family | ❌ During trial only |

## 4.2 Family (Free Tier - Never Subscribed)

| Feature | Access |
|---------|--------|
| Post job requirements | ✅ Full |
| Browse nanny profiles | ✅ Full (preview only) |
| View nanny profile (full) | ⚠️ Limited (5 free views) |
| Watch intro videos | ✅ Full |
| See match scores | ✅ Full |
| In-app chat | ⚠️ After viewing profile (uses 1 contact) |
| View nanny phone number | ❌ Locked |
| Download CV | ❌ Locked |
| Send trial offers | ❌ Locked |
| Call/WhatsApp nanny | ❌ Locked |

## 4.2A Family (Subscription Expired/Cancelled)

When a family's subscription ENDS (expired or fully cancelled past end date), the app reverts to **lockdown mode** — stricter than free tier:

| Feature | Access |
|---------|--------|
| Post job requirements | ✅ Full |
| Browse nanny profiles | ✅ Full (preview only) |
| View nanny profile (full) | ❌ LOCKED (no new full views) |
| View previously-viewed profiles | ❌ LOCKED (also hidden) |
| Watch intro videos | ✅ Full |
| See match scores | ✅ Full |
| In-app chat — read history | ❌ LOCKED (chat hidden) |
| In-app chat — send new messages | ❌ LOCKED |
| View nanny phone number | ❌ LOCKED (hidden again) |
| Download CV | ❌ LOCKED |
| Send trial offers | ❌ LOCKED |
| Call/WhatsApp nanny | ❌ LOCKED |
| Receive notifications | ✅ (sub-renewal CTA) |

**Key behaviors:**
- Existing chats are NOT deleted - they become **inaccessible** (hidden behind subscription wall)
- Nanny phone numbers shown earlier are **re-hidden** upon expiration
- Active trial in progress: continues unaffected (contacts remain visible while trial is ACTIVE)
- Free contact counter is NOT reset (cannot re-use 5 free contacts again)
- Renewing subscription → restores all access (chats reappear, phones unlocked)

## 4.3 Family (Subscribed)

| Feature | Access |
|---------|--------|
| All free tier features | ✅ Full |
| Unlimited profile views | ✅ Full |
| View nanny phone number | ✅ Full |
| Download CV | ✅ Full |
| Send trial offers | ✅ Full |
| Call/WhatsApp nanny | ✅ Full |
| Priority support | ✅ Full |

## 4.4 Admin

| Feature | Access |
|---------|--------|
| Dashboard overview | ✅ Full |
| Verify nanny documents | ✅ Approve/Reject |
| Review nanny videos | ✅ Approve/Reject |
| View all users | ✅ Full |
| Edit user data | ✅ Full |
| View revenue | ✅ Full |
| Send broadcasts | ✅ Full |
| System settings | ✅ Full |

---

# 5. COMPLETE SCREEN LIST

## 5.1 Authentication Screens (5)

| # | Screen | Purpose |
|---|--------|---------|
| 1 | Welcome / Role Selection | Choose Nanny or Family |
| 2 | Nanny Login/Signup | Phone entry for nanny |
| 3 | Family Login/Signup | Phone entry for family |
| 4 | OTP Verification | 4-digit code verification |
| 5 | Create Password | Set account password |

## 5.2 Nanny Onboarding Screens (6)

| # | Screen | Purpose |
|---|--------|---------|
| 6 | Personal Info (Step 1/6) | Basic info, visa, preferences |
| 7 | Media Upload (Step 2/6) | Photos and intro video |
| 8 | Work Experience (Step 3/6) | Previous employment |
| 9 | References (Step 4/6) | Callable references |
| 10 | Document Upload (Step 5/6) | Passport, visa, EID |
| 11 | Pending Review (Step 6/6) | Waiting for admin approval |

## 5.3 Nanny App Screens (8)

| # | Screen | Purpose |
|---|--------|---------|
| 12 | Nanny Dashboard | Home screen after approval |
| 24A | Jobs Home | Browse available jobs |
| 24B | Job Detail | Full job information |
| 24C | Advanced Filters | Filter job listings |
| 25D | My Applications | Track applications |
| 27A | Nanny Profile Edit | Edit profile sections |
| 32A | Trial Offer Received | View pending trial |
| 32C | Active Trial Screen | Current trial info |

## 5.4 Family App Screens (10)

| # | Screen | Purpose |
|---|--------|---------|
| 13 | Family Job Post Form | Create job requirements |
| 14 | Browse Nannies | Discover nannies |
| 15 | Nanny Profile (Locked) | Limited view for free tier |
| 16 | Nanny Profile (Unlocked) | Full view for subscribers |
| 17 | In-App Chat | Messaging |
| 19 | Trial Active Screen | Manage active trial |
| 26A | Shortlist Home | Saved nannies |
| 26B | Compare Nannies | Side-by-side comparison |
| 27B | Family Profile Edit | Edit profile |
| 31A | Create Trial Offer | Send trial to nanny |

## 5.5 Shared Screens (8)

| # | Screen | Purpose |
|---|--------|---------|
| 18 | Smart Match | Match score display |
| 20 | Pricing & Plans | Subscription options |
| 21 | Terms & Conditions | Legal terms |
| 22 | Privacy Policy | Data policy |
| 28 | Notification Center | All notifications |
| 29A | Settings Main | App preferences |
| 29B | Delete Account Flow | Account deletion |
| 30 | Password Reset Flow | Reset password |

## 5.6 Admin Panel Screens (1)

| # | Screen | Purpose |
|---|--------|---------|
| 23 | Admin Dashboard | Web management interface |

## 5.7 App Navigation Structure

### Nanny App Bottom Navigation
| Tab | Icon | Screen |
|-----|------|--------|
| Home | 🏠 | Nanny Dashboard |
| Jobs | 🔍 | Job Listings |
| Messages | 💬 | Chat List |
| Profile | 👤 | Profile View/Edit |

### Family App Bottom Navigation
| Tab | Icon | Screen |
|-----|------|--------|
| Home | 🏠 | Browse Nannies |
| Search | 🔍 | Advanced Search |
| Messages | 💬 | Chat List |
| Profile | 👤 | Profile View/Edit |

**Total Screens: 38**

---

# 6. FUNCTIONAL FLOWS

## 6.1 Nanny Registration Flow

```
START
  │
  ├─→ [Welcome Screen] Select "I am a Nanny"
  │
  ├─→ [Nanny Login] Enter phone number
  │     └─→ Firebase Auth: Send OTP
  │
  ├─→ [OTP Verification] Enter 4-digit code
  │     └─→ Firebase Auth: Verify OTP
  │     └─→ 🔐 PERMISSION CHECK: Request Notification permission
  │     └─→ ⚡ PUSH: None
  │
  ├─→ [Create Password] Set secure password
  │
  ├─→ [Personal Info] Fill all sections
  │     • Basic info, visa status, work preferences
  │     • Personal status, health, comfort preferences
  │     • Emergency contact, bio
  │
  ├─→ [Media Upload] 
  │     • 🔐 PERMISSION CHECK: Camera + Photo Library
  │     • 🔐 PERMISSION CHECK: Microphone (for video)
  │     • Upload 1-5 photos
  │     • Record/upload 60s intro video
  │     • ⚡ PUSH: None
  │
  ├─→ [Work Experience] Add past jobs
  │
  ├─→ [References] Declare callable references
  │
  ├─→ [Document Upload]
  │     • 🔐 PERMISSION CHECK: Photo Library / Files
  │     • Passport (required)
  │     • Visa (required)
  │     • EID (conditional)
  │     • Training certs, police clearance (optional)
  │
  ├─→ [Submit for Review]
  │     └─→ Status: PENDING
  │     └─→ Profile hidden from families
  │
  ├─→ [ADMIN REVIEW]
  │     ├─→ Documents Approved
  │     │     └─→ ⚡ PUSH: "Documents approved! Your profile is now visible"
  │     │     └─→ Status: APPROVED
  │     │     └─→ Profile visible to families
  │     │
  │     └─→ Documents Rejected
  │           └─→ ⚡ PUSH: "Document rejected: [reason]. Please re-upload"
  │           └─→ Status: REJECTED
  │           └─→ Prompt to re-upload
  │
  └─→ [Nanny Dashboard] Home screen
END
```

## 6.2 Family Registration Flow

```
START
  │
  ├─→ [Welcome Screen] Select "I am a Family"
  │
  ├─→ [Family Login] Enter phone number
  │     └─→ Firebase Auth: Send OTP
  │
  ├─→ [OTP Verification] Enter 4-digit code
  │
  ├─→ [Create Password] Set secure password
  │
  ├─→ [Job Post Form]
  │     • 🔐 PERMISSION CHECK: Location (optional, pre-fill emirate)
  │     • Family info (name, nationality, city, children)
  │     • Religion & culture preferences
  │     • Role & job type + employment (FT/PT slot)
  │     • Uber-style location picker (map + search)
  │     • Working days Mon–Sun multi-select sheet
  │     • Duties checklist
  │     • Benefits offered
  │     • Salary range, trial details, visa sponsorship
  │     • GATE: until ≥1 job is posted, relaunch/resume always returns here;
  │       back navigation cannot open Browse
  │     • Cap: one active full-time + one active part-time job
  │
  ├─→ [Browse Nannies] Home screen
  │     └─→ Free contacts: 5/5 remaining
  │
  └─→ END
```

## 6.3 Nanny Job Application Flow

```
START: Nanny views job listing
  │
  ├─→ [Job Detail Screen] View full job info
  │     • Family info, job requirements, salary
  │     • Match score displayed
  │
  ├─→ [Tap "Apply for this Job"]
  │
  ├─→ [Smart Match Screen] Pre-application check
  │     │
  │     ├─→ Match ≥ 80%: "Great fit! 🌸"
  │     │     └─→ Show matching factors
  │     │     └─→ [Send Application] button
  │     │
  │     └─→ Match < 60%: "Not quite the right match"
  │           └─→ Show mismatching factors
  │           └─→ Warning: Low match applications may not get response
  │           └─→ [Go Back] or [Apply Anyway]
  │
  ├─→ [Application Message Screen]
  │     • Optional cover message (300 chars)
  │     • Quick phrases chips
  │     • Profile preview
  │
  ├─→ [Send Application]
  │     └─→ Create Application record (status: PENDING)
  │     └─→ ⚡ PUSH to Family: "New application from [Nanny Name] - [X]% match"
  │
  ├─→ [Confirmation Screen]
  │     └─→ "Application Sent!"
  │     └─→ Average response time: 1-3 days
  │
  └─→ [My Applications] Track status
        │
        ├─→ Family views application
        │     └─→ ⚡ PUSH to Nanny: "Your application was viewed by [Family Name]"
        │     └─→ Status: VIEWED
        │
        ├─→ Family sends trial offer
        │     └─→ ⚡ PUSH to Nanny: "🎉 Trial offer received from [Family Name]!"
        │     └─→ Status: TRIAL_OFFERED
        │
        └─→ Family declines
              └─→ ⚡ PUSH to Nanny: "Application update from [Family Name]"
              └─→ Status: DECLINED
END
```

## 6.4 Family Browsing & Contact Flow

```
START: Family on Browse Nannies screen
  │
  ├─→ [Browse/Filter Nannies]
  │     • Filter by: location, job type, nationality, language, etc.
  │     • See: preview card with photo, name, nationality, experience, match %
  │
  ├─→ [Tap Nanny Card]
  │     │
  │     ├─→ IF Free tier AND contacts remaining
  │     │     └─→ **USE 1 FREE CONTACT** (profile view = contact used)
  │     │     └─→ Show full profile
  │     │     └─→ Update: viewedProfiles.push(nannyId)
  │     │     └─→ Update: freeContactsUsed++
  │     │     └─→ ⚡ PUSH to Nanny: "Your profile was viewed by [Family Name]"
  │     │     │
  │     │     └─→ IF freeContactsUsed == 4 (1 left)
  │     │           └─→ ⚡ PUSH to Family: "You have 1 free contact remaining"
  │     │
  │     ├─→ IF Free tier AND contacts exhausted (5/5 used)
  │     │     └─→ Show subscription paywall
  │     │     └─→ "Subscribe to continue viewing profiles"
  │     │
  │     └─→ IF Subscribed
  │           └─→ Show full profile (no limit)
  │           └─→ ⚡ PUSH to Nanny: "Your profile was viewed"
  │
  ├─→ [Nanny Profile - Full]
  │     │
  │     ├─→ IF Free tier (viewed profile)
  │     │     • See: full profile, photos, video, match score
  │     │     • LOCKED: phone number, download CV, trial offer, call/WhatsApp
  │     │     • CAN: chat (message nanny)
  │     │
  │     └─→ IF Subscribed
  │           • See: everything unlocked
  │           • Phone number visible
  │           • Download CV button
  │           • Call, WhatsApp, Chat buttons
  │           • Send Trial Offer button
  │
  ├─→ [Actions]
  │     │
  │     ├─→ Add to Shortlist (heart icon)
  │     │     └─→ Save to favorites
  │     │     └─→ No push notification
  │     │
  │     ├─→ Message Nanny
  │     │     └─→ Open chat thread
  │     │     └─→ ⚡ PUSH to Nanny: "New message from [Family Name]"
  │     │
  │     ├─→ Call/WhatsApp (SUBSCRIBERS ONLY)
  │     │     └─→ Open phone/WhatsApp with nanny number
  │     │     └─→ No push notification
  │     │
  │     └─→ Send Trial Offer (SUBSCRIBERS ONLY)
  │           └─→ Go to Trial Offer Creation flow
  │
  └─→ END
```

## 6.5 Trial Flow (Complete)

```
START: Family sends trial offer
  │
  ├─→ [Family: Create Trial Offer]
  │     • Select duration: 1, 3, 7, 14, or custom days
  │     • Set daily rate (AED)
  │     • Choose start date & time
  │     • Select: live-in or live-out
  │     • Add notes (optional)
  │
  ├─→ [Trial Summary]
  │     • ⚠️ "Payment is handled directly between you and the nanny"
  │     • ☑ "I understand payment is direct"
  │     └─→ [Send Trial Offer]
  │
  ├─→ [Create Trial Record]
  │     └─→ Status: PENDING
  │     └─→ ⚡ PUSH to Nanny: "🎉 Trial offer from [Family Name]! [X] days @ AED [Y]/day"
  │
  ├─→ [Nanny: Receives Trial Offer]
  │     • View offer details
  │     • Response deadline shown
  │     │
  │     ├─→ [Accept]
  │     │     └─→ Status: ACCEPTED
  │     │     └─→ ⚡ PUSH to Family: "✅ [Nanny Name] accepted your trial offer!"
  │     │     └─→ Phone numbers revealed to both parties
  │     │     └─→ Schedule trial start
  │     │
  │     ├─→ [Counter Offer]
  │     │     • Propose different daily rate
  │     │     • Propose different start date
  │     │     • Add message explaining counter
  │     │     └─→ Status: COUNTERED
  │     │     └─→ ⚡ PUSH to Family: "[Nanny Name] sent a counter offer"
  │     │     │
  │     │     └─→ [Family Reviews Counter]
  │     │           ├─→ Accept counter → Status: ACCEPTED
  │     │           └─→ Decline counter → Status: DECLINED
  │     │
  │     └─→ [Decline]
  │           └─→ Status: DECLINED
  │           └─→ ⚡ PUSH to Family: "[Nanny Name] declined your trial offer"
  │
  ├─→ [Trial Starting Soon - 1 Day Before]
  │     └─→ ⚡ PUSH to Both: "⏰ Trial starts tomorrow at [time]!"
  │
  ├─→ [Trial Starts]
  │     └─→ Status: ACTIVE
  │     └─→ Nanny availability: ON_TRIAL
  │     └─→ Timer begins countdown
  │     └─→ Both can view each other's phone numbers
  │     └─→ Both can call/WhatsApp directly
  │
  ├─→ [During Trial]
  │     • Both see trial dashboard with countdown
  │     • Chat continues
  │     • Family can fill evaluation checklist
  │     │
  │     └─→ [Trial Ending Soon - 2 Days Before End]
  │           └─→ ⚡ PUSH to Family: "🤝 Trial ends in 2 days. Time to decide!"
  │           └─→ ⚡ PUSH to Nanny: "Trial ends in 2 days"
  │
  ├─→ [Trial Ends]
  │     └─→ Status: COMPLETED
  │     └─→ ⚡ PUSH to Both: "Trial completed!"
  │
  ├─→ [Nanny: Confirm Payment]
  │     • "Total: AED [X]"
  │     • ⚠️ "Payment handled directly with family"
  │     │
  │     ├─→ [Confirm Payment Received] 
  │     │     └─→ nannyConfirmedPayment = true
  │     │     └─→ Rate-the-app prompt (throttled)
  │     │
  │     └─→ [Report Payment Issue]
  │           └─→ paymentIssueReported = true
  │           └─→ Contact support flow
  │
  ├─→ [Family: Confirm Payment]
  │     • Same "Confirm payment" control on Screen 19 (settlement)
  │     └─→ nannyConfirmedPayment = true + rate-the-app prompt (throttled)
  │
  ├─→ [Family: Make Decision]
  │     • Review evaluation checklist
  │     │
  │     ├─→ [Hire! ✅]
  │     │     └─→ Status: HIRED
  │     │     └─→ ⚡ PUSH to Nanny: "🎊 Congratulations! You're hired by [Family Name]!"
  │     │     └─→ Show employment details
  │     │     └─→ Prompt nanny to update profile status
  │     │
  │     └─→ [Not This Time]
  │           └─→ Outcome: NOT_HIRED
  │           └─→ ⚡ PUSH to Nanny: "Trial with [Family Name] ended. Keep browsing!"
  │           └─→ Nanny returns to available status
  │
  └─→ END
```

## 6.6 Messaging Flow

```
START: User opens chat
  │
  ├─→ [Chat List]
  │     • Show all conversations
  │     • Unread count badges
  │     • Trial status indicators (e.g., "ON TRIAL", "Trial day 2/7")
  │     • Last message preview
  │     • "Active", "Chat open", "Replied" status badges
  │
  ├─→ [Subscription Gate Check - Family Only]
  │     • IF status in [ACTIVE, CANCELLED-IN-PERIOD]: Proceed
  │     • IF status = FREE: Proceed (limited)
  │     • IF status in [EXPIRED, PAYMENT_FAILED]: 🔒 BLOCK ACCESS
  │         - Hide entire chat list
  │         - Show paywall: "Renew subscription to access your chats"
  │         - Existing messages preserved but hidden
  │         - Exception: Active trial chats remain accessible
  │
  ├─→ [Open Chat Thread]
  │     │
  │     ├─→ [Family View - Subscribed (ACTIVE)]
  │     │     • Contact strip (green): "Subscribed · [Nanny]'s direct contacts unlocked"
  │     │     • Buttons: 📞 Call, WhatsApp
  │     │     • See nanny phone, WhatsApp button, Call button
  │     │     • System message: "🔒 Chat opened · Both numbers remain private 
  │     │       in chat · Use the buttons above to call or WhatsApp directly"
  │     │
  │     ├─→ [Family View - Free Tier]
  │     │     • No contact strip (locked)
  │     │     • Phone/WhatsApp hidden
  │     │     • Can still send text messages
  │     │
  │     ├─→ [Family View - EXPIRED Subscription]
  │     │     • Chat is HIDDEN from thread list entirely
  │     │     • If accessed via deep link: Show paywall screen
  │     │     • "Your subscription expired. Renew to view this chat."
  │     │     • Cannot read history, cannot send new messages
  │     │     • Renewal restores full access immediately
  │     │
  │     └─→ [Nanny View]
  │           • Contact strip (purple): "Family number is private · 
  │             Chat is your connection · Share your number directly if comfortable"
  │           • Family phone: ALWAYS HIDDEN
  │           • Exception: IF trial active → phone revealed
  │           • System message: "💜 [Family] shortlisted your profile · Chat is now open"
  │           • If family subscription expired:
  │               - Nanny CAN still see thread (read-only)
  │               - Nanny can send messages, but they won't be read until family renews
  │               - System message: "Family's subscription expired - they may not see your messages"
  │
  ├─→ [Send Message]
  │     • Validate sender access (subscription check for family)
  │     • IF family expired: Block send, show paywall
  │     └─→ Create Message record
  │     └─→ ⚡ PUSH to Recipient: "💬 New message from [Name]"
  │
  ├─→ [Special Message Types]
  │     • Trial offer bubble (with duration, rate, type, location, Accept/Counter buttons)
  │     • Trial accepted confirmation (green bubble)
  │     • System messages (chat opened, trial started, etc.)
  │
  ├─→ [Chat Privacy Rules]
  │     • 📞 Nanny phone: Visible to active-subscribed families
  │     • 📞 Nanny phone: HIDDEN again when subscription expires
  │     • 💬 In-app chat: Accessible only with ACTIVE subscription
  │     • 🔒 Family number: Never shown to nanny (stays private)
  │
  └─→ END
```

## 6.7 Password Reset Flow

```
START: User taps "Forgot password?"
  │
  ├─→ [Enter Phone Number]
  │     └─→ Validate phone exists in system
  │     │
  │     ├─→ Phone not found
  │     │     └─→ Error: "No account found with this number"
  │     │
  │     └─→ Phone found
  │           └─→ Firebase Auth: Send OTP
  │
  ├─→ [Enter OTP]
  │     └─→ Verify code
  │
  ├─→ [Create New Password]
  │     • Password requirements validation
  │     • Confirm password match
  │
  ├─→ [Success]
  │     └─→ "Password updated!"
  │     └─→ [Sign In Now] button
  │
  └─→ END
```

## 6.8 Subscription Flow

```
START: Family needs subscription
  │
  ├─→ [Trigger: Any of]
  │     • Taps locked content (phone, CV, trial)
  │     • Exhausts 5 free contacts
  │     • Taps "Subscribe" in settings
  │
  ├─→ [Pricing Screen]
  │     • Show 3 plans:
  │       - Weekly: AED 89 / 7 days
  │       - Monthly: AED 239 / 30 days (Most Popular)
  │       - 2 Months: AED 369 / 60 days
  │     • All plans auto-renew
  │     • Managed via RevenueCat
  │
  ├─→ [Tap Plan]
  │     └─→ RevenueCat: Present payment sheet
  │     └─→ Native iOS/Android subscription flow
  │     │
  │     ├─→ [Payment Success]
  │     │     └─→ Update subscription status: ACTIVE
  │     │     └─→ Set plan type, start date, end date
  │     │     └─→ ⚡ PUSH: "🎉 Subscription activated! Full access unlocked"
  │     │     └─→ Unlock all premium features
  │     │
  │     └─→ [Payment Failed/Cancelled]
  │           └─→ Return to pricing screen
  │           └─→ No changes
  │
  ├─→ [Auto-Renewal Events]
  │     │
  │     ├─→ [3 Days Before Expiry]
  │     │     └─→ ⚡ PUSH: "💳 Subscription renews in 3 days"
  │     │
  │     ├─→ [Renewal Success]
  │     │     └─→ Extend end date
  │     │     └─→ ⚡ PUSH: "✅ Subscription renewed successfully"
  │     │
  │     └─→ [Renewal Failed]
  │           └─→ Status: EXPIRED
  │           └─→ ⚡ PUSH: "⚠️ Subscription expired. Renew to keep access"
  │           └─→ 🔒 LOCKDOWN MODE ACTIVATED:
  │                 • Hide nanny phone numbers (everywhere)
  │                 • Lock all chat threads (hide from list)
  │                 • Disable new full profile views
  │                 • Disable trial offer creation
  │                 • Disable CV downloads
  │                 • Disable Call/WhatsApp buttons
  │           └─→ Data preserved (not deleted) - restored on re-subscription
  │           └─→ EXCEPTION: Active trial keeps contacts visible until trial ends
  │
  ├─→ [Cancel Subscription]
  │     └─→ Open App Store / Play Store subscription settings
  │     └─→ User cancels via native UI
  │     └─→ Status: CANCELLED-IN-PERIOD (full access continues until end date)
  │     └─→ ⚡ PUSH on cancel: "Subscription cancelled. You have access until [date]"
  │     └─→ At end date: Status → EXPIRED, lockdown activated
  │
  └─→ END
```

## 6.8.1 Subscription Expiration & Lockdown Flow

```
TRIGGER: endDate passed OR renewal failed OR family cancelled (past end date)
  │
  ├─→ [Daily Check (Cloud Function scheduled)]
  │     • Query all families where status = ACTIVE/CANCELLED
  │     • Compare endDate vs now
  │
  ├─→ [Status Transition]
  │     status: ACTIVE → EXPIRED
  │     expiredAt: now()
  │     contactsHidden: true
  │     chatLocked: true
  │
  ├─→ [Lock All Features]
  │     • Chat threads: marked locked (UI hides them)
  │     • Phone numbers: hidden everywhere
  │     • Trial creation: blocked
  │     • Profile views: blocked
  │     • CV downloads: blocked
  │     • Call/WhatsApp buttons: hidden
  │
  ├─→ [Send Notifications]
  │     • ⚡ PUSH (Day 0): "⚠️ Your subscription expired. Renew to access chats & contacts"
  │     • ⚡ PUSH (Day 3): "💔 Your matches are waiting. Renew to reconnect"
  │     • ⚡ PUSH (Day 7): "🔓 Renew anytime - your chats and shortlist are saved"
  │
  ├─→ [User Experience]
  │     • Home: Banner "Subscription expired - Renew now"
  │     • Chat tab: Empty state with paywall "Renew to view your chats"
  │     • Nanny profiles: Phone numbers blurred again
  │     • Browse: Can still browse but cannot view full
  │     • Settings: "Renew Subscription" CTA prominent
  │
  ├─→ [Exception: Active Trial]
  │     • IF family has trial with status = ACTIVE:
  │       - Trial chat REMAINS accessible
  │       - Nanny contact REMAINS visible
  │       - System keeps trial flow intact
  │     • Once trial ends: full lockdown applies
  │
  ├─→ [Re-Subscription Flow]
  │     • User taps any locked feature → paywall
  │     • Selects plan → RevenueCat payment sheet
  │     • Success: status → ACTIVE
  │     • Cloud Function: Restore access
  │       - chatLocked: false
  │       - contactsHidden: false
  │       - Chat threads reappear
  │       - Phone numbers visible again
  │     • ⚡ PUSH: "🎉 Welcome back! Full access restored"
  │
  └─→ END
```

## 6.9 Account Deletion Flow

```
START: User taps "Delete Account"
  │
  ├─→ [Confirmation Screen]
  │     • Warning: This permanently deletes all data
  │     • List what will be deleted
  │     • Optional: Select reason for leaving
  │
  ├─→ [Re-authenticate]
  │     • Enter password OR request OTP
  │
  ├─→ [Final Confirmation]
  │     • Type "DELETE" to confirm
  │
  ├─→ [Delete Account]
  │     │
  │     ├─→ [IF Family with Active Subscription]
  │     │     └─→ Note: Subscription cancellation via App Store/Play Store
  │     │     └─→ Refund policy per platform
  │     │
  │     ├─→ [IF Nanny/Family with Active Trial]
  │     │     └─→ Warning: You have an active trial
  │     │     └─→ Complete trial first OR proceed anyway
  │     │
  │     └─→ [Proceed]
  │           └─→ Delete: Profile, photos, videos, documents
  │           └─→ Delete: Messages, applications, trials history
  │           └─→ Remove from shortlists
  │           └─→ Firebase Auth: Delete user
  │           └─→ No push notification sent
  │
  └─→ [Redirect to Welcome Screen]
END
```

---

# 7. PUSH NOTIFICATIONS

## 7.1 Notification Events Table

| Category | Event | Recipient | Title | Body |
|----------|-------|-----------|-------|------|
| **Messages** | New message | Both | 💬 New message | "[Name]: [Preview]" |
| **Applications** | New application | Family | 📝 New application | "[Nanny] applied - [X]% match" |
| **Applications** | Application viewed | Nanny | 👁 Profile viewed | "[Family] viewed your application" |
| **Applications** | Application declined | Nanny | Application update | "[Family] chose another candidate" |
| **Trials** | Trial offer sent | Nanny | 🎉 Trial offer! | "[Family] sent [X] day trial @ AED [Y]/day" |
| **Trials** | Trial accepted | Family | ✅ Trial accepted | "[Nanny] accepted your offer!" |
| **Trials** | Trial declined | Family | Trial declined | "[Nanny] declined your offer" |
| **Trials** | Counter offer | Family | 🔄 Counter offer | "[Nanny] sent a counter offer" |
| **Trials** | Starting soon | Both | ⏰ Trial tomorrow | "Trial starts tomorrow at [time]" |
| **Trials** | Ending soon | Both | 🤝 Trial ending | "Trial ends in 2 days" |
| **Trials** | Completed | Both | Trial complete | "Your [X] day trial has ended" |
| **Hiring** | Hired | Nanny | 🎊 You're hired! | "[Family] offered you employment!" |
| **Profile** | Profile viewed | Nanny | 👁 Profile viewed | "A family viewed your profile" |
| **Profile** | Docs approved | Nanny | ✅ Verified! | "Your profile is now visible" |
| **Profile** | Docs rejected | Nanny | ❌ Action needed | "[Doc type] rejected: [reason]" |
| **Subscription** | Expiring | Family | 💳 Expiring soon | "Subscription renews in 3 days" |
| **Subscription** | Renewed | Family | ✅ Renewed | "Subscription renewed successfully" |
| **Subscription** | Expired | Family | ⚠️ Expired | "Renew to keep full access" |
| **Subscription** | Low contacts | Family | ⚠️ 1 contact left | "You have 1 free view remaining" |
| **System** | Announcement | All | 📢 [Title] | "[Message]" |

## 7.2 Notification Settings (User Controllable)

| Setting | Default | Description |
|---------|---------|-------------|
| Push notifications | ON | Master toggle |
| Messages | ON | New message alerts |
| Job matches | ON | New matching jobs (nanny) |
| Trial updates | ON | All trial-related |
| Profile views | OFF | When profile is viewed (nanny) |
| Marketing | OFF | Tips and promotions |
| Email notifications | ON | Email copies |

---

# 8. PAYMENT & SUBSCRIPTION HANDLING

## 8.1 Subscription Plans (via RevenueCat)

| Plan | Duration | Price (AED) | +5% VAT | Total | Auto-Renew |
|------|----------|-------------|---------|-------|------------|
| Weekly | 7 days | 89 | 4.45 | 93.45 | Yes |
| Monthly | 30 days | 239 | 11.95 | 250.95 | Yes (Most Popular) |
| 2 Months | 60 days | 369 | 18.45 | 387.45 | Yes (Save 129 AED) |

## 8.2 Payment Flow

```
[User selects plan]
       │
       ▼
[RevenueCat SDK presents native payment sheet]
       │
       ├─→ iOS: Apple Pay / Credit Card via App Store
       ├─→ Android: Google Pay / Credit Card via Play Store
       └─→ Android: Samsung Pay (where available)
       │
       ▼
[Payment processed by Apple/Google]
       │
       ▼
[RevenueCat webhook → Update subscription status in Firestore]
       │
       ▼
[User gets full access]
```

## 8.3 Key Points

- **No payment gateway needed** - Apple/Google handle all payments
- **VAT/Tax** - Handled by Apple/Google based on user location
- **Refunds** - Via App Store/Play Store policies
- **Restore Purchases** - RevenueCat handles across devices
- **Trial payments** - NOT handled by app (direct between users)
- **Nanny salary** - NOT handled by app (direct between users)

## 8.4 Subscription States & Access Matrix

| State | Description | Profile View | Phone Number | Chat | Trial Offers |
|-------|-------------|--------------|--------------|------|--------------|
| `free` | Never subscribed | 5 free | ❌ Locked | ⚠️ After view | ❌ Locked |
| `active` | Paid + current | ✅ Unlimited | ✅ Visible | ✅ Full | ✅ Full |
| `cancelled` | Cancelled, still in period | ✅ Unlimited | ✅ Visible | ✅ Full | ✅ Full |
| **`expired`** | **Past end date** | ❌ **LOCKED** | ❌ **HIDDEN** | ❌ **HIDDEN** | ❌ **LOCKED** |
| **`payment_failed`** | **Renewal failed** | ❌ **LOCKED** | ❌ **HIDDEN** | ❌ **HIDDEN** | ❌ **LOCKED** |

## 8.5 Subscription Expiration Behavior

### What gets locked:
1. **Nanny phone numbers** → blurred/hidden on all profiles (including previously viewed)
2. **Chat threads** → entire chat list hidden behind subscription wall
3. **Individual chats** → cannot open, cannot send messages, history hidden
4. **CV downloads** → button disabled
5. **Trial offers** → cannot send new ones
6. **Call/WhatsApp buttons** → hidden
7. **Profile views** → no new full views

### What stays accessible:
1. **Browse nanny cards** (preview list)
2. **Intro videos** (free)
3. **Match scores** (visible)
4. **Job posts** (can manage existing)
5. **Settings** (can renew)
6. **Notifications** (renewal CTAs)
7. **ACTIVE trial** (only ongoing trials keep contacts visible until trial ends)

### What gets preserved (not deleted):
- Chat threads (data retained, just hidden)
- Previously viewed profiles (recorded but locked again)
- Job posts and applications
- Shortlist
- Trial history

### Re-subscription restores everything:
- Chats reappear instantly
- Phone numbers unlock
- All previous data accessible

---

# 9. MATCH ALGORITHM

## 9.1 Factor Weights

| Factor | Weight | Description |
|--------|--------|-------------|
| Location | 25% | Nanny preferred emirates vs family emirate |
| Language | 20% | Required language overlap |
| Experience | 15% | Years required vs nanny experience |
| Job Type | 15% | Live-in/out preference match |
| Skills | 10% | Required skills (newborn, cooking, etc.) |
| Salary | 10% | Family budget vs nanny expectation |
| Availability | 5% | Start date alignment |

## 9.2 Score Calculation

```
Total Score = Σ (Factor Score × Weight)

Factor Score:
- Full match = 100%
- Partial match = 50%
- No match = 0%

Example:
- Location: 100% × 0.25 = 25
- Language: 100% × 0.20 = 20
- Experience: 50% × 0.15 = 7.5
- Job Type: 100% × 0.15 = 15
- Skills: 100% × 0.10 = 10
- Salary: 50% × 0.10 = 5
- Availability: 100% × 0.05 = 5
───────────────────────────────
Total: 87.5% → "Great Match"
```

## 9.3 Display Badges

| Score Range | Badge | Color | Message |
|-------------|-------|-------|---------|
| 80-100% | Great Match | Green | "You're a great fit! 🌸" |
| 60-79% | Good Match | Orange | "Good match" |
| Below 60% | Low Match | Red | "Not quite the right match" |

## 9.4 Smart Match Check Items Display

| Check Type | Pass Display | Fail Display | Warn Display |
|------------|--------------|--------------|--------------|
| Language | "✓ Arabic + English — matches" | "✗ Arabic required — not on profile" | - |
| Experience | "✓ 5 years exp — exceeds requirement" | "✗ Needs 3+ years — shows 1 year" | - |
| Skills | "✓ Newborn experience — verified" | - | "! Newborn experience — unclear" |
| Job Type | "✓ Live-in availability — matches" | - | - |
| Salary | "✓ Salary range — within expectation" | - | "! Salary slightly above — discuss" |

---

# 10. TRIAL SYSTEM

## 10.1 Trial Check Requirements

| Check | When | Action |
|-------|------|--------|
| Subscription active | Family sends offer | Block if free tier |
| Nanny verified | Family sends offer | Only to verified nannies |
| No active trial | Nanny accepts | Warn if already on trial |
| Response deadline | Nanny receives | Auto-decline after 48h (optional) |

## 10.2 Trial States

```
PENDING → ACCEPTED → ACTIVE → COMPLETED → HIRED
    │         │                    │
    ├──→ DECLINED                  └──→ NOT_HIRED
    └──→ COUNTERED → ACCEPTED
              │
              └──→ DECLINED
```

## 10.3 Important: Payment Handling

- **Kafi does NOT process trial payments**
- Payment is DIRECT between family and nanny
- App shows: "⚠️ Payment handled directly between you and the nanny"
- Family and nanny discuss payment terms themselves
- Nanny can report payment issues to support

---

# 11. FREE TIER RESTRICTIONS

## 11.1 What Counts as Using a Free Contact

| Action | Uses Contact? |
|--------|---------------|
| Viewing nanny profile card (preview) | ❌ No |
| Viewing full nanny profile | ✅ Yes (1 contact) |
| Viewing same profile again | ❌ No (already counted) |
| Watching intro video | ❌ No (part of browse) |
| Seeing match score | ❌ No |

## 11.2 Features Locked by Subscription State

| Feature | Free | Active | Expired |
|---------|------|--------|---------|
| Browse nanny cards | ✅ Unlimited | ✅ Unlimited | ✅ Unlimited |
| View full profiles | ⚠️ 5 total | ✅ Unlimited | ❌ Locked |
| Re-view previously seen profile | ⚠️ Free | ✅ Yes | ❌ Locked |
| Watch intro videos | ✅ Yes | ✅ Yes | ✅ Yes |
| See match scores | ✅ Yes | ✅ Yes | ✅ Yes |
| In-app chat — list | ⚠️ After view | ✅ Visible | ❌ **HIDDEN** |
| In-app chat — read history | ⚠️ After view | ✅ Yes | ❌ **HIDDEN** |
| In-app chat — send messages | ⚠️ After view | ✅ Yes | ❌ **BLOCKED** |
| View phone number | ❌ Locked | ✅ Yes | ❌ **HIDDEN** |
| Download CV | ❌ Locked | ✅ Yes | ❌ Locked |
| Send trial offer | ❌ Locked | ✅ Yes | ❌ Locked |
| Call nanny | ❌ Locked | ✅ Yes | ❌ **HIDDEN** |
| WhatsApp nanny | ❌ Locked | ✅ Yes | ❌ **HIDDEN** |
| Active trial chat/contact | N/A | ✅ Yes | ✅ Yes (during trial) |

## 11.3 Free Tier UI Indicators

- Progress bar: "3 of 5 free views used"
- Subscribe CTA on locked content
- Subscription badge on full profile

---

# 12. ADMIN FUNCTIONS

## 12.1 Dashboard Metrics

### Top-Level Stats
| Metric | Source |
|--------|--------|
| Total users | Count of User documents |
| Active subscriptions | Count where status = active |
| This month revenue | Sum of subscription payments |
| VAT collected | 5% of revenue (for FTA reporting) |
| Pending document reviews | Count where status = pending |
| Pending video reviews | Count where status = pending |

### Revenue by Plan Breakdown
| Plan | Calculation |
|------|-------------|
| Weekly (AED 89) | Count × 89 |
| Monthly (AED 239) | Count × 239 |
| 2-Months (AED 369) | Count × 369 |
| VAT (5%) | Total revenue × 0.05 |

### Nanny Analytics
| Metric | Description |
|--------|-------------|
| Nannies by status | Active, Pending docs, Pending video |
| Nannies by nationality | Filipino, Sri Lankan, Ethiopian, Indian, Other |
| Nannies by city | Dubai, Abu Dhabi, Sharjah, Other (RAK, UAQ, Ajman, Fujairah, Al Ain) |

### Family Analytics
| Metric | Description |
|--------|-------------|
| Families by status | Subscribed, Free users, New today |
| Families by plan | Weekly, Monthly, 2-months, Not subscribed |
| Families by nationality | Emirati, Arab expats, Western, Asian expats |
| Active trials | Currently running trial periods |

## 12.2 Admin Panel Navigation Structure

| Section | Menu Item | Badge |
|---------|-----------|-------|
| Overview | Dashboard | - |
| Nannies | All nannies | Total count |
| Nannies | Verify docs | Pending count |
| Nannies | Review videos | Pending count |
| Families | All families | Total count |
| Families | Subscriptions | Active count |
| Business | Revenue | - |
| Business | Broadcast | - |
| Business | Settings | - |

## 12.3 Admin Actions

| Action | Description |
|--------|-------------|
| Approve document | Set document.status = 'approved' |
| Reject document | Set document.status = 'rejected' + reason |
| Approve video | Set video.status = 'approved' |
| Reject video | Set video.status = 'rejected' + reason |
| Send broadcast | Create Broadcast document + trigger FCM |
| View user | Read full user document |
| Edit user | Update user fields |
| Delete user | Remove all user data |
| Export CSV | Download data as CSV file |
| Send reminder | Send subscription reminder to free users |
| Hide inactive nannies | Toggle `settings/global.hideInactiveNannies` — when on, family Browse lists only nannies with `lastActiveAt` within 14 days |

## 12.4 Analytics Events to Track

| Event | Trigger |
|-------|---------|
| `user_registered` | New user created |
| `nanny_profile_created` | Nanny completes onboarding |
| `family_profile_created` | Family completes job post |
| `document_uploaded` | Document submitted |
| `video_uploaded` | Video submitted |
| `profile_viewed` | Family views nanny profile |
| `application_sent` | Nanny applies to job |
| `trial_offer_sent` | Family sends trial |
| `trial_accepted` | Nanny accepts trial |
| `nanny_hired` | Family hires nanny |
| `subscription_started` | New subscription |
| `subscription_renewed` | Subscription renewed |
| `subscription_cancelled` | Subscription cancelled |
| `message_sent` | Message sent |

---

# 13. SECURITY & PRIVACY

## 13.1 Data Storage

| Data Type | Storage | Encryption |
|-----------|---------|------------|
| User credentials | Firebase Auth | Firebase managed |
| Profile data | Firestore | At-rest (Firebase) |
| Documents | Firebase Storage | At-rest (Firebase) |
| Photos | Firebase Storage | At-rest (Firebase) |
| Videos | Firebase Storage | At-rest (Firebase) |

## 13.2 Privacy Rules

| Data | Nanny Can See | Family Can See |
|------|---------------|----------------|
| Nanny phone | Own | IF subscription ACTIVE OR during active trial |
| Family phone | IF during active trial only | Own |
| Nanny full name | Own | IF subscription ACTIVE |
| Family full name | First name + "Family" | Own |
| Documents | Own | ❌ Never |
| Chat history | Own threads | IF subscription ACTIVE (hidden when expired) |
| Chat send | Own threads (always) | IF subscription ACTIVE only |

## 13.3 Subscription Expiration Privacy Impact

When subscription expires, the following data becomes inaccessible (NOT deleted):

| Data | State on Expiration | Restored on Renewal |
|------|---------------------|---------------------|
| Nanny phone numbers | Hidden/Re-blurred | ✅ Yes |
| Chat thread list | Hidden | ✅ Yes |
| Chat messages history | Hidden | ✅ Yes |
| CV download links | Disabled | ✅ Yes |
| Previously-viewed nanny profiles | Locked | ✅ Yes |
| Trial offers (active) | Continue (exception) | N/A |
| Job posts | Remain visible | N/A |
| Shortlist | Visible (preview only) | ✅ Yes |

## 13.3 Access Control

- Firebase Security Rules enforce all access
- Users can only read/write own data
- Admin has elevated permissions
- No cross-user data leakage

## 13.4 Terms & Conditions Summary

| Section | Key Points |
|---------|------------|
| Platform Nature | Kafi is marketplace only - does NOT employ, sponsor, or act as agency |
| User Eligibility | 18+ years old, accurate info, comply with UAE laws |
| Profile Information | Accurate info required, no fake identities |
| Verification | Limited document checks, families responsible for final decisions |
| Communication | Via platform, private details hidden until authorized |
| Payments | Subscription fees non-transferable, +5% UAE VAT |
| Liability | Kafi not liable for disputes, injuries, misconduct |
| Termination | May suspend/terminate for policy violations |
| Governing Law | UAE laws |

## 13.5 Privacy Policy Summary

| Section | Key Points |
|---------|------------|
| Data Collected | Personal info, documents, profile, media, technical data |
| Usage | Profiles, matching, verification, safety, subscriptions |
| Consent | Implied by using platform |
| Data Sharing | Between matched users, payment/verification providers, as required by law |
| Profile Visibility | Nanny phone visible to subscribers, family phone always private |
| Data Protection | Secure storage, encryption, restricted access |
| User Rights | Request updates, corrections, deletion |
| Children | Not intended for users under 18 |

---

# APPENDIX A: NOTIFICATION SUMMARY FOR IMPLEMENTATION

## Messages to Send (FCM)

```javascript
// New message
{
  token: recipientFcmToken,
  notification: {
    title: "💬 New message",
    body: `${senderName}: ${messagePreview}`
  },
  data: {
    type: "new_message",
    threadId: threadId,
    senderId: senderId
  }
}

// Trial offer
{
  token: nannyFcmToken,
  notification: {
    title: "🎉 Trial offer received!",
    body: `${familyName} sent you a ${days}-day trial @ AED ${rate}/day`
  },
  data: {
    type: "trial_offer_received",
    trialId: trialId
  }
}

// Documents approved
{
  token: nannyFcmToken,
  notification: {
    title: "✅ Documents approved!",
    body: "Your profile is now verified and visible to families"
  },
  data: {
    type: "documents_approved"
  }
}
```

---

# APPENDIX B: TRIAL VERSION (FREE TIER) FEATURE SUMMARY

## Features HIDDEN/LOCKED for Free Tier Families

1. **Phone number** - Blurred/locked on profile
2. **Full CV download** - Button disabled
3. **Send trial offer** - Button disabled with subscribe CTA
4. **Call button** - Locked
5. **WhatsApp button** - Locked
6. **Unlimited profile views** - Limited to 5 total

## Features AVAILABLE in Free Tier

1. Browse all nanny cards (unlimited)
2. View 5 full profiles (then locked)
3. Watch all intro videos
4. See all match scores
5. Post job requirements
6. Receive applications
7. In-app chat (after using a free contact)
8. View pricing plans

## Push Notifications for Free Tier

All notifications are sent regardless of subscription status. Free tier families receive:
- New applications
- New messages
- Trial updates (if they somehow have one)
- Free contact warnings ("1 left")
- Marketing/system announcements

---

---

# 14. ERROR HANDLING & EDGE CASES

## 14.1 Authentication Errors

| # | Scenario | User Message | Action |
|---|----------|--------------|--------|
| A1 | Invalid phone format | "Please enter a valid phone number" | Highlight field |
| A2 | Phone not registered (login) | "No account found with this number" | Suggest signup |
| A3 | Phone already registered (signup) | "An account already exists. Sign in instead." | Redirect to login |
| A4 | Phone registered with different role | "This number is registered as a [role]. One number = one role." | Block, show contact support |
| A5 | OTP send failed | "Couldn't send code. Check your number and try again." | Retry button |
| A6 | OTP rate limited | "Too many attempts. Try again in [X] minutes." | Disable resend |
| A7 | OTP expired (5 min) | "Code expired. Tap resend." | Show resend |
| A8 | OTP incorrect | "Invalid code. [X] attempts remaining." | Allow retry up to 5 |
| A9 | OTP max attempts | "Too many wrong attempts. Try later." | Lock for 30 min |
| A10 | Network error | "No internet. Check connection." | Retry button |
| A11 | Firebase Auth quota exceeded | "Service busy. Try again shortly." | Wait + retry |
| A12 | Password too weak | "Use 8+ chars, 1 uppercase, 1 number" | Highlight requirements |
| A13 | Passwords don't match | "Passwords don't match" | Inline error |
| A14 | Wrong password (login) | "Incorrect password. [X] left." | Allow retry |
| A15 | Account suspended | "Account suspended. Contact support." | Show support link |
| A16 | Account deleted | "Account no longer exists" | Redirect to welcome |
| A17 | Session expired | "Please sign in again" | Force logout |
| A18 | Reauth required (sensitive ops) | "For security, please verify again" | Re-prompt OTP/password |
| A19 | reCAPTCHA failed | "Verification failed. Retry." | Retry |
| A20 | Auto-verify timeout (Android) | Fall back to manual OTP entry | Allow manual entry |

## 14.2 Permission Errors

| # | Permission | First Denial | Permanent Denial | Recovery |
|---|------------|--------------|------------------|----------|
| P1 | Camera | Show rationale + re-request | Show "Open Settings" dialog | Settings → toggle |
| P2 | Photo Library | Show rationale + re-request | Show "Open Settings" dialog | Settings → toggle |
| P3 | Microphone | Show rationale + re-request | Show "Open Settings" dialog | Settings → toggle |
| P4 | Notifications | Allow skip, prompt later | Show "Enable in Settings" CTA | Settings → toggle |
| P5 | Location | Allow manual selection | Use manual emirate selection | Optional, skippable |
| P6 | Storage (Android <13) | Show rationale + re-request | Show "Open Settings" dialog | Settings → toggle |
| P7 | Location services OFF | "Turn on Location Services" | Open OS Location Settings | Toggle in OS |
| P8 | Limited photo access (iOS 14+) | Show "Select more photos" option | Re-prompt selection sheet | Settings → All Photos |

### Permission Denial Flow

```
Permission Requested
        │
        ├─→ Granted → Proceed
        │
        ├─→ Denied (first time)
        │     └─→ Show rationale dialog
        │           └─→ User taps "Allow" → Re-request
        │           └─→ User taps "Cancel" → Block feature, show retry CTA
        │
        └─→ Denied permanently
              └─→ Show "Open Settings" dialog
                    └─→ User opens Settings → Returns → Re-check on resume
                    └─→ User cancels → Block feature, show retry CTA
```

## 14.3 File Upload Errors

| # | Scenario | User Message | Action |
|---|----------|--------------|--------|
| F1 | Photo > 5 MB | "Photo too large. Max 5 MB." | Show compress option |
| F2 | Video > 50 MB | "Video too large. Max 50 MB." | Show shorter video tip |
| F3 | Video > 60 seconds | "Video must be 60 seconds or less" | Trim option |
| F4 | Document > 10 MB | "Document too large. Max 10 MB." | Compress / re-scan |
| F5 | Unsupported format | "File type not supported. Use JPG/PNG/PDF." | Re-pick |
| F6 | Corrupt file | "Could not read file. Try another." | Re-pick |
| F7 | Network failure mid-upload | "Upload failed. Tap to retry." | Resume upload |
| F8 | Storage quota exceeded (server) | "Upload failed. Contact support." | Support CTA |
| F9 | Photo limit reached (5 max) | "Maximum 5 photos. Remove one first." | Show delete option |
| F10 | No photos uploaded (required) | "Add at least 1 photo to continue" | Block "Next" |
| F11 | Required document missing | "Passport and Visa are required" | Highlight missing |
| F12 | Document admin-rejected | "[Doc] rejected: [reason]. Re-upload." | Show re-upload |
| F13 | EXIF data issues | Auto-strip EXIF | Silent fix |
| F14 | iOS HEIC format | Auto-convert to JPG | Silent fix |

## 14.4 Profile Validation Errors

| # | Scenario | User Message |
|---|----------|--------------|
| V1 | Required field missing | "This field is required" |
| V2 | Age < 18 (DOB validation) | "You must be 18+ to use Kafi" |
| V3 | Future DOB | "Invalid date of birth" |
| V4 | Invalid emergency contact phone | "Please enter a valid phone" |
| V5 | Bio over 300 chars | Counter shows "184 / 300" red |
| V6 | No language selected | "Select at least 1 language" |
| V7 | No emirate selected (nanny) | "Select at least 1 emirate" |
| V8 | Salary min > max | "Min salary must be less than max" |
| V9 | Salary unrealistic | "Salary seems too low/high. Confirm?" |
| V10 | No children added (after "Yes") | "Add at least 1 child age" |
| V11 | No work experience but says "experienced" | "Add at least 1 job" |
| V12 | Reference without details | "Complete reference details" |
| V13 | Trial daily rate is 0 | "Set a daily rate" |
| V14 | Trial duration is 0 | "Select trial duration" |
| V15 | Trial start date in past | "Start date must be future" |

## 14.5 Job & Application Errors

| # | Scenario | User Message | Action |
|---|----------|--------------|--------|
| J1 | Apply to closed job | "This job is no longer accepting applications" | Show similar jobs |
| J2 | Apply to expired job | "This job has expired" | Show similar jobs |
| J3 | Already applied | "You've already applied to this job" | Show status |
| J4 | Apply but not verified | "Complete profile verification first" | Show pending screen |
| J5 | Apply but profile incomplete | "Complete your profile to apply" | Show what's missing |
| J6 | Nanny on active trial | "You're on a trial. Apply after it ends." | Show trial info |
| J7 | Withdraw after viewed | "Application already viewed. Withdraw?" | Confirm |
| J8 | Family hits job post limit | Max **one active full-time + one active part-time**. Duplicate type: "You already have an active job of this type…". Both filled: close one in My Jobs first. | Show My Jobs / block Post CTA |
| J9 | Job post auto-expires | After 7 days → status: expired | Notify family |
| J10 | Cover message too long | "Max 300 characters" | Counter |

## 14.6 Trial Errors

| # | Scenario | User Message | Action |
|---|----------|--------------|--------|
| T1 | Send trial without subscription | "Subscribe to send trial offers" | Show pricing |
| T2 | Send trial to unverified nanny | "Nanny is being verified. Try later." | Block |
| T3 | Send trial when nanny on trial | "Nanny is currently on another trial" | Block / waitlist |
| T4 | Family with active trial | "Complete current trial first" | Show active trial |
| T5 | Counter offer pending | "Waiting for nanny response" | Show pending state |
| T6 | Nanny declined - no comeback | "Offer declined. Try another nanny." | Show similar nannies |
| T7 | Past start date passed | "Start date passed. Update or cancel." | Edit option |
| T8 | Trial started but no response | Auto-decline after 48h | Notify both |
| T9 | Mid-trial app deletion | Trial freezes, alert other party | Support intervention |
| T10 | Evaluation not filled | Allow "Hire" without eval (optional) | Soft warning |
| T11 | Payment dispute | "Report payment issue" → ticket | Support ticket |
| T12 | Trial extension request | Not supported - new trial required | Inform user |
| T13 | Cancel active trial | "Are you sure? Notify other party." | Confirmation |

## 14.7 Chat & Messaging Errors

| # | Scenario | User Message | Action |
|---|----------|--------------|--------|
| C1 | Message empty | Disable send button | - |
| C2 | Message too long (>1000 chars) | "Message too long" | Split |
| C3 | Send failed | "Failed to send. Tap to retry." | Retry per-message |
| C4 | Attachment too large | "Max 10 MB" | Compress |
| C5 | Recipient blocked you | "You can't message this user" | Hide chat |
| C6 | You blocked recipient | "Unblock to send" | Unblock option |
| C7 | User deleted account | "User no longer available" | Archive thread |
| C8 | Sharing phone number in chat | Auto-detect, show warning | Warning, not blocked |
| C9 | Spam content detected | "Message blocked: contains spam" | Block |
| C10 | Trial offer in expired job | "Job no longer active" | Block send |
| C11 | Family subscription expired - tap chat | "Renew subscription to access chats" | Show paywall |
| C12 | Family subscription expires while chat open | Auto-close chat, show paywall, preserve drafts | Paywall |
| C13 | Nanny sends to expired-sub family | Allow send (queued); show "Pending family renewal" status | Queue |
| C14 | Active trial chat (despite expired sub) | Chat remains accessible until trial ends | Bypass |
| C15 | Re-subscription mid-conversation | Chat reappears with latest messages | Sync |

## 14.8 Subscription & Payment Errors

| # | Scenario | User Message | Action |
|---|----------|--------------|--------|
| S1 | Payment declined | "Payment failed. Try another method." | Retry / change method |
| S2 | Free contacts exhausted | "You've used all 5 free views. Subscribe." | Show pricing |
| S3 | Subscription expired mid-action | "Subscription expired. Renew to continue." | Renew CTA |
| S4 | Restore purchases failed | "Couldn't restore. Try again." | Retry |
| S5 | RevenueCat sync delay | Show loading + auto-refresh | Wait 5s, retry |
| S6 | Plan unavailable in region | Show available plans only | Filter |
| S7 | Already subscribed | "You're already subscribed" | Show plan |
| S8 | App Store/Play Store down | "Service temporarily unavailable" | Retry later |
| S9 | Cancellation requires platform | "Cancel via App Store / Play Store settings" | Open settings |
| S10 | Refund request | Direct to App Store/Play Store policy | Show info |
| S11 | Subscription expired - opens chat list | Empty state + paywall "Renew to view your chats" | Pricing |
| S12 | Subscription expired - opens chat thread (deep link) | Full-screen paywall "Renew to access this chat" | Pricing / Back |
| S13 | Subscription expired - taps Call/WhatsApp | Hide buttons; show "Renew to contact" | Pricing |
| S14 | Subscription expired - taps nanny profile (full) | Blur phone; show "Renew for full access" | Pricing |
| S15 | Subscription expired but active trial exists | Allow trial chat/contact only; lock others | Trial bypass |
| S16 | Nanny tries to message expired-sub family | Allow send; system message: "Family's subscription expired - delivery delayed" | Send queued |
| S17 | Nanny opens chat to family whose sub expired | Show banner: "Family's subscription has expired" | Read-only side |
| S18 | Re-subscription after expiration | Restore chats, contacts; ⚡ PUSH: "Welcome back! Access restored" | Auto-restore |
| S19 | Cancellation within active period | Status: CANCELLED-IN-PERIOD; access until endDate | No immediate lockdown |
| S20 | Grace period (platform billing retry) | Show banner: "Renewal pending. Update payment to avoid losing access" | Update payment method |

## 14.9 Network & System Errors

| # | Scenario | User Message | Action |
|---|----------|--------------|--------|
| N1 | No internet | "No connection. Check your network." | Auto-retry on reconnect |
| N2 | Slow connection | Show loading skeleton | Cancel option after 30s |
| N3 | Firebase service down | "We're experiencing issues. Try again." | Show status |
| N4 | Cloud Function timeout | "Action took too long. Retry." | Retry |
| N5 | Firestore permission denied | "Access denied" | Logout if auth issue |
| N6 | Rate limited | "Too many requests. Wait a moment." | Cooldown |
| N7 | Maintenance mode | Full-screen "We'll be back soon" | - |
| N8 | App version too old | "Update Kafi to continue" | Open store |
| N9 | Device clock wrong | "Set device time correctly" | Block until fixed |
| N10 | Background sync failure | Silent retry, queue actions | Sync on resume |
| N11 | Push token refresh fail | Silent retry next session | - |

## 14.10 Free Tier / Restriction Errors

| # | Scenario | User Message | Action |
|---|----------|--------------|--------|
| FT1 | Try to view 6th profile | Show subscription paywall | Pricing |
| FT2 | Try to tap locked phone | Show subscription paywall | Pricing |
| FT3 | Try to send trial offer | "Subscribe to send trial offers" | Pricing |
| FT4 | Try to download CV | "Subscribe to download CVs" | Pricing |
| FT5 | Already viewed profile re-open | Free (counted) - no warning | - |
| FT6 | 1 free contact left | ⚡ PUSH: "1 free view remaining" | Soft warning |
| FT7 | 0 free contacts | Show in-app banner | Persistent CTA |
| FT8 | Post-expiration access to previously viewed | "Renew to view profiles again" | Pricing |
| FT9 | Post-expiration chat list access | Hide all chats; show paywall | Pricing |
| FT10 | Post-expiration deep link (push notif → chat) | Land on paywall; preserve target | Renew → resume |
| FT11 | Free contact counter on re-subscription | Counter NOT reset (full access regardless) | - |
| FT12 | Lockdown bypass attempt (security rules) | Firestore denies; client shows error | Logout/retry |

## 14.11 Admin Panel Errors

| # | Scenario | User Message | Action |
|---|----------|--------------|--------|
| AD1 | Non-admin tries to login | "Access denied" | Logout |
| AD2 | Document already reviewed | "Already reviewed by [Admin]" | Show review |
| AD3 | Reject without reason | "Provide rejection reason" | Required field |
| AD4 | Concurrent edit conflict | "Another admin edited this" | Refresh |
| AD5 | Broadcast send partial failure | "Sent to [X] of [Y] users" | Retry failed |
| AD6 | Export CSV too large | Process async, email link | Notification |
| AD7 | Delete user with active trial | "User has active trial. Confirm?" | Confirmation |
| AD8 | Admin session expired | Force re-login | Login screen |

## 14.12 Account Deletion Edge Cases

| # | Scenario | Action |
|---|----------|--------|
| D1 | Family with active subscription | Cancel via store first, then delete |
| D2 | Nanny on active trial | Block delete, complete trial first |
| D3 | Family with active trial | Block delete, complete trial first |
| D4 | Pending payments | Block delete, resolve first |
| D5 | Open chats | Archive instead of delete |
| D6 | Re-register same phone after delete | Allow after 30-day cooldown |
| D7 | Failed delete (partial) | Retry, notify admin |

## 14.13 Reporting & Safety

| # | Scenario | User Message | Action |
|---|----------|--------------|--------|
| R1 | Report inappropriate profile | "Thanks. We'll review within 24h." | Create report, notify admin |
| R2 | Report spam in chat | "Reported. We'll review." | Flag thread |
| R3 | Report fake document | Admin review queue | Hide profile pending review |
| R4 | Block user | "[User] blocked. They won't contact you." | Hide threads, applications |
| R5 | Unblock user | "Unblocked" | Restore visibility |
| R6 | Reported user takes action | Action recorded for admin review | Admin investigates |
| R7 | False reporting (3+ rejected) | "Your reports are under review" | Account warning |

### Report document (`disputes/{id}`) — filing payload

In-app **Report user** / **Report a problem** / payment-issue reports write to `disputes` (admin **Reports**). At file time the client denormalizes identity and optional evidence:

| Field | Notes |
|-------|--------|
| `reporterId`, `reportedUserId` | Auth UIDs (always) |
| `reporterName`, `reporterType` | `'family'` \| `'nanny'` |
| `reportedName`, `reportedType` | Best-effort from profile docs |
| `reporterSnapshot` / `reportedSnapshot` | Optional `{ phone?, city?, nationality?, status? }` captured at file time so admin retains context if the account is later deleted |
| `attachments` | Optional array (max **5**), each `{ id, url, storagePath, name, contentType, sizeBytes, uploadedAt }` — **images** and **PDF** only, **10 MB** each. Stored under `disputes/{disputeId}/attachments/{fileId}`. No video in v1 |
| `category`, `description`, `relatedTrialId?`, `status` | Existing fields |

Reported users never see the report in-app (My reports = reports **filed by** the current user). Admin report detail shows names, **user IDs**, snapshot fields, related trial link, and attachment gallery.

## 14.14 Content Moderation

| # | Scenario | Detection | Action |
|---|----------|-----------|--------|
| M1 | Phone number in chat | Auto-regex detection | Warning shown, not blocked |
| M2 | Phone number in nanny bio | Auto-detect on save | Block save with message |
| M3 | Profanity in bio | Word filter | Block save |
| M5 | Inappropriate video | Manual admin review | Block until reviewed |
| M6 | Personal info shared in video | Manual admin review | Reject + reason |
| M7 | Watermark on document | OK (passport scans) | Allow |
| M8 | Forged document detected | Admin flag | Reject + reason, possibly suspend |

## 14.15 Internationalization & Localization

| # | Scenario | Solution |
|---|----------|----------|
| I1 | Arabic UI support | RTL layout, Arabic translations |
| I2 | English UI (default) | LTR layout |
| I3 | Phone number format | libphonenumber validation |
| I4 | Date format | DD/MM/YYYY (UAE standard) |
| I5 | Time format | 12-hour with AM/PM |
| I6 | Currency | AED only |
| I7 | Timezone | Asia/Dubai (GMT+4) |
| I8 | Language detection | Auto-detect device locale |
| I9 | Manual language switch | Settings → Language |
| I10 | Mixed language input | Allowed |

## 14.16 Accessibility

| # | Scenario | Solution |
|---|----------|----------|
| Y1 | VoiceOver / TalkBack | Semantic labels on widgets |
| Y2 | Dynamic font size | Respect system text scaling |
| Y3 | High contrast | Test colors for WCAG AA |
| Y4 | Reduce motion | Disable animations when set |
| Y5 | Color blindness | Don't rely on color alone |
| Y6 | Tap target size | Min 44x44pt |

## 14.17 App Lifecycle

| # | Scenario | Action |
|---|----------|--------|
| L1 | App backgrounded mid-upload | Continue via background task |
| L2 | App backgrounded mid-chat | Mark unread on resume |
| L3 | App killed | Push notifications continue (FCM) |
| L4 | Cold start with deep link | Wait for auth, then navigate |
| L5 | Cold start while logged in | Auto-route to dashboard |
| L6 | Token expired in background | Refresh on resume |
| L7 | App update available | Soft prompt; force if critical |
| L8 | First launch | Show welcome flow |
| L9 | Re-install (same device) | Treat as new install |

## 14.18 Deep Links & Notification Navigation

| Notification Type | Deep Link Path | Auth Required |
|-------------------|----------------|---------------|
| New message | `/chat/{threadId}` | Yes |
| Trial offer | `/trial/{trialId}` | Yes |
| New application | `/applications/{appId}` | Yes |
| Documents approved | `/nanny/dashboard` | Yes |
| Profile viewed | `/nanny/dashboard` | Yes |
| Subscription expiring | `/pricing` | Yes |
| Broadcast | `/notifications` | Yes |
| If app not installed | Open store | - |
| If not authenticated | Login → resume to target | Auto-resume |

## 14.19 Search & Filter Edge Cases

| # | Scenario | Action |
|---|----------|--------|
| SR1 | Empty search results | "No nannies match. Adjust filters." |
| SR2 | All filters cleared | Show all verified nannies |
| SR3 | Invalid filter combo | Show "0 results" + suggest |
| SR4 | Slow query | Show skeleton loaders, paginated |
| SR5 | Search with special chars | Sanitize, treat as plain text |
| SR6 | Pagination failure | "Load more" retry button |
| SR7 | Sort by relevance (default) | Match score desc |

## 14.20 Data Privacy Requests

| # | Request | Action |
|---|---------|--------|
| GD1 | Export my data | Compile JSON, email link (7-day expiry) |
| GD2 | Delete my data | Standard account deletion |
| GD3 | Correct my data | Edit profile or contact support |
| GD4 | Stop processing | Mark inactive, hide profile |
| GD5 | Withdraw consent | Treat as data deletion |

## 14.21 Multi-Device & Session Edge Cases

| # | Scenario | Action |
|---|----------|--------|
| MD1 | Logged in on 2 devices | Both work, FCM tokens for both |
| MD2 | Logout from one device | Other device stays signed in |
| MD3 | Notification on both devices | Show on all, mark read syncs |
| MD4 | Action on device A reflects on B | Real-time Firestore listeners |
| MD5 | Phone number changed | Account update flow with OTP |
| MD6 | Lost phone | Login from another device after OTP |
| MD7 | Stale device session | 90-day auto logout |
| MD8 | Force logout from admin | Push command, clear local state |

## 14.22 Input & Form Edge Cases

| # | Scenario | Action |
|---|----------|--------|
| FE1 | Keyboard covers field | Auto-scroll into view |
| FE2 | Date picker future date for DOB | Block, show error |
| FE3 | Emergency contact = user phone | "Use a different number" |
| FE4 | Reference phone = user phone | Allowed (offline contact) |
| FE5 | Empty form submit | Highlight all required |
| FE6 | Special chars in name | Allow Unicode, restrict emoji |
| FE7 | Whitespace-only input | Trim, treat as empty |
| FE8 | Paste exceeds char limit | Truncate to limit |
| FE9 | Network during form submit | Save draft locally, retry |
| FE10 | Back button mid-form | Confirm discard changes |

## 14.23 Trial-Specific Edge Cases

| # | Scenario | Action |
|---|----------|--------|
| TX1 | Daily rate < 50 AED | Warning: "Unusually low rate" |
| TX2 | Daily rate > 1000 AED | Warning: "Unusually high rate" |
| TX3 | Trial start = today | Allowed, no countdown |
| TX4 | Trial overlaps another | Block both running |
| TX5 | Family deletes mid-trial | Trial frozen, notify nanny |
| TX6 | Nanny deletes mid-trial | Trial frozen, notify family |
| TX7 | Trial without job post | Allowed (direct hire) |
| TX8 | Evaluation incomplete | Allow hire decision anyway |
| TX9 | Counter offer counter | Not supported - single counter only |
| TX10 | Multiple trial offers to same nanny | Latest offer wins, prior cancelled |

## 14.24 Subscription-Specific Edge Cases

| # | Scenario | Action |
|---|----------|--------|
| SX1 | Upgrade weekly → monthly | Pro-rate via RevenueCat |
| SX2 | Downgrade monthly → weekly | At next renewal |
| SX3 | Subscription on iOS, login on Android | RevenueCat syncs across |
| SX4 | Family Sharing subscription (iOS) | Each user gets own access |
| SX5 | Promo code redemption | Via App Store / Play Store |
| SX6 | Free trial offer (future feature) | Trial period in RevenueCat |
| SX7 | Reactivate cancelled subscription | Within end date = no charge |
| SX8 | Sub expired but still using app | Treat as free tier |
| SX9 | Sub active but no internet | Cache last state, recheck on online |
| SX10 | RevenueCat webhook delayed | Show pending, recheck periodically |

## 14.25 Image & Video Edge Cases

| # | Scenario | Action |
|---|----------|--------|
| IM1 | Image fails to load (cached URL stale) | Auto-retry, fallback to placeholder |
| IM2 | Video buffering | Show buffering indicator |
| IM3 | Slow network video | Reduce quality automatically |
| IM4 | Video has audio issues | Show "Audio issue" warning |
| IM5 | Photo orientation wrong | Auto-fix using EXIF |
| IM6 | iOS HEIC | Auto-convert to JPG |
| IM7 | Photo has GPS data | Strip EXIF on upload |
| IM8 | Image cache full | Auto-evict LRU |
| IM9 | Replace photo with same name | Auto-rename with timestamp |
| IM10 | Bulk photo upload | Sequential, show progress |

## 14.26 Chat-Specific Edge Cases

| # | Scenario | Action |
|---|----------|--------|
| CX1 | Message out of order | Sort by createdAt timestamp |
| CX2 | Duplicate message (retry) | Idempotency key |
| CX3 | Edit message | Not supported - delete + resend |
| CX4 | Delete message | Soft delete, "Message deleted" |
| CX5 | Read receipt delay | Eventually consistent |
| CX6 | Typing indicator stuck | Auto-clear after 5s |
| CX7 | Push notification opens wrong chat | Use threadId, validate access |
| CX8 | Trial offer expired in chat | Show "Expired" state |
| CX9 | Counter offer in chat | Replace trial bubble |
| CX10 | Attachment download failure | Retry, show error state |

## 14.27 Admin Panel Specific Edge Cases

| # | Scenario | Action |
|---|----------|--------|
| AX1 | Admin logged out elsewhere | Auto-logout this session |
| AX2 | Two admins approve same doc | Last write wins, log both |
| AX3 | Bulk action on 1000+ users | Process in chunks, show progress |
| AX4 | Export with 10,000+ rows | Generate async, email link |
| AX5 | Slow Firestore query | Server-side index check, optimize |
| AX6 | Image preview fails | Show document icon fallback |
| AX7 | Video review buffering | Server transcoding queue |
| AX8 | Permission revoked mid-session | Block save action, show message |
| AX9 | Browser closed during broadcast | Resume on next session |
| AX10 | Date filter beyond data | Show "No data in this range" |

## 14.28 Recovery & Resume Scenarios

| # | Scenario | Action |
|---|----------|--------|
| RC1 | Abandoned nanny onboarding | Resume from last completed step |
| RC2 | Abandoned family registration | Resume on Job Post Form until ≥1 job exists; cannot open Browse |
| RC3 | Abandoned trial offer creation | Save draft locally, prompt on return |
| RC4 | Abandoned first job post | Keep family on Screen 13 (Job Post Form) on relaunch/resume until a job is posted; back navigation does not escape to Browse |
| RC5 | App crash mid-flow | Restore from last save point |
| RC6 | Battery dies mid-upload | Resume upload on next session |
| RC7 | Lost connection mid-chat | Queue messages, send on reconnect |
| RC8 | Re-install with same account | Restore from cloud Firestore |
| RC9 | Logged out during action | Save action, re-execute post-login |
| RC10 | Force-quit during payment | Verify with RevenueCat on relaunch |

---

# 15. PERMISSION HANDLING MATRIX

## 15.1 Permission Decision Table

| Action | Permission Needed | Required? | Skippable? |
|--------|-------------------|-----------|------------|
| OTP via SMS | Notification (post-Android 13) | No (works via SMS) | Yes |
| Photo upload | Camera OR Photo Library | Yes for photos | No |
| Video record | Camera + Microphone | Yes for recording | No (can upload) |
| Document scan | Camera | Yes if scanning | Yes (file upload alt) |
| Document upload | Photo Library OR Files | Yes | No |
| Profile area pre-fill | Location | No | Yes |
| Browse default emirate | Location | No | Yes |
| Receive push | Notification | No | Yes |
| Chat attachments | Photo Library | No | Yes |
| Phone calls | None (uses URL launcher) | - | - |
| WhatsApp | None (uses URL launcher) | - | - |

## 15.2 Permission Request Timing

```
First Launch
    │
    ├─→ Welcome (no permissions)
    │
    ├─→ OTP Verified
    │     └─→ Request: Notification (with rationale)
    │
    ├─→ Nanny Step 2 (Media)
    │     └─→ On "Add Photo" tap: Camera + Photo Library
    │     └─→ On "Record Video" tap: Camera + Microphone
    │
    ├─→ Nanny Step 5 (Documents)
    │     └─→ On "Upload" tap: Photo Library + Files
    │
    └─→ Browse (Family)
          └─→ On first open: Location (optional, with skip)
```

## 15.3 Permission Recovery Strategies

| Strategy | When |
|----------|------|
| Pre-request education screen | Before sensitive permissions |
| Just-in-time rationale | After first denial |
| Settings deep link | After permanent denial |
| Alternative flow | When permission is optional |
| Manual fallback | E.g., manual emirate selection |
| Periodic re-prompt | Once per session for declined essentials |

## 15.4 OS-Specific Notes

### iOS
- Photos: Limited library access (iOS 14+) - handle partial selection
- Notifications: Use provisional auth for non-critical
- App Tracking Transparency: Required if any tracking

### Android
- Storage: Use scoped storage (Android 10+)
- Photos: New `READ_MEDIA_IMAGES` permission (Android 13+)
- Notifications: Runtime permission (Android 13+)
- Background location: Discouraged, not used

---

# RELATED DOCUMENTS

| Document | Purpose |
|----------|---------|
| `KAFI_APP_DOCUMENTATION.md` | Initial screen-by-screen breakdown |
| `KAFI_SYSTEM_SPECIFICATION.md` (this) | Complete system specification |
| `KAFI_TECHNICAL_ARCHITECTURE.md` | GetX controllers, services, Firebase architecture, permissions, FCM, admin panel |

---

## Implementation History

| Date (YYYY-MM-DD) | Task | Status | Summary |
|-------------------|------|--------|---------|
| 2026-05-19 | Phase 0 scaffold | Done | Created `kafi_app/`, `admin-panel/`, `functions/`; Flutter mock mode, service interfaces, core models, placeholder auth→role home |
| 2026-05-19 | Auth UI foundation v8 | Done | Phone→OTP→password auth wired in AuthController; role_select removed; mock OTP 1234 |
| 2026-05-19 | Restart Task 1 — auth flow | Done | AuthConstants + mock OTP; IAuthService/MockAuthService; 4-digit OTP verify per §Authentication |
| 2026-05-19 | Task 2 — Nanny onboarding | Done | NannyModel + sub-models; NannyConstants (5 photos, 60s video, score bonuses); submit→pending flow; profile score calc |
| 2026-05-19 | Task 3 — Family flow | Done | FamilyModel, JobPostModel, TrialModel, ChatModels, SubscriptionPlan; free-view limits; subscription lockdown rules (expired hides chat except active-trial threads) |
| 2026-05-19 | Task 4 — Admin + Functions | Done | Admin: sidebar routes per §12; Cloud Functions: Firestore triggers (chat, trial, nanny docs), scheduled (trial reminder, subscription enforce), RevenueCat webhook for state sync |
| 2026-05-19 | Full Spec Compliance Pass | Done | Updated all models (User, Nanny, Family, JobPost, Trial, Chat, Application) to match §3.1-3.10; added country codes per §1.5; implemented MatchService per §9; verified subscription lockdown per §11; all fields, enums, and structures now spec-compliant |
| 2026-05-19 | Trial Offer Flow Completion | Done | Implemented §6.5 trial actions in app services/controllers: send offer, accept/decline/counter transitions, chat trial_offer/trial response message types, and thread trial linkage used by subscription-lockdown exceptions |
| 2026-05-19 | Audit gap closure (end-to-end) | Done | §3.6 trial lifecycle expanded: cancel (pre-start), nanny payment confirmation, nanny payment-issue report, outcome (hire/pass) persisted with evaluation; §6.7 smart-match scoring implemented as deterministic 5-criteria scorer (language 25 / experience 20 / role 20 / visa 15 / salary 20); §8.4 VAT (5%) now itemised on pricing screen; §18 lockdown bypass surfaced as banner on locked profile when trial active; §21 inactivity policy enforced (90-day auto-logout) |
| 2026-05-19 | Reaudit fix-pass (12 areas) | Done | §3.6 trial: `isActive` strictly limited to ACTIVE status; new `acceptCounter`/`declineCounter` paths; `ChatThread.trialStatus` cached so bypass only fires on ACTIVE trials. §6.4 lockdown: grace state keeps access; expired-only triggers lockdown; profile re-lock UX for previously-viewed nannies. §6.5: family-side counter response added. §6.7: nanny edit-profile (bio/languages/emergency/comfort) per spec §6.7. §8.3 RevenueCat: enum aligned to `paymentFailed`; `PRODUCT_CHANGE` handled; shared-secret auth on webhook. §10.2: `onTrialEnded` recomputes `activeTrialNannyIds`. §12.3: broadcast FCM dispatcher writes `deliveryStats`. §6.9: user-delete cascade across chats/trials/applications. §3.1: duplicate `UserSettings` removed; dot-notation Firestore writes prevent settings wipe; viewedProfiles transactional dedupe. |
| 2026-05-19 | Permissions, handlers & location picker | Done | §5 (permissions): `PermissionService` implemented with real `permission_handler` (camera/photos/mic/location/notification/contacts); all upload entry-points gated. §4.2 OTP: verify blocked and button disabled when timer expired. §6.5 trial: duplicate offer rejected if pending/countered/accepted/active trial already exists for same nanny. §6.3 chat: `markAsRead` wired from `openThread`; `IChatService.markThreadRead` added in interface + both impls; unread count synced to Firestore. Profile score recalculated after `saveProfileDraft`. §6.4 browse: free-view exhaustion shows snackbar before pricing redirect; "X views remaining" shown at 1–2 left. §1.5 UAE locations: `KafiLocationPicker` widget (emirate + area two-column sheet) wired to nanny current-area, trial offer location, and new family city field. |
| 2026-05-19 | Audit round 2 fixes | Done | §6.3–6.6 chat/trial/subscription gaps closed; §6.9 delete cascade uses `chatThreads`; admin doc review patches embedded array; Cloud Functions FCM from `users`, webhook secret required, scheduled reminders idempotent, token prune on send failure. |
| 2026-05-19 | Broken flows + bug bash | Done | §3.6 trial response: thread lookup uses **user id** (was nanny card id); `CounterOffer` (`dailyRate` + `startDate`) now applied via `applyCounterAndAccept`; `ChatThread.trialStatus` persisted in mock + Firestore + seed; bypass logic re-checks status. §4.2 auth: `verifyPasswordResetOtp` (interface + mock + Firebase); OTP screen no longer navigates on send failure; returning users keep `hasPassword`. §6.3 chat: deep-linking via `nannyId` or `threadId` (notification + shortlist); `openThreadForNanny` finds/creates thread; expired families see threads but `openThread` still routes to pricing. §6.4 lockdown: expired family browse list visible; previously-viewed routes to Profile Re-Locked; grace banner across non-browse family shell tabs. §6.5 trial bubble: reactive on `TrialController.all`; only renders Accept/Counter while pending. §6.7 nanny edit: hydrates **all** fields (DOB, nationality, languages, visa, emirates, current area, marital, children, health/meds/allergies, comfort, religion, emergency contact, bio). §6.9 cascade: `onUserDeleted` extended to delete shortlists, jobs, notifications, reviews (both authored + about-user), and family-side applications; `firebase_auth_service.deleteAccount` deletes the user doc to trigger the cascade and writes a `deletionAudits` record. §12.3 FCM: `onMessage` + `onMessageOpenedApp` + `getInitialMessage` + `onTokenRefresh`; token re-registered on every user change. §21 session: `SessionMonitor` clears `AuthController.currentUser` on expiry. Notification model robust to Firestore Timestamps and partial payloads. New family profile edit (Screen 27B). |
| 2026-05-19 | P2 audit fixes | Done | §5.3 disputes: `IDisputeService` + mock + Firestore service created; `disputes/{id}` written when family/nanny calls `reportPaymentIssue` — category `payment`, relatedTrialId linked; admin `DisputeService.list` + `resolve` already wired. §6.9 cascade now deletes Firebase Storage files under `users/{uid}/`, `nannies/{uid}/`, `families/{uid}/` on user deletion (best-effort). `firestore.indexes.json` extended with all Firestore query composite indexes (applications/jobPostId, chatThreads/familyId+nannyId, notifications/userId+read, disputes/reporterId, shortlists compound, jobs/status+city, subscriptions/status+endDate, trials/status+startDate+reminderSent, nannies/status+introVideoStatus). Video review now separate from profile approval — `NannyRow.introVideoStatus` field; `NannyService.reviewVideo()` patches `introVideoStatus` only. |

---

*Document Version: 1.7*
*Last Updated: May 19, 2026*
*Errors: 27 categories, 250+ scenarios documented*
*Comparison Status: Verified against HTML mockup (kafi-platform-v8-final.html)*
| 2026-07-17 | Native media and location permissions | Done | Photo capture requires Camera; photo gallery requires Images/Photos; video capture requires Camera + Microphone; video gallery requires Videos/Photos; location picker requires when-in-use location. Android 12− storage fallback, Android 13+ granular image/video access, Android 14 selected-media access, and iOS limited Photos access are supported. |

| 2026-07-31 | Family first-job onboarding gate | Done | Families with no job posts stay on Screen 13 / familyForm on relaunch and resume; back, Browse/home, and notification deep links cannot escape until ≥1 job exists |

| 2026-07-17 | Media screen photo/video preview | Done | Nanny media step (§3.2) now correctly previews selected photos (cover + thumbs) and intro video after pick/record in mock and live modes. |

| 2026-07-31 | Post-job location/schedule/FT-PT + browse bugs | Done | JobPost workDays + employmentType cap (J8); family form + Browse CTA; shortlist create rules; browse myJobs refresh |
| 2026-07-31 | Watch intro video playback | Done | Intro video perk playback resolves Storage/`gs://` refs to download URLs so Screen 16 Watch intro video can play |
| 2026-07-31 | Select Location iOS crash + map picker | Done | Shared `KafiLocationPicker` (Google map when key present) remains the location UX for family job, trial, About You, experience, refs; iOS sheet text-menu crash fixed |
| 2026-07-31 | Trial offer form validations | Done | §14.4 V13–V15 + §14.6 T1–T4 + TX1–TX2 enforced on Screen 31 send via `validateTrialOffer` / `Validators.trialDailyRate` / `trialStartDate` |
| 2026-07-31 | Chat send permission-denied | Done | Client message writes match §6.3 thread party + rules sender identity; mock-sub entitlement sync required for family creates when `useMockSubscription` |
| 2026-07-31 | Browse home missing nannies | Done | §14 SR2 — All filter clears to full verified catalogue; browse query no longer truncates at 50 |
| 2026-07-31 | Chat conversation single loader | Done | Screen 17 conversation list uses one loader while opening; no per-message trial spinners |
| 2026-07-31 | Trial screen empty while in progress | Done | Screen 19 shows accepted/active trial from chat View trial; permanent controller no longer ignores trialId args |
| 2026-07-31 | Ticket status stale after admin resolve | Done | Mobile support tickets reflect admin resolved/closed via live ticket doc watch |
| 2026-07-31 | Admin Reports (not Disputes) + hide IDs | Done | Admin Safety “Disputes” label removed — Reports queue only (`disputes` collection unchanged); no IDs in report UI |
| 2026-07-31 | Mobile reports vs support listings | Done | §14.13 report-user / report-problem → `disputes` + My reports; Contact Support → `tickets` only |
| 2026-07-31 | Nanny chat report flag | Done | Chat report counterparty from thread membership (not stale role); sheet above shell nav |
| 2026-07-31 | Admin badges + iOS push + notif deep-links | Done | Admin nav badges hidden at 0; iOS remote push configured; push/inbox taps deep-link to counterpart detail |
| 2026-08-03 | Trial checklist sync both parties | Done | §6.5 during-trial evaluation checklist persisted live so both parties see the same ticks |
| 2026-08-03 | Profile quality remaining gaps | Done | Mobile score uses ProfileQualityScore factors (§3.2); dashboard surfaces remaining recommendations |
| 2026-08-03 | Admin panel + push/inbox notification locale rule | Done | Admin locale is a client-only per-browser preference (`localStorage`, no server persistence) toggled EN\|AR from Settings — all admin data-entity enum values (subscription status/plan, nanny/document/intro-video status, trial/dispute/ticket status, opener/reporter type) are resolved to display labels through a single mapping layer rather than rendered as raw Firestore field values. Push/inbox notification locale resolves from the recipient's `users/{uid}` doc field `locale` \| `preferredLanguage` \| `language` \| `settings.language` (first present, default `en`); the one-time admin-bootstrap HTTP endpoint instead resolves locale from the request's `Accept-Language` header since no user doc exists yet. |
| 2026-08-03 | Full i18n verification (3 clean cycles) | Done | Mobile UI + AppError messages localized; admin EN/AR via t(); push/inbox templates locale-aware (en/ar) with 3 consecutive clean verification cycles |
| 2026-08-06 | Nanny trial offer Accept/Decline | Done | Nanny pending trial offer UI exposes accept/decline/counter per §6 trial response flow |
| 2026-08-06 | Nanny jobs live feed | Done | Active job discovery for nannies is a live feed of `status=active` posts |
| 2026-08-06 | Family browse live feed | Done | Family discovery is a live feed of `status=approved` + `isVerified=true` nannies (filter pills preserved) |
| 2026-08-06 | Cancelled trial clears chat active badge | Done | Cancel/decline flips `chatThreads.trialStatus`; `onTrialEnded` syncs thread status so both parties drop active-trial UI |
| 2026-08-06 | Family counter Accept/Decline in chat | Done | §6.5 family reviews counter — Accept/Decline visible in chat when status is countered or message is trialCountered |
| 2026-08-06 | Hide chat trial bar when trial ends | Done | Chat trial indicators only while accepted/active and payment not confirmed (§6.5 / §6.6) |
| 2026-08-06 | Family applicants live inbox | Done | Family Applicants is a live feed of applications for the family; apply requires job.familyId |
| 2026-08-06 | Admin Verify docs badge stale | Done | Admin sidebar pending-docs badge refreshes with queue (route change + post approve/reject) |
| 2026-08-06 | Admin↔user report/ticket realtime | Done | Report resolve + support chat live for family and nanny (dispute/ticket doc + messages snapshots; admin detail panes subscribe) |
| 2026-08-06 | Family Applicants multi-job inbox | Done | Family Applicants lists applications for all of a family's job posts; onNewApplication maintains job applicant counts + familyId |
| 2026-08-06 | Trial offer gate after end | Done | §14.6 T3/T4 / duplicate-offer: ended trials (payment confirmed, payment issue reported, cancelled) do not block a new offer |
| 2026-08-06 | Rate app after payment confirm | Done | Screen 19 Confirm payment available to family; triggers throttled rate-the-app dialog |

| 2026-08-06 | Trial offer chat bubble details | Done | §3.7 TrialOfferBubble expanded: duration, rate, total, starting from, type, location, notes for both parties; ensureTrialInList when nanny list misses the offer |

| 2026-08-06 | Applicants job filter names | Done | Family Applicants filters show job names not Firestore job ids |

| 2026-08-06 | Messages bottom-nav badge | Done | §6.6: shell Messages tab badge for new unread; cleared on opening chat list |

| 2026-08-06 | Report user info + attachments | Done | §14.13: disputes denormalize reporter/reported names, types, snapshot + optional image/PDF attachments (max 5×10MB); admin Reports shows IDs, snapshot, trial link, attachment gallery; Storage path disputes/{id}/attachments |

| 2026-08-06 | Hide inactive nannies listing | Done | `SystemSettings.hideInactiveNannies`: family Browse excludes nannies without recent `lastActiveAt` (14 days); null stamp treated as inactive |

| 2026-08-06 | Report attach storage auth | Done | Dispute create→upload→attachments patch; Storage signed-in read for evidence URLs |

| 2026-08-06 | Admin reports + last active | Done | Admin Reports show IDs + attachment gallery; nanny lastActiveAt surfaced for hide-inactive toggle |
