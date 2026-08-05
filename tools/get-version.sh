#!/bin/bash
# Shared bash functions for the tool scripts
__DIRNAME="$(dirname "$(readlink -f "$0")")"
. $__DIRNAME/shared.sh
getVersion

echo $HUMAN_VERSION