#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source scripts/env.sh
logInfo "Recording started..."
source scripts/metadata.sh
checkMetadataLock
source scripts/themes.sh

record() {
    declare -r _inputDir="${1}"
    declare -r _outputDir="${2}"
    declare -r _theme="${3}"
    declare -ir _counter="${4}"
    declare -ir _totalThemes="${5}"

    declare -r _tapeTplPath="${_inputDir}"/demo.tape
    declare -r _tapePath=/tmp/demo.tape
    local _recordFilePath
    printf -v _recordFilePath "%s/records/%03d %s.gif" "${_outputDir}" "${_counter}" "${_theme}"

    logInfo "(${counter}/${_totalThemes}) Record '${_recordFilePath}'"

    rm -fr "${_tapePath}"
    touch "${_tapePath}"

    export TAPE_OUTPUT=${_recordFilePath}
    export TAPE_INPUT_DIR=${_inputDir}
    export TAPE_THEME=${_theme}
    envsubst < "${_tapeTplPath}" >> "${_tapePath}"

    vhs validate "${_tapePath}"
    vhs "${_tapePath}" &> /dev/null
}

declare -a themes
getThemes themes
warnIfDuplicateThemes

if (( ${#themes[@]} > 500 ));then
    logError "There are ${#themes[@]} themes to be recorded which is greater than the arbitrary limit of 500"
    exit 1
fi

# https://www.shellcheck.net/wiki/SC2115
rm -fr "${ENV_OUTPUT_DIR:?}"/*
mkdir -p "${ENV_OUTPUT_DIR}"/records

declare -i counter=0
for theme in "${themes[@]}"; do
    ((counter+=1))
    record "${ENV_INPUT_DIR:?}" "${ENV_OUTPUT_DIR:?}" "${theme}" "${counter}" "${#themes[@]}"
done

logInfo "Recording done!"
