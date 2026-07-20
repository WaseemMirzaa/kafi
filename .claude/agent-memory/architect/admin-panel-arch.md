---
name: admin-panel-arch
description: Kafi admin panel (React/TS) architecture — shared UI primitives, list-controls pattern, firestore service layer, mock mode. Reuse these before writing new UI/data code.
metadata:
  type: project
---

Kafi admin panel lives at `admin-panel/src/`. React + TypeScript + Tailwind. Design system is hand-rolled, not a 3rd-party kit.

**Why:** Future plans must reuse these primitives instead of inventing new UI or data-access code — that is the project's enforced Quality Bar.

**How to apply:**

- Shared UI primitives in `components/ui/AdminUI.tsx`: `PageShell`, `PageHeader`, `PageContent`, `TableCard`, `Row`, `StatusBadge`, `TopStat`, `ColStat`, `BarRow`, `Avatar`. Pages compose these — never hand-roll cards/rows.
- `StatusBadge` variants: `active`/`verified`/`sub` = green, `pending`/`verify` = amber, `rejected`/`unsub` = rose, `new` = purple. Unknown variant falls back to `pending`.
- Listing/filter pattern: `hooks/useListControls.ts` (search + date-range `from`/`to` + pagination, pageSize default 8) paired with `components/ui/ListControls.tsx` exports `FilterBar` (search box + date-range row, extra controls via children), `FilterSelect` (labeled dropdown), `Pagination`. Reference implementations: `pages/trials/AllTrials.tsx`, `pages/nannies/AllNannies.tsx`, `pages/nannies/VerifyDocuments.tsx`. `FilterBar` date inputs are native `<input type="date">` returning `YYYY-MM-DD` strings; `useListControls` includes the whole "to" day (+86399999ms).
- Design tokens (hardcoded hex, used consistently): muted text `#8090B0`, card borders `#EBEEF8`/`#F4F5FC`, track bg `#F0F1FA`, plan colors weekly `#FFB347`, monthly `#9B6EDB`, twoMonths `#2E9A58`, rose accent `#FF8FAB`/`#FF5C8A`. Button classes `qa-btn` + `qa-g`/`qa-p`/`qa-r`/`qa-n` defined in `index.css`.
- Data layer: `services/firestore.ts` — all services (NannyService, FamilyService, TrialService, RevenueService). Every method checks `useMock()` (`AppConfig.useMock || !db`) and returns mock data when true, else queries Firestore. `parseTimestamp()` normalizes Firestore Timestamps to Date. Plan prices: weekly 89, monthly 239, twoMonths 369 AED.
- `RevenueService.summary()` returns `{ monthly, vat, byPlan[], trend[] }`; `byPlan` is computed from *active subscriptions* (not paid transactions) in live mode. `recentTransactions()` caps at `limit(50)` in live mode. `buildTrend()` buckets paid txns into last N calendar months.
- CSV export: `utils/csv.ts` `exportCsv(filename, rows, columns)`.
- Mock mode is first-class — every service path and every new query must have a mock branch or it breaks the demo build.
