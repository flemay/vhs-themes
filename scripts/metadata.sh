#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

readonly metadataFilePath="${ENV_OUTPUT_DIR:?}/metadata.txt"
readonly metadataLockFilePath="${ENV_OUTPUT_DIR:?}/metadata.lock"

# downloadMetadataFile uses GitHub API to download the remote metadata.txt file.
# It returns an error and outputs the content of the downloaded file if it contains `"message":`.
# An error can happen if the GitHub token does not have access to the file or if the file does not exists.
# Refs
# - https://docs.github.com/en/rest/repos/contents?apiVersion=2022-11-28#get-contents
downloadMetadataFile() {
    logInfo "Metadata check: download remote metadata file"
    declare -r _downloadFilePath="${1}"
    declare -r _endpoint="https://api.github.com/repos/${ENV_GIT_USERNAME:?}/${ENV_GIT_REPO_NAME:?}/contents/metadata.txt?ref=${ENV_PUBLISH_BRANCH:?}"
    curl -s -H "Authorization: Bearer ${ENV_GIT_TOKEN:?}" \
        -H "Accept: application/vnd.github.v3.raw" \
        -o "${_downloadFilePath}" \
        -L "${_endpoint}"
    if grep "\"message\":" "${_downloadFilePath}"; then
        logError "Download remote checksum file failed. Endpoint: ${_endpoint}"
        cat "${_downloadFilePath}" 1>&2
        exit 1
    fi
}

# References
# - https://www.baeldung.com/linux/directory-md5-checksum
generateMetadata(){
    logInfo "Metadata check: generate metadata '${metadataFilePath}'"
    local vhsVersion
    vhsVersion=$(vhs --version)
    local inputChecksum
    if ! inputChecksum=$(find "${ENV_INPUT_DIR:?}" -type f -exec sha256sum {} + | LC_ALL=C sort | sha256sum | awk '{print $1}');then
        logError "Metadata check: something went wrong when doing checksum of ${ENV_INPUT_DIR}"
        exit 1
    fi

    mkdir -p "${ENV_OUTPUT_DIR:?}"
    rm -fr "${metadataFilePath}"
    {
        printf "VHS version: %s\n" "${vhsVersion}"
        printf "Themes: %s\n" "${ENV_THEMES:?}"
        printf "Themes limit: %d\n" "${ENV_THEMES_LIMIT:?}"
        printf "Pagination: %d\n" "${ENV_PAGINATION:?}"
        printf "Dir ${ENV_INPUT_DIR}: %s\n" "${inputChecksum}"
    } >> "${metadataFilePath}"
}

checkMetadataLock() {
    logInfo "Metadata check: check for lock file '${metadataLockFilePath}'"
    if [[ -f "${metadataLockFilePath}" ]];then
        logInfo "Metadata check: stop the script because '${metadataLockFilePath}' exists"
        exit 0
    fi
}

removeMetadataLock(){
    logInfo "Metadata check: remove lock file '${metadataLockFilePath}'"
    rm -fr "${metadataLockFilePath}"
}

checkMetadata(){
    declare -r remoteMetadataFilePath="/tmp/metadata.txt"
    downloadMetadataFile "${remoteMetadataFilePath}"
    if ! remoteMetadataChecksum=$(sha256sum "${remoteMetadataFilePath}" | awk '{print $1}');then
        logError "Metadata check: something went wrong when doing checksum of '${remoteMetadataFilePath}'"
        exit 1
    fi
    if ! metadataChecksum=$(sha256sum "${metadataFilePath}" | awk '{print $1}');then
        logError "Metadata check: something went wrong when doing checksum of '${metadataFilePath}'"
        exit 1
    fi

    removeMetadataLock
    if [[ "${remoteMetadataChecksum}" == "${metadataChecksum}" ]];then
        logInfo "Metadata check: file '${metadataLockFilePath}' has been created because remote and local metadata are the same"
        touch "${metadataLockFilePath}"
        exit 0
    fi
    logInfo "Metadata check: remote and local metadata differ"
}
