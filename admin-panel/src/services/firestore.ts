import {
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  Timestamp,
  updateDoc,
  where,
  serverTimestamp,
  setDoc,
  addDoc,
} from 'firebase/firestore';
import { db } from '../config/firebase';
import { AppConfig } from '../config/app';

const useMock = () => AppConfig.useMock || !db;

// ─────────────────────────────────────────────────────────
// Types (loose to keep cross-cutting code small)
// ─────────────────────────────────────────────────────────
// Enums mirrored from the Flutter app (`lib/models/nanny_model.dart`)
export type VisaStatus = 'visit' | 'residenceSponsored' | 'ownResidence' | 'cancelled' | 'outsideUae';
export type AvailabilityStatus = 'availableNow' | 'availableFrom' | 'onTrial';
export type JobTypePreference = 'liveIn' | 'liveOut' | 'both';
export type MaritalStatus = 'married' | 'single' | 'divorced' | 'widowed';
export type Emirate = 'dubai' | 'abuDhabi' | 'sharjah' | 'ajman' | 'rak' | 'fujairah' | 'uaq' | 'alAin';

export interface WorkExperienceRow {
  id?: string;
  jobTitle: string;
  employer: string;
  cityCountry: string;
  fromDate?: string;
  toDate?: string;
  children?: string;
  duties?: string;
  reasonLeaving?: string;
}

export interface ReferenceContactRow {
  id?: string;
  relationship: string;
  city: string;
  yearsWorked?: number;
  canConfirm?: string;
}

export interface NannyStatsRow {
  profileViews?: number;
  shortlists?: number;
  applicationsCount?: number;
  trialsCount?: number;
  hiresCount?: number;
  averageRating?: number;
  reviewsCount?: number;
}

export interface NannyRow {
  id: string;
  /** When the profile was submitted (used for date filtering). */
  createdAt?: Date;
  // ── Identity & demographics ──
  fullName: string;
  nationality: string;
  city: string;
  /** Free-text current area within the city */
  currentArea?: string;
  dateOfBirth?: string;
  age?: number;
  experienceYears?: number;
  // ── Languages ──
  languages?: string[];
  // ── Visa & Emirates ID ──
  visaStatus?: VisaStatus;
  hasEmiratesId?: boolean;
  eidNumber?: string;
  willingToTransferVisa?: boolean;
  // ── Work location & availability ──
  workEmirates?: Emirate[];
  willingToRelocate?: boolean;
  availability?: AvailabilityStatus;
  availableFrom?: string;
  // ── Job preferences & compensation ──
  jobTypePreference?: JobTypePreference;
  expectedSalaryMin?: number;
  expectedSalaryMax?: number;
  // ── Personal & family status ──
  maritalStatus?: MaritalStatus;
  hasChildren?: boolean;
  childrenCount?: number;
  childrenAges?: string;
  // ── Health ──
  hasHealthConditions?: boolean;
  healthConditions?: string;
  takesMedication?: boolean;
  medications?: string;
  hasAllergies?: boolean;
  allergies?: string;
  // ── Comfort & household preferences ──
  comfortableWithCameras?: boolean;
  cameraNote?: string;
  comfortableWithPets?: boolean;
  petTypes?: string[];
  canCook?: boolean;
  cuisines?: string[];
  canDoNightShifts?: boolean;
  // ── Religion & cultural ──
  religion?: string;
  religiousNotes?: string;
  comfortableWithDifferentFaith?: boolean;
  // ── Emergency contact ──
  emergencyName?: string;
  emergencyRelationship?: string;
  emergencyPhone?: string;
  // ── Profile & media ──
  bio?: string;
  photoUrls?: string[];
  introVideoUrl?: string;
  /** 'pending' | 'approved' | 'rejected' — separate from overall profile status */
  introVideoStatus?: 'pending' | 'approved' | 'rejected';
  introVideoRejectionReason?: string;
  // ── Professional history & references ──
  experiences?: WorkExperienceRow[];
  hasReferences?: boolean;
  numberOfReferences?: number;
  references?: ReferenceContactRow[];
  // ── Verification & documents ──
  status: 'draft' | 'pending' | 'approved' | 'rejected';
  isVerified: boolean;
  blocked?: boolean;
  profileScore?: number;
  documents?: { type: string; status: string; url?: string; rejectionReason?: string }[];
  // ── Engagement stats ──
  stats?: NannyStatsRow;
}

export type NannyReligionPreference = 'noPreference' | 'preferMuslim' | 'preferSame' | 'openWithRespect';

export interface FamilyStatsRow {
  jobPostsCount?: number;
  activeJobPosts?: number;
  totalApplicationsReceived?: number;
  trialsCount?: number;
  hiresCount?: number;
}

export interface FamilyRow {
  id: string;
  /** When the account was created (used for "new today" stats). */
  createdAt?: Date;
  fullName: string;
  nationality: string;
  city: string;
  profilePhoto?: string;
  blocked?: boolean;
  // ── Household / children ──
  childrenCount?: number;
  childrenAges?: string[];
  hasSpecialNeedsChild?: boolean;
  specialNeedsDetails?: string;
  languagesAtHome?: string[];
  hasCameras?: boolean;
  hasPets?: boolean;
  petTypes?: string[];
  // ── Religion & culture ──
  religion?: string;
  nannyReligionPreference?: NannyReligionPreference;
  houseRules?: string;
  aboutFamily?: string;
  // ── Subscription & usage ──
  subscription: {
    status: 'free' | 'active' | 'cancelled' | 'expired' | 'paymentFailed';
    plan?: string;
    startDate?: Date;
    endDate?: Date;
    autoRenew?: boolean;
    hasEverSubscribed?: boolean;
  };
  freeContactsUsed?: number;
  activeTrialNannyIds?: string[];
  stats?: FamilyStatsRow;
}

// ── Job posts (job creation flow) ──
export type JobPostStatus = 'active' | 'paused' | 'closed' | 'expired';
export type JobType = 'liveIn' | 'liveOut';
export type JobDuration = 'permanent' | 'contract';
export type VisaSponsorship = 'full' | 'shared' | 'residenceOnly' | 'none';

export interface JobPostRow {
  id: string;
  familyId: string;
  familyName?: string;
  status: JobPostStatus;
  createdAt?: Date;
  expiresAt?: Date;
  jobTitle?: string;
  rolesNeeded?: string[];
  jobType?: JobType;
  schedule?: string;
  startDate?: Date;
  startImmediate?: boolean;
  duration?: JobDuration;
  contractMonths?: number;
  experienceYears?: number;
  languagesRequired?: string[];
  languagesPreferred?: string[];
  skillsRequired?: string[];
  nationalityPreference?: string[];
  religionPreference?: NannyReligionPreference;
  duties?: string[];
  salaryMin?: number;
  salaryMax?: number;
  currency?: string;
  benefits?: string[];
  visaSponsorship?: VisaSponsorship;
  trialDurationDays?: number;
  trialDailyRate?: number;
  additionalNotes?: string;
  viewsCount?: number;
  applicationsCount?: number;
  city?: string;
}

// ── Applications / offers ──
export type ApplicationStatus =
  | 'pending'
  | 'viewed'
  | 'shortlisted'
  | 'trialOffered'
  | 'declined'
  | 'withdrawn'
  | 'hired';

export interface ApplicationRow {
  id: string;
  jobPostId: string;
  jobTitle?: string;
  nannyId: string;
  nannyName?: string;
  familyId: string;
  familyName?: string;
  status: ApplicationStatus;
  matchScore?: number;
  coverMessage?: string;
  createdAt: Date;
  respondedAt?: Date;
}

// ── Reviews / ratings ──
export interface ReviewRow {
  id: string;
  reviewerId: string;
  reviewerName?: string;
  reviewerType: 'family' | 'nanny';
  revieweeId: string;
  revieweeType: 'family' | 'nanny';
  trialId?: string;
  rating: number; // 1-5
  comment?: string;
  createdAt: Date;
}

// ── Chat threads & messages (nanny ↔ family) ──
export type ChatMessageType = 'text' | 'image' | 'trialOffer' | 'trialAccepted' | 'trialDeclined' | 'trialCountered' | 'system';

export interface ChatMessageRow {
  id: string;
  threadId: string;
  senderId: string;
  senderType: 'nanny' | 'family';
  content: string;
  type?: ChatMessageType;
  attachments?: { type: string; url: string; name: string }[];
  trialOfferId?: string;
  createdAt: Date;
  readAt?: Date;
}

export interface ChatThreadRow {
  id: string;
  familyId: string;
  nannyId: string;
  familyName?: string;
  nannyName?: string;
  createdAt: Date;
  lastMessageAt: Date;
  lastMessage?: string;
  trialId?: string;
  trialStatus?: string;
  status?: 'active' | 'archived';
}

export interface DisputeRow {
  id: string;
  reporterId: string;
  reporterName?: string;
  reporterType?: 'family' | 'nanny';
  reportedUserId: string;
  reportedName?: string;
  category: 'fraud' | 'abuse' | 'no_show' | 'payment' | 'other';
  description: string;
  status: 'open' | 'investigating' | 'resolved' | 'dismissed';
  relatedTrialId?: string;
  resolution?: string;
  createdAt: Date;
}

// Support chat between admin and the reporting user, scoped to a dispute.
export interface DisputeMessageRow {
  id: string;
  disputeId: string;
  senderType: 'admin' | 'user';
  senderName?: string;
  content: string;
  createdAt: Date;
}

// ─────────────────────────────────────────────────────────
// Mock data (used when AppConfig.useMock or no db)
// ─────────────────────────────────────────────────────────
const mockNannies: NannyRow[] = [
  {
    id: 'n1', fullName: 'Sarah Reyes', nationality: 'Filipino', city: 'Dubai', currentArea: 'Dubai Marina',
    createdAt: new Date(Date.now() - 40 * 86400000),
    dateOfBirth: '1992-04-18', age: 34, experienceYears: 5,
    languages: ['English', 'Tagalog', 'Arabic (basic)'],
    visaStatus: 'residenceSponsored', hasEmiratesId: true, eidNumber: '784-1992-1234567-1', willingToTransferVisa: true,
    workEmirates: ['dubai', 'sharjah'], willingToRelocate: false, availability: 'availableNow',
    jobTypePreference: 'liveIn', expectedSalaryMin: 2500, expectedSalaryMax: 3500,
    maritalStatus: 'married', hasChildren: true, childrenCount: 2, childrenAges: '6 and 9 (in Philippines)',
    hasHealthConditions: false, takesMedication: false, hasAllergies: false,
    comfortableWithCameras: true, comfortableWithPets: true, petTypes: ['Cats', 'Small dogs'],
    canCook: true, cuisines: ['Filipino', 'Western', 'Arabic'], canDoNightShifts: true,
    religion: 'Christian', comfortableWithDifferentFaith: true,
    emergencyName: 'Jose Reyes', emergencyRelationship: 'Spouse / Partner', emergencyPhone: '+971 50 123 4567',
    bio: 'Warm and experienced nanny with 5 years caring for newborns and toddlers in Dubai. First-aid certified.',
    photoUrls: [
      'https://randomuser.me/api/portraits/women/68.jpg',
      'https://randomuser.me/api/portraits/women/65.jpg',
    ],
    introVideoUrl: 'https://example.com/n1.mp4', introVideoStatus: 'approved',
    experiences: [
      { id: 'e1', jobTitle: 'Live-in Nanny', employer: 'Al Futtaim Family', cityCountry: 'Dubai, UAE', fromDate: '2021-03-01', toDate: '2024-12-01', children: '2 (ages 1 & 4)', duties: 'Full childcare, school runs, light cooking', reasonLeaving: 'Family relocated' },
      { id: 'e2', jobTitle: 'Newborn Specialist', employer: 'Singh Family', cityCountry: 'Manila, Philippines', fromDate: '2019-01-01', toDate: '2021-02-01', children: '1 newborn', duties: 'Newborn care, night feeds', reasonLeaving: 'Contract ended' },
    ],
    hasReferences: true, numberOfReferences: 2,
    references: [
      { id: 'r1', relationship: 'Previous employer', city: 'Dubai', yearsWorked: 3, canConfirm: 'Reliability, childcare skills, honesty' },
      { id: 'r2', relationship: 'Agency supervisor', city: 'Manila', yearsWorked: 2, canConfirm: 'Professional conduct and training' },
    ],
    status: 'approved', isVerified: true, profileScore: 94,
    documents: [
      { type: 'passport', status: 'approved', url: 'https://picsum.photos/seed/n1passport/640/420' },
      { type: 'visa', status: 'approved', url: 'https://picsum.photos/seed/n1visa/640/420' },
      { type: 'emiratesId', status: 'approved', url: 'https://picsum.photos/seed/n1eid/640/420' },
      { type: 'trainingCert', status: 'approved', url: 'https://picsum.photos/seed/n1cert/640/420' },
      { type: 'policeClearance', status: 'approved', url: 'https://picsum.photos/seed/n1police/640/420' },
    ],
    stats: { profileViews: 412, shortlists: 38, applicationsCount: 12, trialsCount: 4, hiresCount: 2, averageRating: 4.8, reviewsCount: 6 },
  },
  {
    id: 'n2', fullName: 'Priya Sharma', nationality: 'Indian', city: 'Abu Dhabi', currentArea: 'Khalidiya',
    createdAt: new Date(Date.now() - 18 * 86400000),
    dateOfBirth: '1995-09-02', age: 30, experienceYears: 3,
    languages: ['English', 'Hindi', 'Urdu'],
    visaStatus: 'ownResidence', hasEmiratesId: true, willingToTransferVisa: false,
    workEmirates: ['abuDhabi', 'alAin'], willingToRelocate: true, availability: 'availableFrom', availableFrom: new Date(Date.now() + 14 * 86400000).toISOString(),
    jobTypePreference: 'both', expectedSalaryMin: 2200, expectedSalaryMax: 3000,
    maritalStatus: 'single', hasChildren: false, childrenCount: 0,
    hasHealthConditions: false, takesMedication: false, hasAllergies: true, allergies: 'Mild peanut allergy',
    comfortableWithCameras: true, comfortableWithPets: false,
    canCook: true, cuisines: ['Indian', 'Continental'], canDoNightShifts: false,
    religion: 'Hindu', comfortableWithDifferentFaith: true,
    emergencyName: 'Anita Sharma', emergencyRelationship: 'Parent', emergencyPhone: '+971 55 987 6543',
    bio: 'Patient and organised nanny who loves early-learning activities and meal prep for kids.',
    photoUrls: ['https://randomuser.me/api/portraits/women/44.jpg'],
    experiences: [
      { id: 'e1', jobTitle: 'Live-out Nanny', employer: 'Hassan Family', cityCountry: 'Abu Dhabi, UAE', fromDate: '2022-06-01', toDate: '2025-01-01', children: '2 (ages 3 & 5)', duties: 'After-school care, homework, meals', reasonLeaving: 'Children grew up' },
    ],
    hasReferences: true, numberOfReferences: 1,
    references: [
      { id: 'r1', relationship: 'Previous employer', city: 'Abu Dhabi', yearsWorked: 3, canConfirm: 'Punctuality and care quality' },
    ],
    status: 'approved', isVerified: true, profileScore: 82,
    documents: [
      { type: 'passport', status: 'approved', url: 'https://picsum.photos/seed/n2passport/640/420' },
      { type: 'visa', status: 'approved', url: 'https://picsum.photos/seed/n2visa/640/420' },
      { type: 'emiratesId', status: 'approved', url: 'https://picsum.photos/seed/n2eid/640/420' },
    ],
    stats: { profileViews: 287, shortlists: 21, applicationsCount: 8, trialsCount: 2, hiresCount: 1, averageRating: 4.6, reviewsCount: 3 },
  },
  {
    id: 'n3', fullName: 'Amara Kebede', nationality: 'Ethiopian', city: 'Sharjah', currentArea: 'Al Nahda',
    createdAt: new Date(Date.now() - 6 * 86400000),
    dateOfBirth: '1990-11-25', age: 35, experienceYears: 2,
    languages: ['English', 'Amharic', 'Arabic (basic)'],
    visaStatus: 'cancelled', hasEmiratesId: false, willingToTransferVisa: true,
    workEmirates: ['sharjah', 'dubai', 'ajman'], willingToRelocate: true, availability: 'availableNow',
    jobTypePreference: 'liveIn', expectedSalaryMin: 1800, expectedSalaryMax: 2400,
    maritalStatus: 'divorced', hasChildren: true, childrenCount: 1, childrenAges: '11 (in Ethiopia)',
    hasHealthConditions: true, healthConditions: 'Managed asthma (inhaler)', takesMedication: true, medications: 'Salbutamol inhaler as needed', hasAllergies: false,
    comfortableWithCameras: true, cameraNote: 'Prefers no cameras in bedrooms', comfortableWithPets: true, petTypes: ['Dogs'],
    canCook: true, cuisines: ['Ethiopian', 'Arabic'], canDoNightShifts: true,
    religion: 'Christian', comfortableWithDifferentFaith: true,
    emergencyName: 'Selam Bekele', emergencyRelationship: 'Sibling', emergencyPhone: '+971 56 222 1133',
    bio: 'Caring nanny seeking a live-in role; experienced with toddlers and household help.',
    photoUrls: ['https://randomuser.me/api/portraits/women/90.jpg'],
    experiences: [
      { id: 'e1', jobTitle: 'Housekeeper & Nanny', employer: 'Khan Family', cityCountry: 'Sharjah, UAE', fromDate: '2023-02-01', toDate: '2025-02-01', children: '1 (age 2)', duties: 'Childcare and housekeeping', reasonLeaving: 'Family decision' },
    ],
    hasReferences: false, numberOfReferences: 0,
    status: 'pending', isVerified: false, profileScore: 60,
    documents: [
      { type: 'passport', status: 'approved', url: 'https://picsum.photos/seed/n3passport/640/420' },
      { type: 'visa', status: 'approved', url: 'https://picsum.photos/seed/n3visa/640/420' },
      { type: 'emiratesId', status: 'missing' },
      { type: 'trainingCert', status: 'rejected', url: 'https://picsum.photos/seed/n3cert/640/420', rejectionReason: 'Certificate is expired — please upload a current one.' },
    ],
    stats: { profileViews: 96, shortlists: 7, applicationsCount: 3, trialsCount: 0, hiresCount: 0, reviewsCount: 0 },
  },
  {
    id: 'n4', fullName: 'Grace Nkemelu', nationality: 'Ghanaian', city: 'Dubai', currentArea: 'Al Barsha',
    createdAt: new Date(Date.now() - 3 * 86400000),
    dateOfBirth: '1988-07-09', age: 37, experienceYears: 6,
    languages: ['English', 'French'],
    visaStatus: 'visit', hasEmiratesId: false, willingToTransferVisa: true,
    workEmirates: ['dubai'], willingToRelocate: false, availability: 'availableNow',
    jobTypePreference: 'liveOut', expectedSalaryMin: 2600, expectedSalaryMax: 3400,
    maritalStatus: 'widowed', hasChildren: true, childrenCount: 3, childrenAges: '12, 15, 18',
    hasHealthConditions: false, takesMedication: false, hasAllergies: false,
    comfortableWithCameras: true, comfortableWithPets: true, petTypes: ['Dogs', 'Cats'],
    canCook: true, cuisines: ['West African', 'Western'], canDoNightShifts: true,
    religion: 'Christian', comfortableWithDifferentFaith: true,
    emergencyName: 'Kwame Nkemelu', emergencyRelationship: 'Child', emergencyPhone: '+233 24 555 7788',
    bio: 'Senior nanny with 6 years of experience including special-needs care and twins.',
    photoUrls: ['https://randomuser.me/api/portraits/women/12.jpg', 'https://randomuser.me/api/portraits/women/19.jpg'],
    introVideoUrl: 'https://example.com/n4.mp4', introVideoStatus: 'pending',
    experiences: [
      { id: 'e1', jobTitle: 'Live-out Nanny', employer: 'Williams Family', cityCountry: 'Accra, Ghana', fromDate: '2018-01-01', toDate: '2024-06-01', children: 'Twins (age 4)', duties: 'Full daytime childcare', reasonLeaving: 'Personal reasons' },
    ],
    hasReferences: true, numberOfReferences: 1,
    references: [
      { id: 'r1', relationship: 'Long-term contact', city: 'Accra', yearsWorked: 6, canConfirm: 'Character and dependability' },
    ],
    status: 'pending', isVerified: false, profileScore: 70,
    documents: [
      { type: 'passport', status: 'resubmitted', url: 'https://picsum.photos/seed/n4passport/640/420' },
      { type: 'visa', status: 'uploaded', url: 'https://picsum.photos/seed/n4visa/640/420' },
      { type: 'policeClearance', status: 'rejected', url: 'https://picsum.photos/seed/n4police/640/420', rejectionReason: 'Document not clearly legible.' },
    ],
    stats: { profileViews: 154, shortlists: 12, applicationsCount: 5, trialsCount: 1, hiresCount: 0, averageRating: 4.9, reviewsCount: 2 },
  },
  {
    id: 'n5', fullName: 'Kezia Wanjiru', nationality: 'Kenyan', city: 'Dubai', currentArea: 'JLT',
    createdAt: new Date(Date.now() - 1 * 86400000),
    dateOfBirth: '1994-02-14', age: 32, experienceYears: 4,
    languages: ['English', 'Swahili'],
    visaStatus: 'outsideUae', hasEmiratesId: false, willingToTransferVisa: true,
    workEmirates: ['dubai', 'abuDhabi'], willingToRelocate: true, availability: 'onTrial',
    jobTypePreference: 'both', expectedSalaryMin: 2000, expectedSalaryMax: 2800,
    maritalStatus: 'single', hasChildren: false, childrenCount: 0,
    hasHealthConditions: false, takesMedication: false, hasAllergies: false,
    comfortableWithCameras: true, comfortableWithPets: false,
    canCook: false, canDoNightShifts: true,
    religion: 'Christian', comfortableWithDifferentFaith: true,
    emergencyName: 'Mary Wanjiru', emergencyRelationship: 'Parent', emergencyPhone: '+254 72 444 5566',
    bio: 'Energetic nanny who enjoys outdoor play and structured routines for young children.',
    photoUrls: ['https://randomuser.me/api/portraits/women/33.jpg'],
    introVideoUrl: 'https://example.com/v1.mp4', introVideoStatus: 'pending',
    experiences: [
      { id: 'e1', jobTitle: 'Babysitter', employer: 'Otieno Family', cityCountry: 'Nairobi, Kenya', fromDate: '2020-01-01', toDate: '2024-03-01', children: '2 (ages 5 & 7)', duties: 'After-school care and activities', reasonLeaving: 'Contract ended' },
    ],
    hasReferences: true, numberOfReferences: 1,
    references: [
      { id: 'r1', relationship: 'Family member of employer', city: 'Nairobi', yearsWorked: 4, canConfirm: 'Trustworthiness with children' },
    ],
    status: 'pending', isVerified: false, profileScore: 78,
    documents: [
      { type: 'passport', status: 'uploaded', url: 'https://picsum.photos/seed/n5passport/640/420' },
      { type: 'visa', status: 'resubmitted', url: 'https://picsum.photos/seed/n5visa/640/420' },
      { type: 'policeClearance', status: 'uploaded', url: 'https://picsum.photos/seed/n5police/640/420' },
    ],
    stats: { profileViews: 188, shortlists: 15, applicationsCount: 6, trialsCount: 1, hiresCount: 0, reviewsCount: 0 },
  },
];

const mockFamilies: FamilyRow[] = [
  {
    id: 'f1', fullName: 'Al Mansoori Family', nationality: 'Emirati', city: 'Abu Dhabi',
    profilePhoto: 'https://randomuser.me/api/portraits/men/32.jpg',
    childrenCount: 3, childrenAges: ['8 months', '4 years', '7 years'],
    hasSpecialNeedsChild: false,
    languagesAtHome: ['Arabic', 'English'],
    hasCameras: true, hasPets: false,
    religion: 'Muslim', nannyReligionPreference: 'preferMuslim',
    houseRules: 'Halal kitchen, prayer times respected.',
    aboutFamily: 'Busy professional Emirati family looking for a long-term live-in nanny for three young children.',
    subscription: { status: 'active', plan: 'monthly', startDate: new Date(Date.now() - 12 * 86400000), endDate: new Date(Date.now() + 18 * 86400000), autoRenew: true, hasEverSubscribed: true },
    freeContactsUsed: 5, activeTrialNannyIds: ['n1'],
    stats: { jobPostsCount: 2, activeJobPosts: 1, totalApplicationsReceived: 14, trialsCount: 3, hiresCount: 1 },
  },
  {
    id: 'f2', fullName: 'James & Sarah K.', nationality: 'British', city: 'Dubai Marina',
    profilePhoto: 'https://randomuser.me/api/portraits/women/28.jpg',
    childrenCount: 2, childrenAges: ['2 years', '5 years'],
    hasSpecialNeedsChild: false,
    languagesAtHome: ['English'],
    hasCameras: true, hasPets: true, petTypes: ['Dog'],
    religion: 'Christian', nannyReligionPreference: 'noPreference',
    aboutFamily: 'Expat family in Dubai Marina seeking an English-speaking live-out nanny for two children.',
    subscription: { status: 'active', plan: 'twoMonths', startDate: new Date(Date.now() - 13 * 86400000), endDate: new Date(Date.now() + 47 * 86400000), autoRenew: true, hasEverSubscribed: true },
    freeContactsUsed: 3,
    stats: { jobPostsCount: 1, activeJobPosts: 1, totalApplicationsReceived: 9, trialsCount: 1, hiresCount: 0 },
  },
  {
    id: 'f3', fullName: 'Lin Chen', nationality: 'Chinese', city: 'Dubai',
    childrenCount: 1, childrenAges: ['3 years'],
    hasSpecialNeedsChild: true, specialNeedsDetails: 'Child has mild autism; needs patient, structured care.',
    languagesAtHome: ['English', 'Mandarin'],
    hasCameras: true, hasPets: false,
    religion: 'Other', nannyReligionPreference: 'openWithRespect',
    aboutFamily: 'Single working parent seeking experienced caregiver familiar with special-needs routines.',
    subscription: { status: 'free', hasEverSubscribed: false }, freeContactsUsed: 2,
    stats: { jobPostsCount: 1, activeJobPosts: 1, totalApplicationsReceived: 4, trialsCount: 0, hiresCount: 0 },
  },
  {
    id: 'f4', fullName: 'Mohammed Al Rashid', nationality: 'Emirati', city: 'Dubai',
    profilePhoto: 'https://randomuser.me/api/portraits/men/52.jpg',
    childrenCount: 4, childrenAges: ['1 year', '3 years', '6 years', '9 years'],
    hasSpecialNeedsChild: false,
    languagesAtHome: ['Arabic', 'English'],
    hasCameras: true, hasPets: false,
    religion: 'Muslim', nannyReligionPreference: 'preferSame',
    houseRules: 'Modest dress code, halal household.',
    aboutFamily: 'Large family needing a hardworking live-in nanny and housekeeper.',
    subscription: { status: 'expired', plan: 'weekly', startDate: new Date(Date.now() - 10 * 86400000), endDate: new Date(Date.now() - 3 * 86400000), hasEverSubscribed: true },
    freeContactsUsed: 5, activeTrialNannyIds: ['n4'],
    stats: { jobPostsCount: 3, activeJobPosts: 0, totalApplicationsReceived: 21, trialsCount: 4, hiresCount: 2 },
  },
];

// ── Job posts created by families (job-creation flow) ──
const mockJobPosts: JobPostRow[] = [
  {
    id: 'j1', familyId: 'f1', familyName: 'Al Mansoori Family', status: 'active',
    createdAt: new Date(Date.now() - 12 * 86400000), expiresAt: new Date(Date.now() + 18 * 86400000),
    jobTitle: 'Live-in nanny for 3 children', rolesNeeded: ['Nanny', 'Babysitter'], jobType: 'liveIn',
    schedule: 'Sun–Thu, 7am–7pm', startImmediate: true, duration: 'permanent', experienceYears: 3,
    languagesRequired: ['English'], languagesPreferred: ['Arabic (basic)'], nationalityPreference: ['Filipino', 'Indian'],
    religionPreference: 'preferMuslim', duties: ['Newborn', 'Childcare', 'Light cleaning', 'Cook family'],
    salaryMin: 2500, salaryMax: 3500, currency: 'AED',
    benefits: ['Meals provided', 'Private room', 'Yearly flight', 'Health insurance'],
    visaSponsorship: 'full', trialDurationDays: 7, trialDailyRate: 150,
    additionalNotes: 'Must be comfortable with infants and a busy household.',
    viewsCount: 230, applicationsCount: 11, city: 'Abu Dhabi',
  },
  {
    id: 'j2', familyId: 'f1', familyName: 'Al Mansoori Family', status: 'closed',
    createdAt: new Date(Date.now() - 90 * 86400000),
    jobTitle: 'Weekend babysitter', rolesNeeded: ['Babysitter'], jobType: 'liveOut',
    schedule: 'Fri–Sat evenings', startImmediate: false, duration: 'contract', contractMonths: 3, experienceYears: 1,
    languagesRequired: ['English'], duties: ['Childcare'], salaryMin: 1200, salaryMax: 1600, currency: 'AED',
    benefits: ['Meals provided'], visaSponsorship: 'none', trialDurationDays: 3, trialDailyRate: 120,
    viewsCount: 88, applicationsCount: 3, city: 'Abu Dhabi',
  },
  {
    id: 'j3', familyId: 'f2', familyName: 'James & Sarah K.', status: 'active',
    createdAt: new Date(Date.now() - 13 * 86400000), expiresAt: new Date(Date.now() + 17 * 86400000),
    jobTitle: 'Live-out nanny (English-speaking)', rolesNeeded: ['Nanny'], jobType: 'liveOut',
    schedule: 'Mon–Fri, 8am–5pm', startImmediate: true, duration: 'permanent', experienceYears: 2,
    languagesRequired: ['English'], nationalityPreference: ['Filipino', 'Kenyan'],
    duties: ['Childcare', 'Tutoring', 'Light cleaning'], salaryMin: 2200, salaryMax: 3000, currency: 'AED',
    benefits: ['Health insurance', 'Days off weekly'], visaSponsorship: 'residenceOnly', trialDurationDays: 5, trialDailyRate: 140,
    viewsCount: 142, applicationsCount: 9, city: 'Dubai Marina',
  },
  {
    id: 'j4', familyId: 'f3', familyName: 'Lin Chen', status: 'active',
    createdAt: new Date(Date.now() - 6 * 86400000), expiresAt: new Date(Date.now() + 24 * 86400000),
    jobTitle: 'Caregiver — special needs experience', rolesNeeded: ['Caregiver', 'Nanny'], jobType: 'liveOut',
    schedule: 'Sun–Thu, 9am–6pm', startImmediate: false, startDate: new Date(Date.now() + 20 * 86400000),
    duration: 'permanent', experienceYears: 4, languagesRequired: ['English'],
    skillsRequired: ['Special needs care', 'First Aid'], duties: ['Childcare', 'First Aid'],
    salaryMin: 3000, salaryMax: 4000, currency: 'AED', benefits: ['Health insurance', 'Phone provided'],
    visaSponsorship: 'shared', trialDurationDays: 7, trialDailyRate: 170, city: 'Dubai',
    additionalNotes: 'Experience with autism spectrum strongly preferred.',
    viewsCount: 61, applicationsCount: 4,
  },
  {
    id: 'j5', familyId: 'f4', familyName: 'Mohammed Al Rashid', status: 'expired',
    createdAt: new Date(Date.now() - 40 * 86400000), expiresAt: new Date(Date.now() - 5 * 86400000),
    jobTitle: 'Live-in nanny & housekeeper', rolesNeeded: ['Nanny', 'Maid', 'Cook'], jobType: 'liveIn',
    schedule: 'Sat–Thu, full day', startImmediate: true, duration: 'permanent', experienceYears: 5,
    languagesRequired: ['English', 'Arabic (basic)'], religionPreference: 'preferSame',
    duties: ['Childcare', 'Light cleaning', 'Laundry', 'Cook family'], salaryMin: 2800, salaryMax: 3600, currency: 'AED',
    benefits: ['Meals provided', 'Private room', 'Yearly flight'], visaSponsorship: 'full', trialDurationDays: 10, trialDailyRate: 160,
    viewsCount: 310, applicationsCount: 18, city: 'Dubai',
  },
];

// ── Applications / offers ──
const mockApplications: ApplicationRow[] = [
  { id: 'a1', jobPostId: 'j1', jobTitle: 'Live-in nanny for 3 children', nannyId: 'n1', nannyName: 'Sarah Reyes', familyId: 'f1', familyName: 'Al Mansoori Family', status: 'hired', matchScore: 92, coverMessage: 'I have 5 years of live-in experience with infants.', createdAt: new Date(Date.now() - 25 * 86400000), respondedAt: new Date(Date.now() - 20 * 86400000) },
  { id: 'a2', jobPostId: 'j1', jobTitle: 'Live-in nanny for 3 children', nannyId: 'n3', nannyName: 'Amara Kebede', familyId: 'f1', familyName: 'Al Mansoori Family', status: 'shortlisted', matchScore: 74, createdAt: new Date(Date.now() - 8 * 86400000), respondedAt: new Date(Date.now() - 6 * 86400000) },
  { id: 'a3', jobPostId: 'j3', jobTitle: 'Live-out nanny (English-speaking)', nannyId: 'n5', nannyName: 'Kezia Wanjiru', familyId: 'f2', familyName: 'James & Sarah K.', status: 'trialOffered', matchScore: 81, createdAt: new Date(Date.now() - 10 * 86400000), respondedAt: new Date(Date.now() - 7 * 86400000) },
  { id: 'a4', jobPostId: 'j3', jobTitle: 'Live-out nanny (English-speaking)', nannyId: 'n2', nannyName: 'Priya Sharma', familyId: 'f2', familyName: 'James & Sarah K.', status: 'declined', matchScore: 58, createdAt: new Date(Date.now() - 11 * 86400000), respondedAt: new Date(Date.now() - 9 * 86400000) },
  { id: 'a5', jobPostId: 'j5', jobTitle: 'Live-in nanny & housekeeper', nannyId: 'n4', nannyName: 'Grace Nkemelu', familyId: 'f4', familyName: 'Mohammed Al Rashid', status: 'hired', matchScore: 88, createdAt: new Date(Date.now() - 35 * 86400000), respondedAt: new Date(Date.now() - 30 * 86400000) },
  { id: 'a6', jobPostId: 'j4', jobTitle: 'Caregiver — special needs experience', nannyId: 'n4', nannyName: 'Grace Nkemelu', familyId: 'f3', familyName: 'Lin Chen', status: 'pending', matchScore: 79, createdAt: new Date(Date.now() - 3 * 86400000) },
];

// ── Reviews / ratings ──
const mockReviews: ReviewRow[] = [
  { id: 'rv1', reviewerId: 'f1', reviewerName: 'Al Mansoori Family', reviewerType: 'family', revieweeId: 'n1', revieweeType: 'nanny', trialId: 't3', rating: 5, comment: 'Wonderful with our children, highly recommended.', createdAt: new Date(Date.now() - 18 * 86400000) },
  { id: 'rv2', reviewerId: 'f4', reviewerName: 'Mohammed Al Rashid', reviewerType: 'family', revieweeId: 'n1', revieweeType: 'nanny', rating: 4, comment: 'Reliable and punctual.', createdAt: new Date(Date.now() - 60 * 86400000) },
  { id: 'rv3', reviewerId: 'n1', reviewerName: 'Sarah Reyes', reviewerType: 'nanny', revieweeId: 'f1', revieweeType: 'family', trialId: 't3', rating: 5, comment: 'Kind and respectful family, great accommodation.', createdAt: new Date(Date.now() - 17 * 86400000) },
  { id: 'rv4', reviewerId: 'f3', reviewerName: 'Lin Chen', reviewerType: 'family', revieweeId: 'n4', revieweeType: 'nanny', rating: 5, comment: 'Very patient and experienced.', createdAt: new Date(Date.now() - 5 * 86400000) },
  { id: 'rv5', reviewerId: 'n4', reviewerName: 'Grace Nkemelu', reviewerType: 'nanny', revieweeId: 'f4', revieweeType: 'family', rating: 4, comment: 'Good family, busy household.', createdAt: new Date(Date.now() - 28 * 86400000) },
];

// ── Chat threads & messages (nanny ↔ family) ──
const mockChatThreads: ChatThreadRow[] = [
  { id: 'c_f1_n1', familyId: 'f1', nannyId: 'n1', familyName: 'Al Mansoori Family', nannyName: 'Sarah Reyes', createdAt: new Date(Date.now() - 24 * 86400000), lastMessageAt: new Date(Date.now() - 2 * 86400000), lastMessage: 'See you on the first trial day!', trialId: 't3', trialStatus: 'active', status: 'active' },
  { id: 'c_f2_n5', familyId: 'f2', nannyId: 'n5', familyName: 'James & Sarah K.', nannyName: 'Kezia Wanjiru', createdAt: new Date(Date.now() - 10 * 86400000), lastMessageAt: new Date(Date.now() - 1 * 86400000), lastMessage: 'I have sent you a trial offer.', trialId: 't4', trialStatus: 'pending', status: 'active' },
  { id: 'c_f4_n4', familyId: 'f4', nannyId: 'n4', familyName: 'Mohammed Al Rashid', nannyName: 'Grace Nkemelu', createdAt: new Date(Date.now() - 36 * 86400000), lastMessageAt: new Date(Date.now() - 4 * 86400000), lastMessage: 'Thank you, the trial went well.', trialId: 't2', trialStatus: 'active', status: 'active' },
  { id: 'c_f3_n4', familyId: 'f3', nannyId: 'n4', familyName: 'Lin Chen', nannyName: 'Grace Nkemelu', createdAt: new Date(Date.now() - 3 * 86400000), lastMessageAt: new Date(Date.now() - 3 * 86400000), lastMessage: 'Hi, are you available for an interview?', status: 'active' },
];

const mockChatMessages: ChatMessageRow[] = [
  // Thread c_f1_n1
  { id: 'm1', threadId: 'c_f1_n1', senderId: 'f1', senderType: 'family', content: 'Hi Sarah, we loved your profile. Are you available for a live-in role?', type: 'text', createdAt: new Date(Date.now() - 24 * 86400000), readAt: new Date(Date.now() - 24 * 86400000) },
  { id: 'm2', threadId: 'c_f1_n1', senderId: 'n1', senderType: 'nanny', content: 'Hello! Yes, I am available and very interested.', type: 'text', createdAt: new Date(Date.now() - 23 * 86400000), readAt: new Date(Date.now() - 23 * 86400000) },
  { id: 'm3', threadId: 'c_f1_n1', senderId: 'f1', senderType: 'family', content: 'Trial offer: 7 days at AED 150/day starting next week.', type: 'trialOffer', trialOfferId: 't3', createdAt: new Date(Date.now() - 20 * 86400000), readAt: new Date(Date.now() - 20 * 86400000) },
  { id: 'm4', threadId: 'c_f1_n1', senderId: 'n1', senderType: 'nanny', content: 'I accept the trial offer, thank you!', type: 'trialAccepted', createdAt: new Date(Date.now() - 19 * 86400000), readAt: new Date(Date.now() - 19 * 86400000) },
  { id: 'm5', threadId: 'c_f1_n1', senderId: 'f1', senderType: 'family', content: 'See you on the first trial day!', type: 'text', createdAt: new Date(Date.now() - 2 * 86400000) },
  // Thread c_f2_n5
  { id: 'm6', threadId: 'c_f2_n5', senderId: 'f2', senderType: 'family', content: 'Hi Kezia, your experience looks great.', type: 'text', createdAt: new Date(Date.now() - 10 * 86400000), readAt: new Date(Date.now() - 10 * 86400000) },
  { id: 'm7', threadId: 'c_f2_n5', senderId: 'n5', senderType: 'nanny', content: 'Thank you so much! I would love to learn more.', type: 'text', createdAt: new Date(Date.now() - 9 * 86400000), readAt: new Date(Date.now() - 9 * 86400000) },
  { id: 'm8', threadId: 'c_f2_n5', senderId: 'f2', senderType: 'family', content: 'I have sent you a trial offer.', type: 'trialOffer', trialOfferId: 't4', createdAt: new Date(Date.now() - 1 * 86400000) },
  // Thread c_f4_n4
  { id: 'm9', threadId: 'c_f4_n4', senderId: 'f4', senderType: 'family', content: 'Welcome Grace, looking forward to the trial.', type: 'text', createdAt: new Date(Date.now() - 36 * 86400000), readAt: new Date(Date.now() - 36 * 86400000) },
  { id: 'm10', threadId: 'c_f4_n4', senderId: 'n4', senderType: 'nanny', content: 'Thank you, the trial went well.', type: 'text', createdAt: new Date(Date.now() - 4 * 86400000) },
  // Thread c_f3_n4
  { id: 'm11', threadId: 'c_f3_n4', senderId: 'f3', senderType: 'family', content: 'Hi, are you available for an interview?', type: 'text', createdAt: new Date(Date.now() - 3 * 86400000) },
];

// ── Dispute support chat (admin ↔ reporting user) ──
const mockDisputeMessages: DisputeMessageRow[] = [
  { id: 'dm1', disputeId: 'd1', senderType: 'user', senderName: 'Al Mansoori Family', content: 'The nanny did not arrive for the scheduled trial day and did not respond.', createdAt: new Date(Date.now() - 2 * 86400000) },
  { id: 'dm2', disputeId: 'd1', senderType: 'admin', senderName: 'Support', content: 'Thank you for reporting. We are reaching out to the nanny now.', createdAt: new Date(Date.now() - 2 * 86400000 + 3600000) },
  { id: 'dm3', disputeId: 'd2', senderType: 'user', senderName: 'Amara Kebede', content: 'The family did not make the trial payment on day 3 as agreed.', createdAt: new Date(Date.now() - 5 * 86400000) },
  { id: 'dm4', disputeId: 'd2', senderType: 'admin', senderName: 'Support', content: 'We have opened an investigation and contacted the family.', createdAt: new Date(Date.now() - 5 * 86400000 + 7200000) },
  { id: 'dm5', disputeId: 'd2', senderType: 'user', senderName: 'Amara Kebede', content: 'Thank you, I will wait for the update.', createdAt: new Date(Date.now() - 4 * 86400000) },
];

const mockDisputes: DisputeRow[] = [
  { id: 'd1', reporterId: 'f1', reporterName: 'Al Mansoori Family', reporterType: 'family', reportedUserId: 'n2', reportedName: 'Priya Sharma', category: 'no_show', description: 'Nanny did not arrive for scheduled trial day.', status: 'open', relatedTrialId: 't1', createdAt: new Date(Date.now() - 2 * 86400000) },
  { id: 'd2', reporterId: 'n3', reporterName: 'Amara Kebede', reporterType: 'nanny', reportedUserId: 'f4', reportedName: 'Mohammed Al Rashid', category: 'payment', description: 'Trial payment was not made on day 3 as agreed.', status: 'investigating', relatedTrialId: 't2', createdAt: new Date(Date.now() - 5 * 86400000) },
  { id: 'd3', reporterId: 'f3', reporterName: 'Lin Chen', reporterType: 'family', reportedUserId: 'n5', reportedName: 'Kezia Wanjiru', category: 'other', description: 'Nanny stopped responding after agreeing to an interview.', status: 'open', createdAt: new Date(Date.now() - 1 * 86400000) },
  { id: 'd4', reporterId: 'n4', reporterName: 'Grace Nkemelu', reporterType: 'nanny', reportedUserId: 'f4', reportedName: 'Mohammed Al Rashid', category: 'abuse', description: 'Felt disrespected and overworked during the trial period.', status: 'resolved', resolution: 'Mediated between both parties; family agreed to revised hours.', createdAt: new Date(Date.now() - 14 * 86400000) },
  { id: 'd5', reporterId: 'f2', reporterName: 'James & Sarah K.', reporterType: 'family', reportedUserId: 'n2', reportedName: 'Priya Sharma', category: 'fraud', description: 'Suspected fake references provided.', status: 'dismissed', resolution: 'References verified as genuine. No action taken.', createdAt: new Date(Date.now() - 20 * 86400000) },
];

const mockSettings = {
  freeContactLimit: 5,
  jobPostVisibilityDays: 30,
  plans: { weekly: 89, monthly: 239, twoMonths: 369 },
  vatRate: 0.05,
};

function toDateOrUndef(raw: unknown): Date | undefined {
  if (raw && typeof (raw as { toDate?: () => Date }).toDate === 'function') {
    return (raw as { toDate: () => Date }).toDate();
  }
  if (typeof raw === 'string') {
    const d = new Date(raw);
    if (!isNaN(d.getTime())) return d;
  }
  return undefined;
}

/** Normalise a Firestore nanny doc for admin tables (defaults + timestamps). */
function mapNannyFromFirestore(id: string, data: Record<string, unknown>): NannyRow {
  const row = { id, ...(data as Omit<NannyRow, 'id'>) };
  return {
    ...row,
    fullName: row.fullName?.trim() || 'Unnamed nanny',
    nationality: row.nationality?.trim() || '—',
    city: row.city?.trim() || '—',
    status: row.status ?? 'draft',
    isVerified: row.isVerified ?? false,
    createdAt: toDateOrUndef(data.createdAt) ?? row.createdAt,
  };
}

// ─────────────────────────────────────────────────────────
// Nanny service
// ─────────────────────────────────────────────────────────
export const NannyService = {
  async list(): Promise<NannyRow[]> {
    if (useMock()) return mockNannies;
    const snap = await getDocs(query(collection(db!, 'nannies'), limit(200)));
    return snap.docs.map((d) => mapNannyFromFirestore(d.id, d.data()));
  },
  async listPendingDocs(): Promise<NannyRow[]> {
    if (useMock()) return mockNannies.filter((n) => n.status === 'pending');
    const snap = await getDocs(query(collection(db!, 'nannies'), where('status', '==', 'pending')));
    return snap.docs.map((d) => mapNannyFromFirestore(d.id, d.data()));
  },
  async listPendingVideos(): Promise<NannyRow[]> {
    if (useMock()) return mockNannies.filter((n) => !!n.introVideoUrl && n.introVideoStatus !== 'approved' && n.introVideoStatus !== 'rejected');
    // Query for nannies that have a video URL but haven't been video-reviewed yet
    const snap = await getDocs(
      query(collection(db!, 'nannies'), where('introVideoStatus', '==', 'pending'), limit(200)),
    );
    return snap.docs.map((d) => mapNannyFromFirestore(d.id, d.data()));
  },
  async get(id: string): Promise<NannyRow | null> {
    if (useMock()) return mockNannies.find((n) => n.id === id) ?? null;
    const snap = await getDoc(doc(db!, 'nannies', id));
    return snap.exists() ? mapNannyFromFirestore(snap.id, snap.data()) : null;
  },
  async update(id: string, patch: Partial<NannyRow>): Promise<void> {
    if (useMock()) {
      const i = mockNannies.findIndex((n) => n.id === id);
      if (i >= 0) mockNannies[i] = { ...mockNannies[i], ...patch };
      return;
    }
    await updateDoc(doc(db!, 'nannies', id), patch as Record<string, unknown>);
  },
  async approve(id: string, adminId: string): Promise<void> {
    if (useMock()) {
      const i = mockNannies.findIndex((n) => n.id === id);
      if (i >= 0) mockNannies[i] = { ...mockNannies[i], status: 'approved', isVerified: true };
      return;
    }
    await updateDoc(doc(db!, 'nannies', id), {
      status: 'approved',
      isVerified: true,
      verifiedAt: serverTimestamp(),
      verifiedBy: adminId,
    });
  },
  async reject(id: string, reason: string, adminId: string): Promise<void> {
    if (useMock()) {
      const i = mockNannies.findIndex((n) => n.id === id);
      if (i >= 0) mockNannies[i] = { ...mockNannies[i], status: 'rejected' };
      return;
    }
    await updateDoc(doc(db!, 'nannies', id), {
      status: 'rejected',
      rejectionReason: reason,
      rejectedAt: serverTimestamp(),
      rejectedBy: adminId,
    });
  },
  async reviewVideo(nannyId: string, status: 'approved' | 'rejected', adminId: string, reason?: string): Promise<void> {
    if (useMock()) {
      const i = mockNannies.findIndex((n) => n.id === nannyId);
      if (i >= 0) {
        mockNannies[i] = {
          ...mockNannies[i],
          introVideoStatus: status,
          introVideoRejectionReason: status === 'rejected' ? reason : undefined,
        };
      }
      return;
    }
    await updateDoc(doc(db!, 'nannies', nannyId), {
      introVideoStatus: status,
      introVideoRejectionReason: status === 'rejected' ? reason ?? '' : null,
      introVideoReviewedAt: serverTimestamp(),
      introVideoReviewedBy: adminId,
    });
  },
  async block(id: string): Promise<void> {
    if (useMock()) {
      const i = mockNannies.findIndex((n) => n.id === id);
      if (i >= 0) mockNannies[i] = { ...mockNannies[i], blocked: true };
      return;
    }
    await updateDoc(doc(db!, 'nannies', id), { blocked: true, blockedAt: serverTimestamp() });
  },
  async unblock(id: string): Promise<void> {
    if (useMock()) {
      const i = mockNannies.findIndex((n) => n.id === id);
      if (i >= 0) mockNannies[i] = { ...mockNannies[i], blocked: false };
      return;
    }
    await updateDoc(doc(db!, 'nannies', id), { blocked: false });
  },
  async reviewDocument(nannyId: string, docId: string, status: 'approved' | 'rejected', reason?: string): Promise<void> {
    if (useMock()) {
      const i = mockNannies.findIndex((n) => n.id === nannyId);
      if (i >= 0) {
        const docs = (mockNannies[i].documents ?? []).map((d) =>
          d.type === docId
            ? { ...d, status, rejectionReason: status === 'rejected' ? reason ?? '' : undefined }
            : d,
        );
        mockNannies[i] = { ...mockNannies[i], documents: docs };
      }
      return;
    }
    // Flutter stores `documents` as an embedded array on the nanny doc
    // (`nanny_model.dart` → toMap()), not as a subcollection. Patch the
    // matching entry in the array and write the parent doc back.
    const ref = doc(db!, 'nannies', nannyId);
    const snap = await getDoc(ref);
    if (!snap.exists()) throw new Error('Nanny not found');
    const data = snap.data() as Record<string, unknown>;
    const docs = Array.isArray(data.documents)
      ? ((data.documents as Array<Record<string, unknown>>) ?? [])
      : [];
    const next = docs.map((d) =>
      d.type === docId
        ? {
            ...d,
            status,
            rejectionReason: status === 'rejected' ? reason ?? '' : null,
            reviewedAt: new Date().toISOString(),
          }
        : d,
    );
    await updateDoc(ref, { documents: next, updatedAt: serverTimestamp() });
  },
  /// Reads the private `nannies/{id}/documents/{type}` subcollection where the
  /// app now stores sensitive KYC download URLs (C5 — kept off the
  /// world-readable parent doc). Returns a `{ [docType]: url }` map so the
  /// review UI can display each document. Mock nannies carry inline URLs, so
  /// this is a no-op there.
  async getDocumentUrls(nannyId: string): Promise<Record<string, string>> {
    if (useMock()) return {};
    const snap = await getDocs(collection(db!, 'nannies', nannyId, 'documents'));
    const out: Record<string, string> = {};
    snap.docs.forEach((d) => {
      const url = (d.data() as { url?: string }).url;
      if (url) out[d.id] = url; // doc id === document type name
    });
    return out;
  },
};

// ─────────────────────────────────────────────────────────
// Family / subscription service
// ─────────────────────────────────────────────────────────
export const FamilyService = {
  async list(): Promise<FamilyRow[]> {
    if (useMock()) return mockFamilies;
    const snap = await getDocs(query(collection(db!, 'families'), limit(200)));
    return snap.docs.map((d) => parseFamily(d.id, d.data() as Record<string, unknown>));
  },
  async get(id: string): Promise<FamilyRow | null> {
    if (useMock()) return mockFamilies.find((f) => f.id === id) ?? null;
    const snap = await getDoc(doc(db!, 'families', id));
    if (!snap.exists()) return null;
    return parseFamily(snap.id, snap.data() as Record<string, unknown>);
  },
  async overrideSubscription(
    id: string,
    patch: { status: FamilyRow['subscription']['status']; plan?: string; endDate?: Date }
  ): Promise<void> {
    if (useMock()) {
      const i = mockFamilies.findIndex((f) => f.id === id);
      if (i >= 0) mockFamilies[i] = { ...mockFamilies[i], subscription: { ...mockFamilies[i].subscription, ...patch } };
      return;
    }
    await updateDoc(doc(db!, 'families', id), {
      'subscription.status': patch.status,
      ...(patch.plan ? { 'subscription.plan': patch.plan } : {}),
      ...(patch.endDate ? { 'subscription.endDate': Timestamp.fromDate(patch.endDate) } : {}),
      'subscription.lastRenewalAt': serverTimestamp(),
    });
  },
  async resetFreeContacts(id: string): Promise<void> {
    if (useMock()) {
      const i = mockFamilies.findIndex((f) => f.id === id);
      if (i >= 0) mockFamilies[i] = { ...mockFamilies[i], freeContactsUsed: 0 };
      return;
    }
    await updateDoc(doc(db!, 'families', id), { freeContactsUsed: 0 });
  },
  async block(id: string): Promise<void> {
    if (useMock()) {
      const i = mockFamilies.findIndex((f) => f.id === id);
      if (i >= 0) mockFamilies[i] = { ...mockFamilies[i], blocked: true };
      return;
    }
    await updateDoc(doc(db!, 'families', id), { blocked: true, blockedAt: serverTimestamp() });
  },
  async unblock(id: string): Promise<void> {
    if (useMock()) {
      const i = mockFamilies.findIndex((f) => f.id === id);
      if (i >= 0) mockFamilies[i] = { ...mockFamilies[i], blocked: false };
      return;
    }
    await updateDoc(doc(db!, 'families', id), { blocked: false });
  },
};

function parseSub(v: unknown): FamilyRow['subscription'] {
  const s = (v ?? {}) as Record<string, unknown>;
  const status = (s.status as FamilyRow['subscription']['status']) ?? 'free';
  const plan = s.plan as string | undefined;
  return {
    status,
    plan,
    startDate: toDateOrUndef(s.startDate),
    endDate: toDateOrUndef(s.endDate),
    autoRenew: s.autoRenew as boolean | undefined,
    hasEverSubscribed: s.hasEverSubscribed as boolean | undefined,
  };
}

function parseFamily(id: string, data: Record<string, unknown>): FamilyRow {
  return {
    id,
    createdAt: toDateOrUndef(data.createdAt),
    fullName: (data.fullName as string) ?? '',
    nationality: (data.nationality as string) ?? '',
    city: (data.city as string) ?? '',
    profilePhoto: data.profilePhoto as string | undefined,
    blocked: data.blocked as boolean | undefined,
    childrenCount: data.childrenCount as number | undefined,
    childrenAges: (data.childrenAges as string[]) ?? [],
    hasSpecialNeedsChild: data.hasSpecialNeedsChild as boolean | undefined,
    specialNeedsDetails: data.specialNeedsDetails as string | undefined,
    languagesAtHome: (data.languagesAtHome as string[]) ?? [],
    hasCameras: data.hasCameras as boolean | undefined,
    hasPets: data.hasPets as boolean | undefined,
    petTypes: (data.petTypes as string[]) ?? [],
    religion: data.religion as string | undefined,
    nannyReligionPreference: data.nannyReligionPreference as NannyReligionPreference | undefined,
    houseRules: data.houseRules as string | undefined,
    aboutFamily: data.aboutFamily as string | undefined,
    subscription: parseSub(data.subscription),
    freeContactsUsed: (data.freeContactsUsed as number) ?? 0,
    activeTrialNannyIds: (data.activeTrialNannyIds as string[]) ?? [],
    stats: (data.stats as FamilyStatsRow) ?? undefined,
  };
}

// ─────────────────────────────────────────────────────────
// Trial service (admin read-only)
// ─────────────────────────────────────────────────────────
export type TrialStatus = 'pending' | 'countered' | 'accepted' | 'declined' | 'active' | 'completed' | 'cancelled';

/** Family's evaluation checklist after a trial (mirrors TrialEvaluation). */
export interface TrialEvaluationRow {
  childInteractionAndPatience?: boolean;
  punctualityAndReliability?: boolean;
  followingInstructions?: boolean;
  communicationAndLanguage?: boolean;
  cookingFamilyFood?: boolean;
  honestyAndTrustworthiness?: boolean;
  additionalNotes?: string;
}

export interface TrialAdminRow {
  id: string;
  familyId: string;
  nannyId: string;
  familyName?: string;
  nannyName?: string;
  jobPostId?: string;
  status: TrialStatus | string;
  trialType?: string;
  durationDays: number;
  dailyRate: number;
  startDate: Date;
  endDate: Date;
  location?: string;
  notes?: string;
  outcome?: string;
  completedAt?: Date;
  /** Family's rating of the nanny for this trial (1-5), if reviewed. */
  rating?: number;
  evaluation?: TrialEvaluationRow;
  nannyConfirmedPayment?: boolean;
  paymentIssueReported?: boolean;
}

const mockTrials: TrialAdminRow[] = [
  { id: 't1', familyId: 'f1', nannyId: 'n1', familyName: 'Al Mansoori Family', nannyName: 'Sarah Reyes', jobPostId: 'j1', status: 'active', trialType: 'live-in', durationDays: 7, dailyRate: 150, startDate: new Date(Date.now() - 2 * 86400000), endDate: new Date(Date.now() + 5 * 86400000), location: 'Dubai Marina', notes: 'Trial going well; family happy so far.', nannyConfirmedPayment: false },
  { id: 't2', familyId: 'f4', nannyId: 'n4', familyName: 'Mohammed Al Rashid', nannyName: 'Grace Nkemelu', jobPostId: 'j5', status: 'active', trialType: 'live-in', durationDays: 3, dailyRate: 120, startDate: new Date(Date.now() - 1 * 86400000), endDate: new Date(Date.now() + 2 * 86400000), location: 'Al Barsha', notes: 'Day 2 in progress.', paymentIssueReported: true },
  { id: 't3', familyId: 'f1', nannyId: 'n1', familyName: 'Al Mansoori Family', nannyName: 'Sarah Reyes', jobPostId: 'j1', status: 'completed', trialType: 'live-in', durationDays: 7, dailyRate: 150, startDate: new Date(Date.now() - 30 * 86400000), endDate: new Date(Date.now() - 23 * 86400000), location: 'Abu Dhabi', outcome: 'hired', completedAt: new Date(Date.now() - 23 * 86400000), rating: 5, nannyConfirmedPayment: true,
    evaluation: { childInteractionAndPatience: true, punctualityAndReliability: true, followingInstructions: true, communicationAndLanguage: true, cookingFamilyFood: true, honestyAndTrustworthiness: true, additionalNotes: 'Excellent throughout the trial — hired immediately.' } },
  { id: 't4', familyId: 'f2', nannyId: 'n5', familyName: 'James & Sarah K.', nannyName: 'Kezia Wanjiru', jobPostId: 'j3', status: 'pending', trialType: 'live-out', durationDays: 5, dailyRate: 140, startDate: new Date(Date.now() + 3 * 86400000), endDate: new Date(Date.now() + 8 * 86400000), location: 'Dubai Marina' },
  { id: 't5', familyId: 'f4', nannyId: 'n4', familyName: 'Mohammed Al Rashid', nannyName: 'Grace Nkemelu', jobPostId: 'j5', status: 'cancelled', trialType: 'live-in', durationDays: 10, dailyRate: 160, startDate: new Date(Date.now() - 45 * 86400000), endDate: new Date(Date.now() - 35 * 86400000), location: 'Dubai', outcome: 'cancelled', completedAt: new Date(Date.now() - 42 * 86400000) },
  { id: 't6', familyId: 'f4', nannyId: 'n4', familyName: 'Mohammed Al Rashid', nannyName: 'Grace Nkemelu', jobPostId: 'j5', status: 'completed', trialType: 'live-in', durationDays: 7, dailyRate: 160, startDate: new Date(Date.now() - 33 * 86400000), endDate: new Date(Date.now() - 26 * 86400000), location: 'Dubai', outcome: 'hired', completedAt: new Date(Date.now() - 26 * 86400000), rating: 4 },
];

function parseTimestamp(v: unknown): Date {
  if (!v) return new Date();
  if (typeof (v as { toDate?: () => Date }).toDate === 'function') {
    return (v as { toDate: () => Date }).toDate();
  }
  if (typeof v === 'string') {
    const d = new Date(v);
    if (!isNaN(d.getTime())) return d;
  }
  return new Date();
}

export const TrialService = {
  async listActive(): Promise<TrialAdminRow[]> {
    if (useMock()) return mockTrials;
    const snap = await getDocs(
      query(
        collection(db!, 'trials'),
        where('status', 'in', ['active', 'accepted']),
        limit(100),
      ),
    );
    return snap.docs.map((d) => parseTrial(d.id, d.data() as Record<string, unknown>));
  },
  async listAll(): Promise<TrialAdminRow[]> {
    if (useMock()) return mockTrials;
    const snap = await getDocs(query(collection(db!, 'trials'), limit(300)));
    return snap.docs.map((d) => parseTrial(d.id, d.data() as Record<string, unknown>));
  },
  async listByFamily(familyId: string): Promise<TrialAdminRow[]> {
    if (useMock()) return mockTrials.filter((t) => t.familyId === familyId);
    const snap = await getDocs(query(collection(db!, 'trials'), where('familyId', '==', familyId), limit(100)));
    return snap.docs.map((d) => parseTrial(d.id, d.data() as Record<string, unknown>));
  },
  async listByNanny(nannyId: string): Promise<TrialAdminRow[]> {
    if (useMock()) return mockTrials.filter((t) => t.nannyId === nannyId);
    const snap = await getDocs(query(collection(db!, 'trials'), where('nannyId', '==', nannyId), limit(100)));
    return snap.docs.map((d) => parseTrial(d.id, d.data() as Record<string, unknown>));
  },
  async get(id: string): Promise<TrialAdminRow | null> {
    if (useMock()) return mockTrials.find((t) => t.id === id) ?? null;
    const snap = await getDoc(doc(db!, 'trials', id));
    return snap.exists() ? parseTrial(snap.id, snap.data() as Record<string, unknown>) : null;
  },
};

function parseTrial(id: string, data: Record<string, unknown>): TrialAdminRow {
  return {
    id,
    familyId: (data.familyId as string) ?? '',
    nannyId: (data.nannyId as string) ?? '',
    familyName: data.familyName as string | undefined,
    nannyName: data.nannyName as string | undefined,
    jobPostId: data.jobPostId as string | undefined,
    status: (data.status as string) ?? 'active',
    trialType: data.trialType as string | undefined,
    durationDays: (data.durationDays as number) ?? 0,
    dailyRate: (data.dailyRate as number) ?? 0,
    startDate: parseTimestamp(data.startDate),
    endDate: parseTimestamp(data.endDate),
    location: data.location as string | undefined,
    notes: data.notes as string | undefined,
    outcome: data.outcome as string | undefined,
    completedAt: toDateOrUndef(data.completedAt),
    rating: data.rating as number | undefined,
    evaluation: data.evaluation as TrialEvaluationRow | undefined,
    nannyConfirmedPayment: data.nannyConfirmedPayment as boolean | undefined,
    paymentIssueReported: data.paymentIssueReported as boolean | undefined,
  };
}

// ─────────────────────────────────────────────────────────
// Job posts service (admin read-only)
// ─────────────────────────────────────────────────────────
function parseJobPost(id: string, data: Record<string, unknown>): JobPostRow {
  return {
    id,
    familyId: (data.familyId as string) ?? '',
    familyName: data.familyName as string | undefined,
    status: (data.status as JobPostStatus) ?? 'active',
    createdAt: toDateOrUndef(data.createdAt),
    expiresAt: toDateOrUndef(data.expiresAt),
    jobTitle: data.jobTitle as string | undefined,
    rolesNeeded: (data.rolesNeeded as string[]) ?? [],
    jobType: data.jobType as JobType | undefined,
    schedule: data.schedule as string | undefined,
    startDate: toDateOrUndef(data.startDate),
    startImmediate: data.startImmediate as boolean | undefined,
    duration: data.duration as JobDuration | undefined,
    contractMonths: data.contractMonths as number | undefined,
    experienceYears: data.experienceYears as number | undefined,
    languagesRequired: (data.languagesRequired as string[]) ?? [],
    languagesPreferred: (data.languagesPreferred as string[]) ?? [],
    skillsRequired: (data.skillsRequired as string[]) ?? [],
    nationalityPreference: (data.nationalityPreference as string[]) ?? [],
    religionPreference: data.religionPreference as NannyReligionPreference | undefined,
    duties: (data.duties as string[]) ?? [],
    salaryMin: data.salaryMin as number | undefined,
    salaryMax: data.salaryMax as number | undefined,
    currency: (data.currency as string) ?? 'AED',
    benefits: (data.benefits as string[]) ?? [],
    visaSponsorship: data.visaSponsorship as VisaSponsorship | undefined,
    trialDurationDays: data.trialDurationDays as number | undefined,
    trialDailyRate: data.trialDailyRate as number | undefined,
    additionalNotes: data.additionalNotes as string | undefined,
    viewsCount: data.viewsCount as number | undefined,
    applicationsCount: data.applicationsCount as number | undefined,
    city: data.city as string | undefined,
  };
}

export const JobPostService = {
  async listByFamily(familyId: string): Promise<JobPostRow[]> {
    if (useMock()) return mockJobPosts.filter((j) => j.familyId === familyId);
    const snap = await getDocs(query(collection(db!, 'jobs'), where('familyId', '==', familyId), limit(100)));
    return snap.docs.map((d) => parseJobPost(d.id, d.data() as Record<string, unknown>));
  },
  async get(id: string): Promise<JobPostRow | null> {
    if (useMock()) return mockJobPosts.find((j) => j.id === id) ?? null;
    const snap = await getDoc(doc(db!, 'jobs', id));
    return snap.exists() ? parseJobPost(snap.id, snap.data() as Record<string, unknown>) : null;
  },
};

// ─────────────────────────────────────────────────────────
// Applications / offers service (admin read-only)
// ─────────────────────────────────────────────────────────
function parseApplication(id: string, data: Record<string, unknown>): ApplicationRow {
  return {
    id,
    jobPostId: (data.jobPostId as string) ?? '',
    jobTitle: data.jobTitle as string | undefined,
    nannyId: (data.nannyId as string) ?? '',
    nannyName: data.nannyName as string | undefined,
    familyId: (data.familyId as string) ?? '',
    familyName: data.familyName as string | undefined,
    status: (data.status as ApplicationStatus) ?? 'pending',
    matchScore: data.matchScore as number | undefined,
    coverMessage: data.coverMessage as string | undefined,
    createdAt: parseTimestamp(data.createdAt),
    respondedAt: toDateOrUndef(data.respondedAt),
  };
}

export const ApplicationService = {
  async listByFamily(familyId: string): Promise<ApplicationRow[]> {
    if (useMock()) return mockApplications.filter((a) => a.familyId === familyId);
    const snap = await getDocs(query(collection(db!, 'applications'), where('familyId', '==', familyId), limit(200)));
    return snap.docs.map((d) => parseApplication(d.id, d.data() as Record<string, unknown>));
  },
  async listByNanny(nannyId: string): Promise<ApplicationRow[]> {
    if (useMock()) return mockApplications.filter((a) => a.nannyId === nannyId);
    const snap = await getDocs(query(collection(db!, 'applications'), where('nannyId', '==', nannyId), limit(200)));
    return snap.docs.map((d) => parseApplication(d.id, d.data() as Record<string, unknown>));
  },
};

// ─────────────────────────────────────────────────────────
// Reviews / ratings service (admin read-only)
// ─────────────────────────────────────────────────────────
function parseReview(id: string, data: Record<string, unknown>): ReviewRow {
  return {
    id,
    reviewerId: (data.reviewerId as string) ?? '',
    reviewerName: data.reviewerName as string | undefined,
    reviewerType: (data.reviewerType as 'family' | 'nanny') ?? 'family',
    revieweeId: (data.revieweeId as string) ?? '',
    revieweeType: (data.revieweeType as 'family' | 'nanny') ?? 'nanny',
    trialId: data.trialId as string | undefined,
    rating: (data.rating as number) ?? 0,
    comment: data.comment as string | undefined,
    createdAt: parseTimestamp(data.createdAt),
  };
}

export const ReviewService = {
  async listForReviewee(userId: string): Promise<ReviewRow[]> {
    if (useMock()) return mockReviews.filter((r) => r.revieweeId === userId);
    const snap = await getDocs(query(collection(db!, 'reviews'), where('revieweeId', '==', userId), limit(200)));
    return snap.docs.map((d) => parseReview(d.id, d.data() as Record<string, unknown>));
  },
  /** Average rating + count for a given reviewee (nanny or family). */
  async averageFor(userId: string): Promise<{ average: number | null; count: number }> {
    const reviews = await this.listForReviewee(userId);
    if (reviews.length === 0) return { average: null, count: 0 };
    const sum = reviews.reduce((s, r) => s + r.rating, 0);
    return { average: sum / reviews.length, count: reviews.length };
  },
};

// ─────────────────────────────────────────────────────────
// Chat service (admin read-only — nanny ↔ family conversations)
// ─────────────────────────────────────────────────────────
function parseThread(id: string, data: Record<string, unknown>): ChatThreadRow {
  return {
    id,
    familyId: (data.familyId as string) ?? '',
    nannyId: (data.nannyId as string) ?? '',
    familyName: data.familyName as string | undefined,
    nannyName: data.nannyName as string | undefined,
    createdAt: parseTimestamp(data.createdAt),
    lastMessageAt: parseTimestamp(data.lastMessageAt),
    lastMessage: data.lastMessage as string | undefined,
    trialId: data.trialId as string | undefined,
    trialStatus: data.trialStatus as string | undefined,
    status: (data.status as 'active' | 'archived') ?? 'active',
  };
}

function parseMessage(id: string, data: Record<string, unknown>): ChatMessageRow {
  return {
    id,
    threadId: (data.threadId as string) ?? '',
    senderId: (data.senderId as string) ?? '',
    senderType: (data.senderType as 'nanny' | 'family') ?? 'family',
    content: (data.content as string) ?? '',
    type: data.type as ChatMessageType | undefined,
    trialOfferId: data.trialOfferId as string | undefined,
    createdAt: parseTimestamp(data.createdAt),
    readAt: toDateOrUndef(data.readAt),
  };
}

export const ChatService = {
  async listThreadsForNanny(nannyId: string): Promise<ChatThreadRow[]> {
    if (useMock()) return mockChatThreads.filter((t) => t.nannyId === nannyId);
    const snap = await getDocs(query(collection(db!, 'chatThreads'), where('nannyId', '==', nannyId), limit(100)));
    return snap.docs.map((d) => parseThread(d.id, d.data() as Record<string, unknown>));
  },
  async listThreadsForFamily(familyId: string): Promise<ChatThreadRow[]> {
    if (useMock()) return mockChatThreads.filter((t) => t.familyId === familyId);
    const snap = await getDocs(query(collection(db!, 'chatThreads'), where('familyId', '==', familyId), limit(100)));
    return snap.docs.map((d) => parseThread(d.id, d.data() as Record<string, unknown>));
  },
  async listMessages(threadId: string): Promise<ChatMessageRow[]> {
    if (useMock()) {
      return mockChatMessages
        .filter((m) => m.threadId === threadId)
        .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
    }
    const snap = await getDocs(
      query(collection(db!, 'chatThreads', threadId, 'messages'), orderBy('createdAt', 'asc'), limit(500)),
    );
    return snap.docs.map((d) => parseMessage(d.id, d.data() as Record<string, unknown>));
  },
  /** Find the conversation linked to a given trial (admin trial detail view). */
  async findThreadByTrial(trialId: string): Promise<ChatThreadRow | null> {
    if (useMock()) return mockChatThreads.find((t) => t.trialId === trialId) ?? null;
    const snap = await getDocs(query(collection(db!, 'chatThreads'), where('trialId', '==', trialId), limit(1)));
    const d = snap.docs[0];
    return d ? parseThread(d.id, d.data() as Record<string, unknown>) : null;
  },
};

// ─────────────────────────────────────────────────────────
// Disputes service
// ─────────────────────────────────────────────────────────
function parseDispute(id: string, data: Record<string, unknown>): DisputeRow {
  return {
    id,
    reporterId: (data.reporterId as string) ?? '',
    reporterName: data.reporterName as string | undefined,
    reporterType: data.reporterType as 'family' | 'nanny' | undefined,
    reportedUserId: (data.reportedUserId as string) ?? '',
    reportedName: data.reportedName as string | undefined,
    category: (data.category as DisputeRow['category']) ?? 'other',
    description: (data.description as string) ?? '',
    status: (data.status as DisputeRow['status']) ?? 'open',
    relatedTrialId: data.relatedTrialId as string | undefined,
    resolution: data.resolution as string | undefined,
    createdAt: parseTimestamp(data.createdAt),
  };
}

export const DisputeService = {
  async list(): Promise<DisputeRow[]> {
    if (useMock()) return mockDisputes;
    const snap = await getDocs(query(collection(db!, 'disputes'), orderBy('createdAt', 'desc'), limit(100)));
    return snap.docs.map((d) => parseDispute(d.id, d.data() as Record<string, unknown>));
  },
  async get(id: string): Promise<DisputeRow | null> {
    if (useMock()) return mockDisputes.find((d) => d.id === id) ?? null;
    const snap = await getDoc(doc(db!, 'disputes', id));
    return snap.exists() ? parseDispute(snap.id, snap.data() as Record<string, unknown>) : null;
  },
  async resolve(id: string, resolution: string, status: 'resolved' | 'dismissed'): Promise<void> {
    if (useMock()) {
      const i = mockDisputes.findIndex((d) => d.id === id);
      if (i >= 0) mockDisputes[i] = { ...mockDisputes[i], status, resolution };
      return;
    }
    await updateDoc(doc(db!, 'disputes', id), {
      status,
      resolution,
      resolvedAt: serverTimestamp(),
    });
  },
  // ── Support chat (admin ↔ reporting user) ──
  async listMessages(disputeId: string): Promise<DisputeMessageRow[]> {
    if (useMock()) {
      return mockDisputeMessages
        .filter((m) => m.disputeId === disputeId)
        .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
    }
    const snap = await getDocs(
      query(collection(db!, 'disputes', disputeId, 'messages'), orderBy('createdAt', 'asc'), limit(500)),
    );
    return snap.docs.map((d) => {
      const data = d.data() as Record<string, unknown>;
      return {
        id: d.id,
        disputeId,
        senderType: (data.senderType as 'admin' | 'user') ?? 'admin',
        senderName: data.senderName as string | undefined,
        content: (data.content as string) ?? '',
        createdAt: parseTimestamp(data.createdAt),
      };
    });
  },
  async sendMessage(disputeId: string, content: string, senderName = 'Support'): Promise<DisputeMessageRow> {
    if (useMock()) {
      const msg: DisputeMessageRow = {
        id: `dm_${mockDisputeMessages.length + 1}_${disputeId}`,
        disputeId,
        senderType: 'admin',
        senderName,
        content,
        createdAt: new Date(),
      };
      mockDisputeMessages.push(msg);
      // Move an open dispute to "investigating" once support replies.
      const i = mockDisputes.findIndex((d) => d.id === disputeId);
      if (i >= 0 && mockDisputes[i].status === 'open') {
        mockDisputes[i] = { ...mockDisputes[i], status: 'investigating' };
      }
      return msg;
    }
    const ref = await addDoc(collection(db!, 'disputes', disputeId, 'messages'), {
      senderType: 'admin',
      senderName,
      content,
      createdAt: serverTimestamp(),
    });
    return { id: ref.id, disputeId, senderType: 'admin', senderName, content, createdAt: new Date() };
  },
};

// ─────────────────────────────────────────────────────────
// Broadcast service
// ─────────────────────────────────────────────────────────
export const BroadcastService = {
  async send(audience: 'all' | 'nannies' | 'families' | 'subscribers', title: string, message: string): Promise<string> {
    if (useMock()) {
      await new Promise((r) => setTimeout(r, 400));
      return `mock_${Date.now()}`;
    }
    const ref = await addDoc(collection(db!, 'broadcasts'), {
      audience,
      title,
      message,
      createdAt: serverTimestamp(),
      status: 'queued',
    });
    return ref.id;
  },
  async listRecent(): Promise<{ id: string; audience: string; title: string; message: string; createdAt: Date }[]> {
    if (useMock()) return [];
    const snap = await getDocs(query(collection(db!, 'broadcasts'), orderBy('createdAt', 'desc'), limit(20)));
    return snap.docs.map((d) => {
      const data = d.data() as Record<string, unknown>;
      const c = data.createdAt;
      const createdAt = c && typeof (c as { toDate?: () => Date }).toDate === 'function'
        ? (c as { toDate: () => Date }).toDate()
        : new Date();
      return {
        id: d.id,
        audience: (data.audience as string) ?? 'all',
        title: (data.title as string) ?? '',
        message: (data.message as string) ?? '',
        createdAt,
      };
    });
  },
};

// ─────────────────────────────────────────────────────────
// Settings service
// ─────────────────────────────────────────────────────────
export const SettingsService = {
  async get() {
    if (useMock()) return mockSettings;
    const snap = await getDoc(doc(db!, 'settings', 'global'));
    if (!snap.exists()) return mockSettings;
    return { ...mockSettings, ...(snap.data() as typeof mockSettings) };
  },
  async update(patch: Partial<typeof mockSettings>): Promise<void> {
    if (useMock()) {
      Object.assign(mockSettings, patch);
      return;
    }
    await setDoc(doc(db!, 'settings', 'global'), patch, { merge: true });
  },
};

// ─────────────────────────────────────────────────────────
// Revenue/dashboard analytics
// ─────────────────────────────────────────────────────────
export interface RevenueSummary {
  monthly: number;
  vat: number;
  byPlan: { plan: string; subs: number; revenue: number }[];
  trend: { label: string; amount: number; pct: number }[];
}

export interface RevenueTransaction {
  id: string;
  familyId: string;
  familyName: string;
  plan: string;
  amount: number;
  status: 'paid' | 'refunded' | 'failed';
  createdAt: Date;
}

const mockTransactions: RevenueTransaction[] = [
  { id: 'tx1', familyId: 'f1', familyName: 'Al Mansoori Family', plan: 'monthly', amount: 239, status: 'paid', createdAt: new Date(Date.now() - 12 * 86400000) },
  { id: 'tx2', familyId: 'f2', familyName: 'James & Sarah K.', plan: 'twoMonths', amount: 369, status: 'paid', createdAt: new Date(Date.now() - 13 * 86400000) },
  { id: 'tx3', familyId: 'f4', familyName: 'Mohammed Al Rashid', plan: 'weekly', amount: 89, status: 'paid', createdAt: new Date(Date.now() - 10 * 86400000) },
  { id: 'tx4', familyId: 'f4', familyName: 'Mohammed Al Rashid', plan: 'weekly', amount: 89, status: 'failed', createdAt: new Date(Date.now() - 3 * 86400000) },
  { id: 'tx5', familyId: 'f3', familyName: 'Lin Chen', plan: 'monthly', amount: 239, status: 'refunded', createdAt: new Date(Date.now() - 7 * 86400000) },
  { id: 'tx6', familyId: 'f1', familyName: 'Al Mansoori Family', plan: 'monthly', amount: 239, status: 'paid', createdAt: new Date(Date.now() - 42 * 86400000) },
  { id: 'tx7', familyId: 'f2', familyName: 'James & Sarah K.', plan: 'twoMonths', amount: 369, status: 'paid', createdAt: new Date(Date.now() - 75 * 86400000) },
  { id: 'tx8', familyId: 'f3', familyName: 'Lin Chen', plan: 'monthly', amount: 239, status: 'paid', createdAt: new Date(Date.now() - 100 * 86400000) },
  { id: 'tx9', familyId: 'f4', familyName: 'Mohammed Al Rashid', plan: 'weekly', amount: 89, status: 'paid', createdAt: new Date(Date.now() - 130 * 86400000) },
  { id: 'tx10', familyId: 'f1', familyName: 'Al Mansoori Family', plan: 'monthly', amount: 239, status: 'paid', createdAt: new Date(Date.now() - 160 * 86400000) },
];

/** Bucket paid transactions into the last `months` calendar months (oldest →
 *  newest) so the revenue trend chart reflects real data. `pct` is relative to
 *  the best month so the tallest bar always fills the chart. */
function buildTrend(
  txns: { amount: number; status: RevenueTransaction['status']; createdAt: Date }[],
  months = 6,
): RevenueSummary['trend'] {
  const now = new Date();
  const buckets = Array.from({ length: months }, (_, i) => {
    const d = new Date(now.getFullYear(), now.getMonth() - (months - 1 - i), 1);
    return {
      key: `${d.getFullYear()}-${d.getMonth()}`,
      label: d.toLocaleDateString('en-GB', { month: 'short' }),
      amount: 0,
    };
  });
  const byKey = new Map(buckets.map((b) => [b.key, b]));
  txns.forEach((t) => {
    if (t.status !== 'paid') return;
    const b = byKey.get(`${t.createdAt.getFullYear()}-${t.createdAt.getMonth()}`);
    if (b) b.amount += t.amount;
  });
  const max = Math.max(...buckets.map((b) => b.amount), 1);
  return buckets.map((b) => ({ label: b.label, amount: b.amount, pct: Math.round((b.amount / max) * 100) }));
}

export const RevenueService = {
  async recentTransactions(): Promise<RevenueTransaction[]> {
    if (useMock()) return [...mockTransactions].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    const snap = await getDocs(query(collection(db!, 'transactions'), orderBy('createdAt', 'desc'), limit(50)));
    return snap.docs.map((d) => {
      const data = d.data() as Record<string, unknown>;
      return {
        id: d.id,
        familyId: (data.familyId as string) ?? '',
        familyName: (data.familyName as string) ?? '',
        plan: (data.plan as string) ?? '',
        amount: (data.amount as number) ?? 0,
        status: (data.status as RevenueTransaction['status']) ?? 'paid',
        createdAt: parseTimestamp(data.createdAt),
      };
    });
  },
  /** Full transaction history (no 50-row cap) for the Revenue page's
   *  client-side period filtering. Newest first. */
  async allTransactions(): Promise<RevenueTransaction[]> {
    if (useMock()) {
      return [...mockTransactions].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    }
    const snap = await getDocs(
      query(collection(db!, 'transactions'), orderBy('createdAt', 'desc')),
    );
    return snap.docs.map((d) => {
      const data = d.data() as Record<string, unknown>;
      return {
        id: d.id,
        familyId: (data.familyId as string) ?? '',
        familyName: (data.familyName as string) ?? '',
        plan: (data.plan as string) ?? '',
        amount: (data.amount as number) ?? 0,
        status: (data.status as RevenueTransaction['status']) ?? 'paid',
        createdAt: parseTimestamp(data.createdAt),
      };
    });
  },
  async summary(): Promise<RevenueSummary> {
    if (useMock()) {
      return {
        monthly: 10800,
        vat: 540,
        byPlan: [
          { plan: 'weekly', subs: 25, revenue: 2225 },
          { plan: 'monthly', subs: 30, revenue: 7170 },
          { plan: 'twoMonths', subs: 10, revenue: 3690 },
        ],
        trend: buildTrend(mockTransactions),
      };
    }
    const now = new Date();
    const trendStart = new Date(now.getFullYear(), now.getMonth() - 5, 1);
    const [families, txSnap] = await Promise.all([
      FamilyService.list(),
      getDocs(query(collection(db!, 'transactions'), where('createdAt', '>=', Timestamp.fromDate(trendStart)))),
    ]);
    const trendTxns = txSnap.docs.map((d) => {
      const data = d.data() as Record<string, unknown>;
      return {
        amount: (data.amount as number) ?? 0,
        status: (data.status as RevenueTransaction['status']) ?? 'paid',
        createdAt: parseTimestamp(data.createdAt),
      };
    });
    const planPrices: Record<string, number> = { weekly: 89, monthly: 239, twoMonths: 369 };
    const byPlanMap: Record<string, { subs: number; revenue: number }> = {};
    families.forEach((f) => {
      if (f.subscription.status === 'active' && f.subscription.plan) {
        const p = f.subscription.plan;
        const price = planPrices[p] ?? 0;
        byPlanMap[p] = {
          subs: (byPlanMap[p]?.subs ?? 0) + 1,
          revenue: (byPlanMap[p]?.revenue ?? 0) + price,
        };
      }
    });
    const monthly = Object.values(byPlanMap).reduce((s, x) => s + x.revenue, 0);
    return {
      monthly,
      vat: Math.round(monthly * 0.05),
      byPlan: Object.entries(byPlanMap).map(([plan, v]) => ({ plan, ...v })),
      trend: buildTrend(trendTxns),
    };
  },
};
