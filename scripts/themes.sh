#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# This file contains all function related to themes!
getAllThemes(){
    declare -n _retAllThemes="${1}"

    if [[ "${ENV_THEMES:?}" == "all" ]]; then
        # https://www.shellcheck.net/wiki/SC2207
        # https://www.shellcheck.net/wiki/SC2312
        # The command `vhs themes` outputs to stderr so the following line redirects stderr to stdout
        mapfile -t _retAllThemes < <(vhs themes 2>&1 \
            | sort --ignore-case \
            || true)
    else
        # Transform string like "Zenburn,Adventure" to an array
        # https://stackoverflow.com/questions/10586153/how-to-split-a-string-into-an-array-in-bash
        # https://www.shellcheck.net/wiki/SC2207
        # shellcheck disable=SC2154,SC2312
        mapfile -t _retAllThemes < <(printf "%s" "${ENV_THEMES}" \
            | tr ',' '\n' \
            | sort --ignore-case)
    fi

    if [[ "${#_retAllThemes[@]}" == 0 ]];then
        logError "Number of themes is 0. Either the command 'vhs themes' didn't return any theme or ENV_THEMES is empty."
        exit 1
    fi
}

# 1) With ignore case
# printf "tokyonight\nTokyoNight\ntokyonight" | sort --ignore-case | uniq -D --ignore-case
# TokyoNight
# tokyonight
# tokyonight
#
# 2) Without ignore case
# printf "tokyonight\nTokyoNight\ntokyonight" | sort --ignore-case | uniq -D
# tokyonight
# tokyonight
getAllDuplicateThemes(){
    declare -n _retDuplicates="${1}"
    declare -r _withIgnoreCase="${2}"

    local _uniqOptions="-D"
    if [[ "${_withIgnoreCase}" == "true" ]];then
        _uniqOptions="-D --ignore-case"
    fi

    getAllThemes _retDuplicates
    # shellcheck disable=SC2248,SC2086
    mapfile -t _retDuplicates < <(printf "%s\n" "${_retDuplicates[@]}" \
        | sort --ignore-case \
        | uniq ${_uniqOptions} \
        || true)
}

warnIfDuplicateThemes(){
    declare -a _duplicates
    getAllDuplicateThemes _duplicates "false"
    if (( ${#_duplicates[@]} > 0 ));then
        local _commaSeparatedDuplicates
        arrayToCommaSeparatedString _commaSeparatedDuplicates _duplicates
        logWarn "${#_duplicates[@]} duplicate themes: ${_commaSeparatedDuplicates}"
    fi
}

# getAllUniqThemes returns all themes excluding duplicates (repeated)
#
# 1) With ignore case
# printf "tokyonight\nTokyoNight\ntokyonight" | sort --ignore-case | uniq --ignore-case
# TokyoNight
#
# 2) Without ignore case
# printf "tokyonight\nTokyoNight\ntokyonight" | sort --ignore-case | uniq
# TokyoNight
# tokyonight
getAllUniqThemes(){
    declare -n _retUniqThemes="${1}"
    declare -r _withIgnoreCase="${2}"

    local _uniqOptions=""
    if [[ "${_withIgnoreCase}" == "true" ]];then
        _uniqOptions="--ignore-case"
    fi
    getAllThemes _retUniqThemes
    # shellcheck disable=SC2248
    mapfile -t _retUniqThemes < <( printf "%s\n" "${_retUniqThemes[@]}" \
        | uniq ${_uniqOptions} \
        || true)
}

getLimit(){
    declare -n _retLimit="${1}"
    declare -nr _themes="${2}"
    declare -r _totalThemes="${#_themes[@]}"

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
    getAllUniqThemes _retThemes "false"
    declare -i _limit
    getLimit _limit _retThemes
    _retThemes=("${_retThemes[@]:0:${_limit}}")
}
