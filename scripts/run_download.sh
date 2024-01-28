#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source scripts/env.sh
logInfo "Downloading content from branch '${ENV_GIT_PUBLISH_BRANCH:?}' to dir '${ENV_OUTPUT_DIR:?}' started..."
source scripts/metadata.sh
checkMetadataLock

rm -fr "${ENV_OUTPUT_DIR}"

declare gitRepoName=""
getGitRepoName gitRepoName
readonly tmpRepoDir="${ENV_TMP_DIR:?}/${gitRepoName}"
rm -fr "${tmpRepoDir}"
# the Git clone option `--single-branch` prevents from downloading other branches. For instance, `make testE2E` without this option would also download the branch `themes` which is about 40mb in size. Now with this option, only branch `themes_test_e2e` (5mb) is downloaded.
gitAuth clone --branch "${ENV_GIT_PUBLISH_BRANCH}" --single-branch "${ENV_GIT_REPO_URL:?}" "${tmpRepoDir}"
rm -fr "${tmpRepoDir}"/.git

mv "${tmpRepoDir}" "${ENV_OUTPUT_DIR}"

logInfo "Downloading content from branch '${ENV_GIT_PUBLISH_BRANCH}' to dir '${ENV_OUTPUT_DIR}' is done!"
