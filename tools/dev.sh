#!/bin/bash

__DIRNAME="$(dirname "$(readlink -f "$0")")"
. $__DIRNAME/shared.sh

updateVersionFiles

log "Running the application"
go run .