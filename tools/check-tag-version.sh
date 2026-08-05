#!/bin/bash
# Verify that a v* tag matches the version in version.json.
#
#   tools/check-tag-version.sh [ref]
#
# Defaults to $GITHUB_REF. Exits non-zero on mismatch so release builds cannot
# publish a tag that disagrees with the source tree.
set -e

__DIRNAME="$(dirname "$(readlink -f "$0")")"
. "$__DIRNAME/shared.sh"

REF="${1:-$GITHUB_REF}"

if [ -z "$REF" ]; then
	error "No ref given and GITHUB_REF is not set"
fi

if [ "${REF##refs/tags/v}" = "$REF" ]; then
	error "Not a version tag: ${REF}. Production builds must be started by a v* tag."
fi

TAG_VERSION="${REF##refs/tags/v}"

getVersion

if [ "$TAG_VERSION" != "$HUMAN_VERSION" ]; then
	error "Tag is 'v${TAG_VERSION}' but version.json says '${HUMAN_VERSION}'. Update version.json to match the tag."
fi

log "Version check passed: $HUMAN_VERSION"
