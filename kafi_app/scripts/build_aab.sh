#!/usr/bin/env bash
#
# Build a Play Store–ready Android App Bundle (AAB) signed with the release keystore.
#
# Prereqs:
#   • android/key.properties + android/upload-keystore.jks (git-ignored)
#   • android/app/google-services.json for live Firebase
#   • AppConfig.useMock = false
#
# Usage:
#   scripts/build_aab.sh
#
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_DIR"

KEY_PROPS="android/key.properties"
if [[ ! -f "$KEY_PROPS" ]]; then
  cat >&2 <<EOF
ERROR: $KEY_PROPS not found.

Create a release keystore and key.properties (see BUILD_APK.md § Release signing).
EOF
  exit 1
fi

GS="android/app/google-services.json"
if [[ ! -f "$GS" ]]; then
  echo "ERROR: $GS not found (needed for live Firebase)." >&2
  exit 1
fi

if grep -qE 'useMock\s*=\s*true' lib/config/app_config.dart; then
  echo "ERROR: AppConfig.useMock is true — set it to false for a Play build." >&2
  exit 1
fi

FLUTTER="${FLUTTER:-flutter}"
if ! command -v "$FLUTTER" >/dev/null 2>&1; then
  if [[ -x /Users/macuser/fvm/versions/3.38.10/bin/flutter ]]; then
    FLUTTER=/Users/macuser/fvm/versions/3.38.10/bin/flutter
  else
    echo "ERROR: flutter not on PATH." >&2
    exit 1
  fi
fi

echo "==> $FLUTTER pub get"
"$FLUTTER" pub get

echo "==> $FLUTTER build appbundle --release"
"$FLUTTER" build appbundle --release

AAB="build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "AAB built: $APP_DIR/$AAB"
ls -lh "$AAB"
echo ""
echo "Upload this file in Google Play Console."
