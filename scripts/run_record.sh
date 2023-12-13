#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source scripts/env.sh
logInfo "Recording started..."
source scripts/metadata.sh
checkMetadataLock

checkVHSThemeDuplicates(){
    local _duplicatedThemes
    _duplicatedThemes=$(vhs themes 2>&1 | sort | uniq -d)
    if [[ -z "${_duplicatedThemes}" ]];then
        logInfo "No duplicated themes found"
        return 0
    fi
    declare -i _duplicatedThemeCount
    _duplicatedThemeCount=$(vhs themes 2>&1 | sort | uniq -d | wc -l)
    if (( _duplicatedThemeCount > 0 ));then
        logWarn "The followning ${_duplicatedThemeCount} themes are duplicated:"
        logWarn "${_duplicatedThemes}"
    fi
}

record() {
    declare -r _inputDir="${1}"
    declare -r _outputDir="${2}"
    declare -r _theme="${3}"
    declare -r _tapeTplPath="${_inputDir}"/demo.tape
    declare -r _tapePath=/tmp/demo.tape

    rm -fr "${_tapePath}"
    touch "${_tapePath}"
    if [[ "${ENV_ENABLE_OUTPUT_ASCII:?}" == "true" ]]; then
        printf "Output \"%s\"\n" "${_outputDir}/records/${_theme}.ascii" >> "${_tapePath}"
    fi

    export TAPE_OUTPUT=${_outputDir}/records/${_theme}.gif
    export TAPE_INPUT_DIR=${_inputDir}
    export TAPE_THEME=${_theme}
    envsubst < "${_tapeTplPath}" >> "${_tapePath}"

    vhs validate "${_tapePath}"
    vhs "${_tapePath}" &> /dev/null
}

getLimit(){
    declare -n _retLimit="${1}"
    declare -nr _themes="${2}"
    declare -r _totalThemes="${#themes[@]}"

    if (( "${ENV_THEMES_LIMIT:?}" == -1 )); then
        _retLimit="${_totalThemes}"
    elif (( "${ENV_THEMES_LIMIT}" > _totalThemes )); then
        _retLimit="${_totalThemes}"
    else
        _retLimit="${ENV_THEMES_LIMIT}"
    fi
}

getThemes(){
    declare -n _retThemes="${1}"

    if [[ "${ENV_THEMES:?}" == "all" ]]; then
        # https://www.shellcheck.net/wiki/SC2207
        # https://www.shellcheck.net/wiki/SC2312
        # The command `vhs themes` outputs to stderr so the following line redirects stderr to stdout
        mapfile -t _retThemes < <(vhs themes 2>&1 || true)
    else
        # Transform string like "Zenburn,Adventure" to an array
        # https://stackoverflow.com/questions/10586153/how-to-split-a-string-into-an-array-in-bash
        # https://www.shellcheck.net/wiki/SC2207
        # shellcheck disable=SC2154,SC2312
        mapfile -t _retThemes < <(printf "%s" "${ENV_THEMES}" | tr ',' '\n')
    fi

    if [[ "${#_retThemes[@]}" == 0 ]];then
        logError "Number of themes is 0. Either the command 'vhs themes' didn't return any theme or ENV_THEMES is empty."
        exit 1
    fi

    declare -i _limit
    getLimit _limit _retThemes
    _retThemes=("${themes[@]:0:${_limit}}")
}

checkVHSThemeDuplicates

# https://www.shellcheck.net/wiki/SC2115
rm -fr "${ENV_OUTPUT_DIR:?}"/*
mkdir -p "${ENV_OUTPUT_DIR}"/records

declare -a themes
getThemes themes
declare -i counter=0
for theme in "${themes[@]}"; do
    ((counter+=1))
    logInfo "(${counter}/${#themes[@]}) Record '${ENV_OUTPUT_DIR:?}/records/${theme}.gif'"
    record "${ENV_INPUT_DIR:?}" "${ENV_OUTPUT_DIR:?}" "${theme}"
done

logInfo "Recording done!"
