#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# This file contains all function related to themes!
#
# Few important points:
# - ignore case option is used because some systems are case-insensitive. So "Adventure" and "adventure" will be counted as duplicates otherwise "adventure" recording will overwrite "Adventure" whilst the name will remain "Adventure.gif"
# - Sort reverse is used because of the way "uniq --ignore-case" and "uniq --ignore-case --repeated" works.
#
# Here's an example of expected behaviour between uniq and duplicates (repeated):
#
# The following is what the function getAllUniqThemes would return. Notice it returns "Adventure"
# printf "%s\n" "Tokyo" "Adventure" "adventure" | sort --ignore-case | uniq --ignore-case
#Adventure
#Tokyo
#
# Let's find the duplicates (repeated) without reverse sort. It returns "Adventure". This is not what we want to print out.
# printf "%s\n" "Tokyo" "Adventure" "adventure" | sort --ignore-case | uniq --ignore-case --repeated
#Adventure
#
# Now, let's find duplicates (repeated) with reverse. It returns what we want to display.
# printf "%s\n" "Tokyo" "Adventure" "adventure" | sort --ignore-case --reverse | uniq --ignore-case --repeated
#adventure

# getAllThemes returns all the themes (including duplicates) based on ENV_THEMES sorted
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

# getAllDuplicateThemes gets all duplicate themes (repeated) which are excluded from the function getAllUniqThemes
getAllDuplicateThemes(){
    declare -n _retDuplicates="${1}"
    getAllThemes _retDuplicates
    mapfile -t _retDuplicates < <(printf "%s\n" "${_retDuplicates[@]}" \
        | sort --ignore-case --reverse \
        | uniq --ignore-case --repeated \
        || true)
}

warnIfDuplicateThemes(){
    declare -a _duplicates
    getAllDuplicateThemes _duplicates
    if (( ${#_duplicates[@]} > 0 ));then
        local _commaSeparatedDuplicates
        arrayToCommaSeparatedString _commaSeparatedDuplicates _duplicates
        logWarn "${#_duplicates[@]} duplicate themes discarded: ${_commaSeparatedDuplicates}"
    fi
}

# getAllUniqThemes returns all themes excluding duplicates (repeated)
getAllUniqThemes(){
    declare -n _retUniqThemes="${1}"
    getAllThemes _retUniqThemes
    mapfile -t _retUniqThemes < <( printf "%s\n" "${_retUniqThemes[@]}" \
        | uniq --ignore-case \
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
    getAllUniqThemes _retThemes
    declare -i _limit
    getLimit _limit _retThemes
    _retThemes=("${_retThemes[@]:0:${_limit}}")
}
