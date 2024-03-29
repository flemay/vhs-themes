#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Use `source scripts/env.sh` so that environment variables can be set/unset in the same process as the caller.

[[ -f "/.dockerenv" ]] || { printf "Error: must be executed inside Docker container\n" 1>&2; exit 1; }

# Time format: https://pkg.go.dev/time
logInfo(){
    declare -r _message="${1}"
    gum log --time="DateTime" --level info "${_message}"
}

logWarn(){
    declare -r _message="${1}"
    gum log --time="DateTime" --level warn "${_message}"
}

logError(){
    declare -r _message="${1}"
    gum log --time="DateTime" --level error "${_message}"
}

# https://stackoverflow.com/questions/72577367/git-push-provide-credentials-without-any-prompts
gitAuth() {
    # shellcheck disable=SC2016
    git -c credential.helper= \
        -c credential.helper='!f() { echo "username=${ENV_GIT_USERNAME:?}"; echo "password=${ENV_GIT_TOKEN:?}"; };f' \
    "$@"
}

# Gets the name of the repo from ENV_GIT_REPO_URL
# Ex: https://github.com/flemay/vhs-themes.git -> vhs-themes
getGitRepoName() {
    declare -n _retRepoName="${1}"
    declare -r _gitRepoURL="${ENV_GIT_REPO_URL:?}"
    _retRepoName="${_gitRepoURL##*/}"
    _retRepoName="${_retRepoName%.git}"
}

checkEnvVars(){
    if ! envTemplate=$(grep -v "#" env.template | awk -F '=' '{print $1}');then
        logError "checkEnvVars: failed"
        exit 1
    fi
    mapfile -t envVars < <(printf "%s" "${envTemplate}")
    local hasUnsetEnvVars="false"
    for ev in "${envVars[@]}";do
        # to check the env value based on ev, use bash variable indirection
        if [[ -z "${!ev:-""}" ]];then
            logError "${ev} is missing"
            hasUnsetEnvVars="true"
        fi
    done
    if [[ "${hasUnsetEnvVars}" == "true" ]];then
        exit 1
    fi
}

arrayToCommaSeparatedString(){
    declare -n _retCommaSeparatedString="${1}"
    declare -n _array="${2}"
    printf -v _retCommaSeparatedString '%s,' "${_array[@]}"
    _retCommaSeparatedString="${_retCommaSeparatedString::-1}"
}

# https://www.baeldung.com/linux/directory-md5-checksum
# > Letters, numbers, dates, and how they should be sorted can change from locale to locale. This can change our results for directories residing on two systems with different locale settings.
export LC_ALL=C
checkEnvVars
