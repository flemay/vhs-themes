#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# Inspired by https://gist.github.com/joncardasis/e6494afd538a400722545163eb2e1fa5

source scripts/env.sh
logInfo "Downloading content from branch '${ENV_PUBLISH_BRANCH:?}' to dir '${ENV_OUTPUT_DIR:?}' started..."
source scripts/metadata.sh
checkMetadataLock

rm -fr "${ENV_OUTPUT_DIR}"

readonly tmpRepoDir="/tmp/${ENV_GIT_REPO_NAME:?}"
rm -fr "${tmpRepoDir}"
gitAuth clone --branch "${ENV_PUBLISH_BRANCH}" "${ENV_GIT_REPO_URL:?}" "${tmpRepoDir}"
rm -fr "${tmpRepoDir}"/.git

mv "${tmpRepoDir}" "${ENV_OUTPUT_DIR}"

logInfo "Downloading content from branch '${ENV_PUBLISH_BRANCH}' to dir '${ENV_OUTPUT_DIR}' is done!"
