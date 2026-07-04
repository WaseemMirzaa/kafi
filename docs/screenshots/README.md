# Kafi — Screen Screenshots (mock mode)

Screen-by-screen captures of both deployables, in **mock mode** (seeded demo data,
no live Firebase). Content-cropped, full-height images.

- **[Mobile app — 37 screens, grouped by flow](./mobile/README.md)** (Flutter)
- **[Admin panel — 14 pages](./admin/README.md)** (React/Vite)

## How these were generated
- Mobile: `flutter build web --no-web-resources-cdn` with `useMock = true`, served
  locally and driven with Playwright/Chromium at a tall mobile viewport. A seeded demo
  session (`mock_family_1`) is injected so data screens populate; images are then
  content-cropped. Google Fonts via the environment proxy; locale `en-US`.
- Admin: `npm run dev` (mock) driven full-page at 1440×900.
- See `docs/LIVE_MODE_SETUP.md` + `scripts/materialize-secrets.sh` to run live.
