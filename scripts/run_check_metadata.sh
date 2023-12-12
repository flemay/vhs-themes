#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source scripts/env.sh
logInfo "Checking metadata started..."
source scripts/metadata.sh
generateMetadata
checkMetadata
logInfo "Checking metadata is done!"
