#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source scripts/env.sh
logInfo "Publishing to branch '${ENV_GIT_PUBLISH_BRANCH:?}' started..."
source scripts/metadata.sh
checkMetadataLock
generateMetadata

./scripts/run_git_publish.sh

logInfo "Publishing to branch '${ENV_GIT_PUBLISH_BRANCH}' is done!"
