#!/bin/bash
# Regenerate version.go from version.json + git metadata, without building or
# running anything. Used by CI and by anyone who wants to `go build` directly.
#
#   tools/dev-version.sh

__DIRNAME="$(dirname "$(readlink -f "$0")")"
. "$__DIRNAME/shared.sh"

updateVersionFiles

log "Wrote version.go ($VERSION)"
