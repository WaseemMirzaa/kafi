#!/usr/bin/env bash
# Materialize Kafi live-mode secrets from environment variables into the repo.
#
# Intended as the Claude Code on the web environment "setup script" (or invoked
# from a .claude SessionStart hook). Idempotent — safe to run every session.
# See docs/LIVE_MODE_SETUP.md for the full variable list. Never commit the files
# this produces; they are gitignored secrets.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

decode() { # $1 = env var name, $2 = destination path
  local val="${!1:-}"
  if [ -n "$val" ]; then
    mkdir -p "$(dirname "$2")"
    printf '%s' "$val" | base64 -d > "$2" && echo "  wrote $2"
  else
    echo "  skip $2 (\$$1 not set)"
  fi
}

echo "[materialize-secrets] platform Firebase files"
decode GOOGLE_SERVICES_JSON_B64      "$ROOT/kafi_app/android/app/google-services.json"
decode GOOGLE_SERVICE_INFO_PLIST_B64 "$ROOT/kafi_app/ios/Runner/GoogleService-Info.plist"
decode FIREBASE_SA_JSON_B64          "$ROOT/scripts/service-account.json"

echo "[materialize-secrets] admin-panel/.env"
if [ -n "${VITE_FIREBASE_API_KEY:-}" ]; then
  cat > "$ROOT/admin-panel/.env" <<EOF
VITE_USE_MOCK=false
VITE_FIREBASE_API_KEY=${VITE_FIREBASE_API_KEY}
VITE_FIREBASE_AUTH_DOMAIN=${VITE_FIREBASE_AUTH_DOMAIN:-}
VITE_FIREBASE_PROJECT_ID=${VITE_FIREBASE_PROJECT_ID:-}
VITE_FIREBASE_STORAGE_BUCKET=${VITE_FIREBASE_STORAGE_BUCKET:-}
VITE_FIREBASE_MESSAGING_SENDER_ID=${VITE_FIREBASE_MESSAGING_SENDER_ID:-}
VITE_FIREBASE_APP_ID=${VITE_FIREBASE_APP_ID:-}
EOF
  echo "  wrote admin-panel/.env"
else
  echo "  skip admin-panel/.env (VITE_FIREBASE_API_KEY not set)"
fi

echo "[materialize-secrets] Google Maps key"
if [ -n "${GOOGLE_MAPS_API_KEY:-}" ]; then
  K="$GOOGLE_MAPS_API_KEY"
  sed -i "s/YOUR_GOOGLE_MAPS_API_KEY/$K/g" \
    "$ROOT/kafi_app/lib/utils/constants/app_constants.dart" \
    "$ROOT/kafi_app/android/app/src/main/AndroidManifest.xml" \
    "$ROOT/kafi_app/ios/Runner/AppDelegate.swift" 2>/dev/null || true
  if ! grep -q "maps.googleapis.com" "$ROOT/kafi_app/web/index.html"; then
    sed -i "s#</head>#  <script src=\"https://maps.googleapis.com/maps/api/js?key=${K}\&libraries=places\"></script>\n</head>#" \
      "$ROOT/kafi_app/web/index.html"
  fi
  echo "  injected Maps key (native x3 + web)"
else
  echo "  skip Maps key (GOOGLE_MAPS_API_KEY not set)"
fi

echo "[materialize-secrets] done. Remaining manual steps: flutterfire configure"
echo "  (firebase_options.dart), set-admin-claims.ts, firebase deploy — see"
echo "  docs/LIVE_MODE_SETUP.md."
