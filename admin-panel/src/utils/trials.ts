import { TrialAdminRow } from '../services/firestore';

/** Day X of Y, matching the mobile app (day = ceil(elapsed since start)). */
export function trialDayNumber(t: Pick<TrialAdminRow, 'startDate'>): number {
  return Math.max(1, Math.ceil((Date.now() - t.startDate.getTime()) / 86400000));
}

/** "4d 23h 12m" countdown to the trial end, mirroring TrialModel.remaining. */
export function trialCountdown(t: Pick<TrialAdminRow, 'endDate'>): string {
  const ms = t.endDate.getTime() - Date.now();
  if (ms <= 0) return '0d 0h 0m';
  const d = Math.floor(ms / 86400000);
  const h = Math.floor((ms % 86400000) / 3600000);
  const m = Math.floor((ms % 3600000) / 60000);
  return `${d}d ${h}h ${m}m`;
}

/** Short "4d 23h left" used in compact rows. */
export function trialShortLeft(t: Pick<TrialAdminRow, 'endDate'>): string {
  const ms = t.endDate.getTime() - Date.now();
  if (ms <= 0) return '0d 0h left';
  const d = Math.floor(ms / 86400000);
  const h = Math.floor((ms % 86400000) / 3600000);
  return `${d}d ${h}h left`;
}

export function trialTotalAmount(t: Pick<TrialAdminRow, 'dailyRate' | 'durationDays'>): number {
  return t.dailyRate * t.durationDays;
}
