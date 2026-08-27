#!/bin/sh
# Simulator only. Xcode signing is off (CODE_SIGNING_ALLOWED=NO for iphonesimulator).
# Resolve through any Documents symlink so we sign the real /tmp bundle, strip
# iCloud FinderInfo, then ad-hoc sign with Keychain entitlements.
if [ "${PLATFORM_NAME}" != "iphonesimulator" ]; then
  exit 0
fi

APP="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
if [ ! -d "${APP}" ]; then
  APP="${TARGET_BUILD_DIR}/${FULL_PRODUCT_NAME}"
fi
if [ ! -d "${APP}" ]; then
  echo "error: app bundle not found at ${TARGET_BUILD_DIR}" >&2
  exit 1
fi

APP_DIR="$(cd "$(dirname "${APP}")" && pwd -P)"
APP="${APP_DIR}/$(basename "${APP}")"

xattr -cr "${APP}" 2>/dev/null || true

find "${APP}" \( -name "*.framework" -o -name "*.dylib" -o -name "*.appex" \) -print0 2>/dev/null |
  while IFS= read -r -d "" item; do
    xattr -cr "${item}" 2>/dev/null || true
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
