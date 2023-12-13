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
    # https://www.shellcheck.net/wiki/SC2015
    if [[ "${ENV_PUBLISH_BRANCH:?}" == "main" ]]; then
        logError "ENV_PUBLISH_BRANCH cannot be 'main'"
        exit 1
    fi
}

checkEnvVars
