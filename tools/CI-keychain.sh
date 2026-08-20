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

# The .p12 extension matters: `security import` guesses the format from it, and
# gives an unhelpful "Unknown format in import" for an extensionless file.
CERTDIR="$(mktemp -d)"
CERTFILE="$CERTDIR/certificate.p12"
KEYCHAIN=build.keychain
KEYCHAINFILE=$HOME/Library/Keychains/$KEYCHAIN-db

trap 'rm -rf "$CERTDIR"' EXIT

if [[ -e "$KEYCHAINFILE" ]]; then
	log "Removing existing keychainfile $KEYCHAIN"
	security delete-keychain "$KEYCHAIN"
fi

log "Creating keychain $KEYCHAIN"
security create-keychain -p "$CSC_KEY_PASSWORD" "$KEYCHAIN"
security list-keychains -d user -s "$KEYCHAIN" login.keychain
security set-keychain-settings -lut 21600 "$KEYCHAIN" # No interactive unlock for the next 6 hours
security unlock-keychain -p "$CSC_KEY_PASSWORD" "$KEYCHAIN"

log "Decoding signing certificate"
# Whitespace is stripped first, so a secret stored with line wrapping still decodes.
echo "$CSC_LINK" | tr -d '[:space:]' | base64 -D >"$CERTFILE" || error "CSC_LINK is not valid base64; it must be a base64-encoded .p12 certificate"

# A PKCS#12 file is DER, so it always starts with a SEQUENCE tag (0x30). Checking
# this gives a usable error instead of 'Unknown format in import' from security.
if [ "$(head -c 1 "$CERTFILE" | od -An -tx1 | tr -d '[:space:]')" != "30" ]; then
	error "CSC_LINK did not decode to a .p12 certificate. electron-builder also accepts a path or url there; this script needs the base64 of the certificate itself."
fi

log "Importing signing certificate to keychain"
security import "$CERTFILE" -k "$KEYCHAIN" -f pkcs12 -P "$CSC_KEY_PASSWORD" -T /usr/bin/codesign -T /usr/bin/productsign || error "Failed to import signing certificate to keychain"

log "Make sure signing tools can be used without user interaction"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$CSC_KEY_PASSWORD" "$KEYCHAIN"
