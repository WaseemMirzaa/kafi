#!/bin/sh
# Build/run iOS from a /tmp work copy so iCloud Documents cannot stamp FinderInfo
# xattrs (codesign "resource fork / detritus not allowed") or hang on Pods.
set -e
SRC="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
DST="${KAFI_IOS_WORK:-/tmp/kafi_work}"
DEVICE="${1:-00008110-00046D043EA0A01E}"
shift 2>/dev/null || true

FLUTTER="${FLUTTER_ROOT:-/Users/macuser/fvm/versions/3.47.7}/bin/flutter"
if [ ! -x "$FLUTTER" ]; then
  FLUTTER="$(command -v flutter)"
fi

echo "Syncing $SRC → $DST (excluding Pods/build)…"
mkdir -p "$DST"
rsync -a --delete \
  --exclude 'build/' \
  --exclude 'build.nosync/' \
  --exclude 'ios/Pods/' \
  --exclude 'ios/.symlinks/' \
  --exclude 'ios/Flutter/ephemeral/' \
  --exclude '.dart_tool/' \
  --exclude 'flutter_*.log' \
  "$SRC/" "$DST/"

cd "$DST"
export COPYFILE_DISABLE=1
export PATH="$DST/ios/bin:$PATH"

"$FLUTTER" pub get
(
  cd ios
  pod install
)

/bin/sh "$DST/ios/ensure_build_dir.sh" 2>/dev/null || true
mkdir -p "$DST/build"

echo "Running on $DEVICE with $($FLUTTER --version | head -1)…"
exec "$FLUTTER" run -d "$DEVICE" "$@"
