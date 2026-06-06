// Human-readable labels for the nanny enums mirrored from the Flutter app
// (`lib/models/nanny_model.dart`). Kept in one place so the listing, detail
// screen and CSV export stay consistent.
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
} from '../services/firestore';

export const visaStatusLabel: Record<VisaStatus, string> = {
  visit: 'Visit visa',
  residenceSponsored: 'Residence (sponsored)',
  ownResidence: 'Own residence',
  cancelled: 'Visa cancelled',
  outsideUae: 'Outside UAE',
};

export const availabilityLabel: Record<AvailabilityStatus, string> = {
  availableNow: 'Available now',
  availableFrom: 'Available from',
  onTrial: 'On trial',
};

export const jobTypeLabel: Record<JobTypePreference, string> = {
  liveIn: 'Live-in',
  liveOut: 'Live-out',
  both: 'Live-in or out',
};

export const maritalStatusLabel: Record<MaritalStatus, string> = {
  married: 'Married',
  single: 'Single',
  divorced: 'Divorced',
  widowed: 'Widowed',
};

export const emirateLabel: Record<Emirate, string> = {
  dubai: 'Dubai',
  abuDhabi: 'Abu Dhabi',
  sharjah: 'Sharjah',
  ajman: 'Ajman',
  rak: 'Ras Al Khaimah',
  fujairah: 'Fujairah',
  uaq: 'Umm Al Quwain',
  alAin: 'Al Ain',
};

/** Look up a label from a map, falling back to the raw key if unmapped. */
export function label<T extends string>(map: Record<T, string>, key?: T | null): string {
  if (!key) return '—';
  return map[key] ?? String(key);
}

export const yesNo = (v?: boolean): string => (v === undefined ? '—' : v ? 'Yes' : 'No');

export function salaryRange(min?: number, max?: number): string {
  if (min == null && max == null) return '—';
  if (min != null && max != null) return `AED ${min.toLocaleString()}–${max.toLocaleString()}`;
  const v = (min ?? max)!;
  return `AED ${v.toLocaleString()}`;
}

export function emiratesList(list?: Emirate[]): string {
  if (!list || list.length === 0) return '—';
  return list.map((e) => emirateLabel[e] ?? e).join(', ');
}

export function listOr(list?: string[]): string {
  if (!list || list.length === 0) return '—';
  return list.join(', ');
}

export function formatDate(iso?: string): string {
  if (!iso) return '—';
  const d = new Date(iso);
  if (isNaN(d.getTime())) return iso;
  return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
}

/** Format a Date (not ISO string) — used by family/job/trial rows. */
export function fmtDate(d?: Date | null): string {
  if (!d) return '—';
  return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
}

// ── Family / job-creation labels ──
export const religionPreferenceLabel: Record<NannyReligionPreference, string> = {
  noPreference: 'No preference',
  preferMuslim: 'Prefer Muslim nanny',
  preferSame: 'Prefer same religion',
  openWithRespect: 'Open — must respect house rules',
};

export const jobTypeFullLabel: Record<JobType, string> = {
  liveIn: 'Live-in',
  liveOut: 'Live-out',
};

export const jobDurationLabel: Record<JobDuration, string> = {
  permanent: 'Permanent',
  contract: 'Contract',
};

export const visaSponsorshipLabel: Record<VisaSponsorship, string> = {
  full: 'Full sponsorship',
  shared: 'Shared sponsorship',
  residenceOnly: 'Residence only',
  none: 'No sponsorship',
};

export const jobPostStatusLabel: Record<JobPostStatus, string> = {
  active: 'Active',
  paused: 'Paused',
  closed: 'Closed',
  expired: 'Expired',
};

export const applicationStatusLabel: Record<ApplicationStatus, string> = {
  pending: 'Pending',
  viewed: 'Viewed',
  shortlisted: 'Shortlisted',
  trialOffered: 'Trial offered',
  declined: 'Declined',
  withdrawn: 'Withdrawn',
  hired: 'Hired',
};

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
