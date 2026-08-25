import { TrialAdminRow } from '../services/firestore';
import { t } from '../locales/t';

/** Day X of Y, matching the mobile app (day = ceil(elapsed since start)). */
export function trialDayNumber(row: Pick<TrialAdminRow, 'startDate'>): number {
  return Math.max(1, Math.ceil((Date.now() - row.startDate.getTime()) / 86400000));
}

/** "4d 23h 12m" countdown to the trial end, mirroring TrialModel.remaining. */
export function trialCountdown(row: Pick<TrialAdminRow, 'endDate'>): string {
  const ms = row.endDate.getTime() - Date.now();
  if (ms <= 0) return t('trials.countdownExpired');
  const d = Math.floor(ms / 86400000);
  const h = Math.floor((ms % 86400000) / 3600000);
  const m = Math.floor((ms % 3600000) / 60000);
  return t('trials.countdownFull', { d, h, m });
}

/** Short "4d 23h left" used in compact rows. */
export function trialShortLeft(row: Pick<TrialAdminRow, 'endDate'>): string {
  const ms = row.endDate.getTime() - Date.now();
  if (ms <= 0) return t('trials.countdownShortExpired');
  const d = Math.floor(ms / 86400000);
  const h = Math.floor((ms % 86400000) / 3600000);
  return t('trials.countdownShort', { d, h });
}

export function trialTotalAmount(t: Pick<TrialAdminRow, 'dailyRate' | 'durationDays'>): number {
  return t.dailyRate * t.durationDays;
}
