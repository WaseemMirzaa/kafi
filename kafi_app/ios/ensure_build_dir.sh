#!/bin/sh
# Keep Flutter's build/ outside iCloud Documents. A real build/ under
# ~/Documents gets FinderInfo xattrs and codesign fails with
# "resource fork, Finder information, or similar detritus not allowed".
# flutter clean removes a symlink and recreates a local build/ — call this
# before every ios build/run.
set -e
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TARGET="${KAFI_IOS_BUILD_DIR:-/tmp/kafi_app_build}"
mkdir -p "$TARGET"
# If build is a real directory (post flutter clean), move contents then replace.
if [ -d "$ROOT/build" ] && [ ! -L "$ROOT/build" ]; then
  # Prefer rsync so we don't lose a mid-build tree needlessly; then wipe local.
  rsync -a "$ROOT/build/" "$TARGET/" 2>/dev/null || true
  rm -rf "$ROOT/build"
fi
if [ -L "$ROOT/build" ]; then
  current="$(readlink "$ROOT/build")"
  if [ "$current" != "$TARGET" ]; then
    rm -f "$ROOT/build"
    ln -sfn "$TARGET" "$ROOT/build"
  fi
elif [ ! -e "$ROOT/build" ]; then
  ln -sfn "$TARGET" "$ROOT/build"
fi
export COPYFILE_DISABLE=1
xattr -cr "$TARGET" 2>/dev/null || true
# Engine frameworks copied with FinderInfo still break codesign.
find "$TARGET" \( -name 'Flutter.framework' -o -name 'App.framework' \) -print0 2>/dev/null |
  while IFS= read -r -d '' fw; do
    xattr -cr "$fw" 2>/dev/null || true
  done
echo "kafi: build -> $TARGET"
