#!/bin/bash
# Regenerate the packaged icons from icon.png (repo root).
#
#   tools/gen-icons.sh
#
# Produces:
#   tools/extras/iconfile.icns  (macOS app bundle, via sips + iconutil)
#   tools/extras/icon.ico       (Windows exe, PNG-payload .ico via tools/gen-ico)
#
# Commit the regenerated files. The build pipeline (build.sh / make-mac-app.sh)
# consumes these two files directly and is not changed by this script.
set -euo pipefail

__DIRNAME="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$__DIRNAME/.." && pwd)"
SRC="$ROOT/icon.png"
EXTRAS="$__DIRNAME/extras"

[ -f "$SRC" ] || { echo "error: missing $SRC" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- macOS .icns ---
ICONSET="$TMP/icon.iconset"
mkdir -p "$ICONSET"
icns() { sips -z "$2" "$2" "$SRC" --out "$ICONSET/$1" >/dev/null; }
icns icon_16x16.png      16
icns icon_16x16@2x.png   32
icns icon_32x32.png      32
icns icon_32x32@2x.png   64
icns icon_128x128.png    128
icns icon_128x128@2x.png 256
icns icon_256x256.png    256
icns icon_256x256@2x.png 512
icns icon_512x512.png    512
icns icon_512x512@2x.png 1024
iconutil -c icns "$ICONSET" -o "$EXTRAS/iconfile.icns"
echo "wrote $EXTRAS/iconfile.icns"

# --- Windows .ico ---
ICODIR="$TMP/ico"
mkdir -p "$ICODIR"
PNGS=()
for s in 16 32 48 64 128 256; do
	sips -z "$s" "$s" "$SRC" --out "$ICODIR/$s.png" >/dev/null
	PNGS+=("$ICODIR/$s.png")
done
go run "$__DIRNAME/gen-ico/main.go" "$EXTRAS/icon.ico" "${PNGS[@]}"
