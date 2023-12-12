#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source scripts/env.sh
logInfo "Recording started..."
source scripts/metadata.sh
checkMetadataLock

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

# Use "${var:?}" to ensure this never expands to /*
#   https://www.shellcheck.net/wiki/SC2115
rm -fr "${ENV_OUTPUT_DIR:?}"/*
mkdir -p "${ENV_OUTPUT_DIR}"/records

if [[ "${ENV_THEMES:?}" == "all" ]]; then
    # https://www.shellcheck.net/wiki/SC2207
    # https://www.shellcheck.net/wiki/SC2312
    # The command `vhs themes` outputs to stderr so the following line redirects stderr to stdout
    mapfile -t themes < <(vhs themes 2>&1 || true)
else
    # Transform string like "Zenburn,Adventure" to an array
    # https://stackoverflow.com/questions/10586153/how-to-split-a-string-into-an-array-in-bash
    # https://www.shellcheck.net/wiki/SC2207
    # shellcheck disable=SC2154,SC2312
    mapfile -t themes < <(printf "%s" "${ENV_THEMES}" | tr ',' '\n')
fi

readonly totalThemes="${#themes[@]}"

if (( "${ENV_THEMES_LIMIT:?}" == -1 )); then
    readonly limit="${totalThemes}"
elif (( "${ENV_THEMES_LIMIT}" > totalThemes )); then
    readonly limit="${totalThemes}"
else
    readonly limit="${ENV_THEMES_LIMIT}"
fi

readonly themes=("${themes[@]:0:${limit}}")
declare -i counter=0
for theme in "${themes[@]}"; do
    ((counter+=1))
    logInfo "(${counter}/${limit}) Record '${ENV_OUTPUT_DIR:?}/records/${theme}.gif'"
    record "${ENV_INPUT_DIR:?}" "${ENV_OUTPUT_DIR:?}" "${theme}"
done

logInfo "Recording done!"
