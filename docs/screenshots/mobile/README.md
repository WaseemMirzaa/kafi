# Kafi Mobile App — Screen Galleries (mock mode)

The mobile app screens are split by user flow. **Each flow is complete on its own** —
the screens shared between flows (welcome, OTP, create-password, notifications, terms,
privacy, password-reset, delete-account) appear in **both** galleries, each rendered in
that flow's own context (rose/nanny vs purple/family theme, and per-role notification
content). There is no separate "shared" gallery.

- **[Nanny flow — 23 screens](./nanny/README.md)**
- **[Family flow — 23 screens](./family/README.md)**

Captured as Flutter web in mock mode, driven with Playwright at a tall mobile viewport and
content-cropped. A seeded demo session (an approved nanny / a subscribed family) is injected
so data-rich screens render real content. See `docs/LIVE_MODE_SETUP.md` to run live.
