#!/bin/bash
# Build the macOS .app bundle and dmg, signing and notarizing when credentials
# are available.
#
#   tools/make-mac-app.sh [arch]      arch: arm64 | amd64 (default: go env GOARCH)
#
# Signing follows the same convention as the other Bitfocus projects: it happens
# only when CSC_LINK is set (the certificate must already be in the keychain, see
# tools/CI-keychain.sh). Notarization additionally needs APPLE_ID,
# APPLE_TEAM_ID and APPLE_APP_SPECIFIC_PASSWORD. Without them the build still
# succeeds and simply produces an unsigned dmg, so forks and pull requests work.
__DIRNAME="$(dirname "$(readlink -f "$0")")"
. "$__DIRNAME/shared.sh"

getVersion

if [ -z "$PRODUCTION_FOLDER" ]; then
	PRODUCTION_FOLDER="$__DIRNAME/../build"
fi

ARCH="${1:-$(go env GOARCH)}"

APP_PATH="$(mktemp -d)/Bitfocus Listener.app"
test -d "$APP_PATH" && rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

cp "$__DIRNAME/extras/iconfile.icns" "$APP_PATH/Contents/Resources/Icon.icns" || error "Failed to copy iconset to app"

# The build keychain holds exactly one Developer ID certificate, so matching on
# the identity prefix avoids hardcoding a team. Set SIGNING_IDENTITY to pin it.
: "${SIGNING_IDENTITY:="Developer ID Application"}"

APPS=("bitfocus-listener")

log Copying files
MACARCH="$ARCH"
if [ "$ARCH" = "amd64" ]; then
	MACARCH="x86_64"
fi

cat $__DIRNAME/extras/info.plist | sed \
	-e "s/%VERSION%/$VERSION_MAJOR.$VERSION_MINOR.$VERSION_PATCH.$VERSION_BUILD/g" \
	-e "s/%SHORTVERSION%/$VERSION_MAJOR.$VERSION_MINOR/g" \
	-e "s/%ARCH%/$MACARCH/g" \
	-e "s/%YEAR%/$(date +%Y)/g" \
	>"$APP_PATH/Contents/Info.plist"

# Sign only when a certificate was supplied. Everything else builds unsigned.
if [ -z "$CSC_LINK" ]; then
	NOSIGN=1
fi

if [ -z "$NOSIGN" ]; then
	for app in "${APPS[@]}"; do
		log "Signing $app"
		mv "$PRODUCTION_FOLDER/$app" "$APP_PATH/Contents/MacOS/"
		codesign --force --verify -o runtime --entitlements "$__DIRNAME/extras/osx-entitlements.plist" --timestamp --sign "$SIGNING_IDENTITY" "$APP_PATH/Contents/MacOS/$app" || error "Failed to sign $app in app bundle"
	done
else
	for app in "${APPS[@]}"; do
		log "Skipping: Signing $app (no CSC_LINK)"
		mv "$PRODUCTION_FOLDER/$app" "$APP_PATH/Contents/MacOS/"
	done
fi

# Might not be any more files, ignore errors
mv "$PRODUCTION_FOLDER"/* "$APP_PATH/Contents/Resources/" >/dev/null 2>&1

log Packaging dmg

rm -rf "$PRODUCTION_FOLDER"
mkdir -p "$PRODUCTION_FOLDER"
mv "$APP_PATH" "$PRODUCTION_FOLDER/"
cp "$__DIRNAME/../LICENSE" "$PRODUCTION_FOLDER/LICENSE.txt"
cp "$__DIRNAME/../THIRD-PARTY-NOTICES.md" "$PRODUCTION_FOLDER/"

if [ -z "$NOSIGN" ]; then
	log Signing app bundle
	codesign --force --verify -o runtime --timestamp --sign "$SIGNING_IDENTITY" "$PRODUCTION_FOLDER/$(basename "$APP_PATH")" || error "Failed to sign app"
fi

DMGPATH="$(mktemp -d)/bitfocus-listener.dmg"
hdiutil create -volname "Bitfocus Listener" -srcfolder "$PRODUCTION_FOLDER" -ov -format UDZO "$DMGPATH" || error "Failed to create dmg"

if [ -z "$NOSIGN" ]; then
	log Signing dmg
	codesign --verify -o runtime --timestamp --sign "$SIGNING_IDENTITY" "$DMGPATH" || error "Failed to sign bundle"
fi

if [ -z "$NOSIGN" ] && [ -n "$APPLE_ID" ] && [ -n "$APPLE_TEAM_ID" ] && [ -n "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
	NOTARYLOG="$(mktemp)"
	log Notarizing app
	xcrun notarytool submit "$DMGPATH" --team-id "$APPLE_TEAM_ID" --apple-id "$APPLE_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD" --wait --output-format json >"$NOTARYLOG" || error "Failed to notarize app: $(cat "$NOTARYLOG")"
	status=$(jq -r .status "$NOTARYLOG")
	id="$(jq -r .id "$NOTARYLOG")"
	message="$(jq -r .message "$NOTARYLOG")"
	log "Notarization status: $status (id: $id): $message"
	if [ "$status" = "Invalid" ]; then
		xcrun notarytool log "$id" --team-id "$APPLE_TEAM_ID" --apple-id "$APPLE_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD" || error "Failed to get notarization log"
		error "Notarization failed"
	fi

	log Stapling notarization
	xcrun stapler staple -v "$DMGPATH" >"$NOTARYLOG" || error "Failed to staple notarization: $(cat "$NOTARYLOG")"
else
	if [ -z "$NOSIGN" ]; then
		log "Notarization skipped (no Apple credentials in the environment)"
	else
		log "Notarization skipped (unsigned build)"
	fi
fi

rm -rf "$PRODUCTION_FOLDER"
mkdir -p "$PRODUCTION_FOLDER"
mv "$DMGPATH" "$PRODUCTION_FOLDER/"
