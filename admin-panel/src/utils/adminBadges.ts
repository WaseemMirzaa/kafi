/** Dispatched after admin actions that change sidebar badge counts. */
export const ADMIN_BADGES_REFRESH = 'kafi-admin-badges-refresh';

/** Ask the sidebar to re-fetch nav badge counts (pending docs, trials, etc.). */
export function refreshAdminBadges(): void {
  if (typeof window === 'undefined') return;
  window.dispatchEvent(new Event(ADMIN_BADGES_REFRESH));
}
