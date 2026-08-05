#!/bin/bash
# Import the macOS code-signing certificate into a temporary build keychain.
#
# Expects the same environment electron-builder uses elsewhere at Bitfocus:
#   CSC_LINK          base64-encoded .p12 certificate
#   CSC_KEY_PASSWORD  password for that certificate
#
# When those are unset, signing is skipped entirely (see tools/make-mac-app.sh),
# so forks and pull requests still produce working unsigned builds.
set -e

if [ -z "$CI" ]; then
	echo "This should never be run locally on your Mac; it is only intended for CI." >&2
	exit 1
fi

__DIRNAME="$(dirname "$(readlink -f "$0")")"
. $__DIRNAME/shared.sh

if [[ -z "$CSC_LINK" ]]; then
	echo "Error: CSC_LINK is not set, cannot set up signing keychain" >&2
	exit 1
fi

if [[ -z "$CSC_KEY_PASSWORD" ]]; then
	echo "Error: CSC_KEY_PASSWORD is not set, cannot set up signing keychain" >&2
	exit 1
fi

CERTFILE="$(mktemp -t listener-cert)"
KEYCHAIN=build.keychain
KEYCHAINFILE=$HOME/Library/Keychains/$KEYCHAIN-db

trap 'rm -f "$CERTFILE"' EXIT

if [[ -e "$KEYCHAINFILE" ]]; then
	log "Removing existing keychainfile $KEYCHAIN"
	security delete-keychain "$KEYCHAIN"
fi

log "Creating keychain $KEYCHAIN"
security create-keychain -p "$CSC_KEY_PASSWORD" "$KEYCHAIN"
security list-keychains -d user -s "$KEYCHAIN" login.keychain
security set-keychain-settings -lut 21600 "$KEYCHAIN" # No interactive unlock for the next 6 hours
security unlock-keychain -p "$CSC_KEY_PASSWORD" "$KEYCHAIN"

log "Importing signing certificate to keychain"
echo "$CSC_LINK" | base64 -D >"$CERTFILE"
security import "$CERTFILE" -k "$KEYCHAIN" -P "$CSC_KEY_PASSWORD" -T /usr/bin/codesign -T /usr/bin/productsign

log "Make sure signing tools can be used without user interaction"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$CSC_KEY_PASSWORD" "$KEYCHAIN"
