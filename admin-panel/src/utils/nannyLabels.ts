// Human-readable labels for the nanny enums mirrored from the Flutter app
// (`lib/models/nanny_model.dart`). Kept in one place so the listing, detail
// screen and CSV export stay consistent. Every label resolves through `t()`
// so it re-renders in the active locale (see `nannyLabels.*` keys in
// `locales/en.ts` / `locales/ar.ts`).
import type {
  VisaStatus,
  AvailabilityStatus,
  JobTypePreference,
  MaritalStatus,
  Emirate,
  NannyReligionPreference,
  JobType,
  JobDuration,
  VisaSponsorship,
  JobPostStatus,
  ApplicationStatus,
  NannyRow,
  FamilyRow,
  TrialStatus,
  DisputeRow,
  TicketRow,
} from '../services/firestore';
import { t, getLocale } from '../locales/t';
import type { TranslationKey } from '../locales/en';

const dash = () => t('common.dash');

function mapLabel<T extends string>(map: Record<T, TranslationKey>, key?: T | null): string {
  if (!key) return dash();
  const translationKey = map[key];
  return translationKey ? t(translationKey) : String(key);
}

const visaStatusKeys: Record<VisaStatus, TranslationKey> = {
  visit: 'nannyLabels.visaStatus.visit',
  residenceSponsored: 'nannyLabels.visaStatus.residenceSponsored',
  ownResidence: 'nannyLabels.visaStatus.ownResidence',
  cancelled: 'nannyLabels.visaStatus.cancelled',
  outsideUae: 'nannyLabels.visaStatus.outsideUae',
};
export const visaStatusLabel = (status?: VisaStatus | null): string => mapLabel(visaStatusKeys, status);

const availabilityKeys: Record<AvailabilityStatus, TranslationKey> = {
  availableNow: 'nannyLabels.availability.availableNow',
  availableFrom: 'nannyLabels.availability.availableFrom',
  onTrial: 'nannyLabels.availability.onTrial',
};
export const availabilityLabel = (status?: AvailabilityStatus | null): string => mapLabel(availabilityKeys, status);

const jobTypeKeys: Record<JobTypePreference, TranslationKey> = {
  liveIn: 'nannyLabels.jobType.liveIn',
  liveOut: 'nannyLabels.jobType.liveOut',
  both: 'nannyLabels.jobType.both',
};
export const jobTypeLabel = (pref?: JobTypePreference | null): string => mapLabel(jobTypeKeys, pref);

const maritalStatusKeys: Record<MaritalStatus, TranslationKey> = {
  married: 'nannyLabels.maritalStatus.married',
  single: 'nannyLabels.maritalStatus.single',
  divorced: 'nannyLabels.maritalStatus.divorced',
  widowed: 'nannyLabels.maritalStatus.widowed',
};
export const maritalStatusLabel = (status?: MaritalStatus | null): string => mapLabel(maritalStatusKeys, status);

const emirateKeys: Record<Emirate, TranslationKey> = {
  dubai: 'nannyLabels.emirate.dubai',
  abuDhabi: 'nannyLabels.emirate.abuDhabi',
  sharjah: 'nannyLabels.emirate.sharjah',
  ajman: 'nannyLabels.emirate.ajman',
  rak: 'nannyLabels.emirate.rak',
  fujairah: 'nannyLabels.emirate.fujairah',
  uaq: 'nannyLabels.emirate.uaq',
  alAin: 'nannyLabels.emirate.alAin',
};
export const emirateLabel = (emirate: Emirate): string => t(emirateKeys[emirate] ?? emirate as TranslationKey);

export const yesNo = (v?: boolean): string => (v === undefined ? dash() : v ? t('common.yes') : t('common.no'));

export function salaryRange(min?: number, max?: number): string {
  if (min == null && max == null) return dash();
  if (min != null && max != null) return `AED ${min.toLocaleString()}–${max.toLocaleString()}`;
  const v = (min ?? max)!;
  return `AED ${v.toLocaleString()}`;
}

export function emiratesList(list?: Emirate[]): string {
  if (!list || list.length === 0) return dash();
  return list.map((e) => emirateLabel(e)).join(', ');
}

export function listOr(list?: string[]): string {
  if (!list || list.length === 0) return dash();
  return list.join(', ');
}

export function formatDate(iso?: string): string {
  if (!iso) return dash();
  const d = new Date(iso);
  if (isNaN(d.getTime())) return iso;
  return d.toLocaleDateString(getLocale() === 'ar' ? 'ar-AE' : 'en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
}

/** Format a Date (not ISO string) — used by family/job/trial rows. */
export function fmtDate(d?: Date | null): string {
  if (!d) return dash();
  return d.toLocaleDateString(getLocale() === 'ar' ? 'ar-AE' : 'en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
}

// ── Family / job-creation labels ──
const religionPreferenceKeys: Record<NannyReligionPreference, TranslationKey> = {
  noPreference: 'nannyLabels.religionPreference.noPreference',
  preferMuslim: 'nannyLabels.religionPreference.preferMuslim',
  preferSame: 'nannyLabels.religionPreference.preferSame',
  openWithRespect: 'nannyLabels.religionPreference.openWithRespect',
};
export const religionPreferenceLabel = (pref?: NannyReligionPreference | null): string =>
  mapLabel(religionPreferenceKeys, pref);

const jobTypeFullKeys: Record<JobType, TranslationKey> = {
  liveIn: 'nannyLabels.jobTypeFull.liveIn',
  liveOut: 'nannyLabels.jobTypeFull.liveOut',
};
export const jobTypeFullLabel = (type?: JobType | null): string => mapLabel(jobTypeFullKeys, type);

const jobDurationKeys: Record<JobDuration, TranslationKey> = {
  permanent: 'nannyLabels.jobDuration.permanent',
  contract: 'nannyLabels.jobDuration.contract',
};
export const jobDurationLabel = (duration?: JobDuration | null): string => mapLabel(jobDurationKeys, duration);

const visaSponsorshipKeys: Record<VisaSponsorship, TranslationKey> = {
  full: 'nannyLabels.visaSponsorship.full',
  shared: 'nannyLabels.visaSponsorship.shared',
  residenceOnly: 'nannyLabels.visaSponsorship.residenceOnly',
  none: 'nannyLabels.visaSponsorship.none',
};
export const visaSponsorshipLabel = (sponsorship?: VisaSponsorship | null): string =>
  mapLabel(visaSponsorshipKeys, sponsorship);

const jobPostStatusKeys: Record<JobPostStatus, TranslationKey> = {
  active: 'nannyLabels.jobPostStatus.active',
  paused: 'nannyLabels.jobPostStatus.paused',
  closed: 'nannyLabels.jobPostStatus.closed',
  expired: 'nannyLabels.jobPostStatus.expired',
};
export const jobPostStatusLabel = (status: JobPostStatus): string => mapLabel(jobPostStatusKeys, status);

const applicationStatusKeys: Record<ApplicationStatus, TranslationKey> = {
  pending: 'nannyLabels.applicationStatus.pending',
  viewed: 'nannyLabels.applicationStatus.viewed',
  shortlisted: 'nannyLabels.applicationStatus.shortlisted',
  trialOffered: 'nannyLabels.applicationStatus.trialOffered',
  declined: 'nannyLabels.applicationStatus.declined',
  withdrawn: 'nannyLabels.applicationStatus.withdrawn',
  hired: 'nannyLabels.applicationStatus.hired',
};
export const applicationStatusLabel = (status: ApplicationStatus): string => mapLabel(applicationStatusKeys, status);

/** Maps a status string to a StatusBadge variant. */
export function applicationStatusVariant(s: ApplicationStatus): string {
  switch (s) {
    case 'hired':
      return 'verified';
    case 'shortlisted':
    case 'trialOffered':
      return 'new';
    case 'declined':
    case 'withdrawn':
      return 'rejected';
    default:
      return 'pending';
  }
}

export function trialStatusVariant(s: string): string {
  switch (s) {
    case 'completed':
    case 'accepted':
      return 'verified';
    case 'active':
    case 'awaitingOutcome':
      return 'new';
    case 'cancelled':
    case 'declined':
      return 'rejected';
    default:
      return 'pending';
  }
}

export function jobStatusVariant(s: JobPostStatus): string {
  switch (s) {
    case 'active':
      return 'verified';
    case 'paused':
      return 'pending';
    default:
      return 'rejected';
  }
}

// ── Cross-domain status/enum labels (nanny profile, docs, subscriptions,
//    trials, disputes, tickets) — shared so every badge/filter renders in the
//    active locale instead of the raw Firestore enum value. ──

const nannyProfileStatusKeys: Record<NannyRow['status'], TranslationKey> = {
  draft: 'nannies.draft',
  pending: 'nannies.pending',
  approved: 'nannies.approved',
  rejected: 'nannies.rejected',
};
export const nannyProfileStatusLabel = (status: NannyRow['status']): string =>
  mapLabel(nannyProfileStatusKeys, status);

/** Per-document verification status (`missing`/`uploaded`/`reviewing` plus
 *  the shared `pending`/`approved`/`rejected` review outcomes). */
const docStatusKeys: Record<string, TranslationKey> = {
  missing: 'nannies.docStatus.missing',
  uploaded: 'nannies.docStatus.uploaded',
  reviewing: 'nannies.docStatus.reviewing',
  pending: 'nannies.pending',
  approved: 'nannies.approved',
  rejected: 'nannies.rejected',
};
export const docStatusLabel = (status?: string | null): string =>
  status ? (docStatusKeys[status] ? t(docStatusKeys[status]) : status) : dash();

const subscriptionStatusKeys: Record<FamilyRow['subscription']['status'], TranslationKey> = {
  free: 'families.subscriptionStatus.free',
  active: 'families.subscriptionStatus.active',
  cancelled: 'families.subscriptionStatus.cancelled',
  expired: 'families.subscriptionStatus.expired',
  paymentFailed: 'families.subscriptionStatus.paymentFailed',
};
export const subscriptionStatusLabel = (status: FamilyRow['subscription']['status']): string =>
  mapLabel(subscriptionStatusKeys, status);

const subscriptionPlanKeys: Record<string, TranslationKey> = {
  weekly: 'dashboard.plan.weekly',
  monthly: 'dashboard.plan.monthly',
  twoMonths: 'dashboard.plan.twoMonths',
};
export const subscriptionPlanLabel = (plan?: string | null): string =>
  plan ? (subscriptionPlanKeys[plan] ? t(subscriptionPlanKeys[plan]) : plan) : dash();

const trialStatusKeys: Record<TrialStatus, TranslationKey> = {
  pending: 'trials.pending',
  countered: 'trials.countered',
  accepted: 'trials.accepted',
  declined: 'trials.declined',
  active: 'trials.active',
  awaitingOutcome: 'trials.awaitingOutcome',
  completed: 'trials.completed',
  cancelled: 'trials.cancelled',
};
export const trialStatusLabel = (status: TrialStatus | string): string =>
  mapLabel(trialStatusKeys, status as TrialStatus);

const trialOutcomeSideKeys: Record<string, TranslationKey> = {
  hired: 'trials.outcomeHired',
  notHired: 'trials.outcomeNotHired',
};

/** One-line outcome summary for list/detail rows. Falls back to the legacy
 *  single-sided `outcome` field for trials recorded before the mutual-confirm
 *  model (familyOutcome/nannyOutcome) shipped. */
export function trialOutcomeSummary(trial: {
  outcome?: string;
  familyOutcome?: string;
  nannyOutcome?: string;
}): string {
  if (trial.familyOutcome || trial.nannyOutcome) {
    const family = trial.familyOutcome ? trialOutcomeSideKeys[trial.familyOutcome] ? t(trialOutcomeSideKeys[trial.familyOutcome]) : trial.familyOutcome : t('trials.outcomeAwaiting');
    const nanny = trial.nannyOutcome ? trialOutcomeSideKeys[trial.nannyOutcome] ? t(trialOutcomeSideKeys[trial.nannyOutcome]) : trial.nannyOutcome : t('trials.outcomeAwaiting');
    return `${t('trials.familyOutcome')}: ${family} · ${t('trials.nannyOutcome')}: ${nanny}`;
  }
  return trial.outcome ?? '';
}

const disputeStatusKeys: Record<DisputeRow['status'], TranslationKey> = {
  open: 'reports.open',
  investigating: 'reports.investigating',
  resolved: 'reports.resolved',
  dismissed: 'reports.dismissed',
};
export const disputeStatusLabel = (status: DisputeRow['status']): string =>
  mapLabel(disputeStatusKeys, status);

const ticketStatusKeys: Record<TicketRow['status'], TranslationKey> = {
  open: 'support.open',
  investigating: 'support.inProgress',
  resolved: 'support.resolved',
  closed: 'support.closed',
};
export const ticketStatusLabel = (status: TicketRow['status']): string =>
  mapLabel(ticketStatusKeys, status);

const personTypeKeys: Record<'family' | 'nanny', TranslationKey> = {
  family: 'trials.family',
  nanny: 'trials.nanny',
};
export const personTypeLabel = (type?: 'family' | 'nanny' | null): string =>
  type ? mapLabel(personTypeKeys, type) : dash();
