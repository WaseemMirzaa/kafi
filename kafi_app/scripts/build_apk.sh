#!/usr/bin/env bash
#
# Build an installable Android APK for Kafi against LIVE Firebase.
#
# Prereqs (one-time):
#   • Flutter SDK on PATH            — flutter --version   (repo uses 3.44.x)
#   • Android SDK / Android Studio   — flutter doctor must show Android ✓
#     (accept licenses once: flutter doctor --android-licenses)
#   • Firebase Android config at:    android/app/google-services.json  (git-ignored)
#     Download from Firebase console → Project settings → your Android app
#     (package com.kafi.kafi_app) → "google-services.json".
#
# Usage:
#   scripts/build_apk.sh            # release APK (debug-signed; installable)
#   scripts/build_apk.sh debug      # debug APK
#
set -euo pipefail

MODE="${1:-release}"
if [[ "$MODE" != "release" && "$MODE" != "debug" ]]; then
  echo "Usage: $0 [release|debug]" >&2
  exit 2
fi

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_DIR"

GS="android/app/google-services.json"
if [[ ! -f "$GS" ]]; then
  cat >&2 <<EOF
ERROR: $GS not found.

Live Firebase needs the Android config. Download google-services.json from the
Firebase console (Android app: com.kafi.kafi_app) and place it at:
  kafi_app/$GS
then re-run. It is git-ignored and never committed. See FIREBASE_SETUP.md.
EOF
  exit 1
fi

# Live Firebase requires AppConfig.useMock = false.
if grep -qE 'useMock\s*=\s*true' lib/config/app_config.dart; then
  echo "ERROR: AppConfig.useMock is true — set it to false for a live-Firebase build." >&2
  exit 1
fi

echo "==> flutter pub get"
flutter pub get

echo "==> flutter build apk --$MODE"
flutter build apk "--$MODE"

APK="build/app/outputs/flutter-apk/app-$MODE.apk"
echo ""
echo "APK built: $APP_DIR/$APK"
ls -lh "$APK" 2>/dev/null || true
echo ""
echo "Install on a connected device (USB debugging on):"
echo "  adb install -r \"$APK\""
