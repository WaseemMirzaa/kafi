# Kafi — Screen Screenshots (mock mode)

Screen-by-screen captures of both deployables, produced in **mock mode** (seeded
demo data, no live Firebase). Full-height images so scrollable screens show all
fields/data.

- **[Mobile app — 37 screens](./mobile/README.md)** (Flutter)
- **[Admin panel — 14 screens](./admin/README.md)** (React/Vite)

## How these were generated

- Mobile: `flutter build web --no-web-resources-cdn` with `useMock = true`, served
  locally and driven with Playwright/Chromium at a tall mobile viewport (430×2600 @2x)
  so each screen renders its full scrollable content into one image. Google Fonts are
  fulfilled through the environment proxy; the browser locale is pinned to `en-US`.
- Admin: `npm run dev` (mock) driven with Playwright at 1440×900 @2x, full-page.
- See `scripts/materialize-secrets.sh` + `docs/LIVE_MODE_SETUP.md` to run either in
  **live** mode against real Firebase.

## Notes on data state

Most screens show seeded mock data (e.g. browse match cards, admin dashboards).
A few flows are argument-driven (job detail, smart match, compare) and their direct
routes show an empty/placeholder state — noted per screen. Some auth-gated tiles
render their unauthenticated state because the mock session is not fully signed in.
