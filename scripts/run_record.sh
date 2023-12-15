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

# https://www.shellcheck.net/wiki/SC2115
rm -fr "${ENV_OUTPUT_DIR:?}"/*
mkdir -p "${ENV_OUTPUT_DIR}"/records

declare -a themes
getThemes themes
exit 0
declare -i counter=0
for theme in "${themes[@]}"; do
    ((counter+=1))
    logInfo "(${counter}/${#themes[@]}) Record '${ENV_OUTPUT_DIR:?}/records/${theme}.gif'"
    record "${ENV_INPUT_DIR:?}" "${ENV_OUTPUT_DIR:?}" "${theme}"
done

logInfo "Recording done!"
