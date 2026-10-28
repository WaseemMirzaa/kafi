#!/bin/sh
# Strip iCloud FinderInfo / resource-fork xattrs that break codesign when the
# project lives under ~/Documents (Desktop & Documents iCloud). Runs for both
# device and simulator; re-signs the app + embedded frameworks ad-hoc on
# simulator, and only strips (lets Xcode finish signing) on device.

APP="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
if [ ! -d "${APP}" ]; then
  APP="${TARGET_BUILD_DIR}/${FULL_PRODUCT_NAME}"
fi
if [ ! -d "${APP}" ]; then
  echo "warning: app bundle not found at ${TARGET_BUILD_DIR}; stripping build dir only"
  if [ -n "${TARGET_BUILD_DIR}" ] && [ -d "${TARGET_BUILD_DIR}" ]; then
    xattr -cr "${TARGET_BUILD_DIR}" 2>/dev/null || true
  fi
  exit 0
fi

APP_DIR="$(cd "$(dirname "${APP}")" && pwd -P)"
APP="${APP_DIR}/$(basename "${APP}")"

xattr -cr "${APP}" 2>/dev/null || true

find "${APP}" \( -name "*.framework" -o -name "*.dylib" -o -name "*.appex" \) -print0 2>/dev/null |
  while IFS= read -r -d "" item; do
    xattr -cr "${item}" 2>/dev/null || true
  done

# Device/archive: Xcode signs after this phase — strip only.
if [ "${PLATFORM_NAME}" != "iphonesimulator" ]; then
  exit 0
fi

# Simulator: re-ad-hoc-sign after strip (signing is often disabled for pods).
find "${APP}" \( -name "*.framework" -o -name "*.dylib" -o -name "*.appex" \) -print0 2>/dev/null |
  while IFS= read -r -d "" item; do
    /usr/bin/codesign --force --sign - --timestamp=none "${item}" || true
  done

xattr -cr "${APP}" 2>/dev/null || true

XCENT="${TARGET_TEMP_DIR}/${FULL_PRODUCT_NAME}.xcent"
if [ ! -f "${XCENT}" ]; then
  XCENT="${TARGET_TEMP_DIR}/Runner.app.xcent"
fi

if [ -f "${XCENT}" ]; then
  /usr/bin/codesign --force --sign - --entitlements "${XCENT}" --timestamp=none --generate-entitlement-der "${APP}"
else
  /usr/bin/codesign --force --sign - --timestamp=none --generate-entitlement-der "${APP}"
fi
