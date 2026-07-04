# Kafi Mobile App — Screen Galleries (mock mode)

The mobile app screens are split by user flow, each with its own gallery:

- **[Nanny flow — 15 screens](./nanny/README.md)**
- **[Family flow — 15 screens](./family/README.md)**
- **[Shared screens — 8 screens](./shared/README.md)** (welcome, OTP, password, notifications, legal)

Captured as Flutter web in **mock mode** (`useMock = true`), driven with Playwright at a
tall mobile viewport and content-cropped. A seeded demo session (an approved nanny /
a subscribed family) is injected so data-rich screens render real content. See
`docs/LIVE_MODE_SETUP.md` to run live.
