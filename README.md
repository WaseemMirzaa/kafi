# Kafi Platform

| Folder | Stack |
|--------|--------|
| `kafi_app/` | Flutter 3.35.7 (FVM) + GetX — mock mode by default |
| `admin-panel/` | React 18 + TypeScript + Vite + Tailwind |
| `functions/` | Firebase Cloud Functions (Node 20) |

## Quick start

```bash
# Mobile (mock mode)
cd kafi_app && fvm flutter pub get && fvm flutter run

# Admin
cd admin-panel && npm install && npm run dev

# Functions
cd functions && npm install && npm run build
```

Docs: `KAFI_APP_DOCUMENTATION.md`, `KAFI_SYSTEM_SPECIFICATION.md`, `KAFI_TECHNICAL_ARCHITECTURE.md`
