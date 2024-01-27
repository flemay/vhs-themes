#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source scripts/env.sh
logInfo "Paging started..."

getRecordsDir() {
    declare -n _retRecordsDir="${1}"
    _retRecordsDir="${ENV_OUTPUT_DIR:?}"/records
}

getFilteredRecordFiles() {
    declare -n _retRecordFiles="${1}"
    declare -r _recordsFilter="${2}"

    local _recordsDir
    getRecordsDir _recordsDir
    # shellcheck disable=SC2312
    mapfile -t _retRecordFiles < <(find "${_recordsDir}" -regextype egrep -iregex "${_recordsFilter}" | LC_ALL=C sort -f)
}

getRecordRelativePathAndName(){
    declare -n _retPath="${1}"
    declare -n _retName="${2}"
    declare -r _recordFile="${3}"

    # Transform "output/records/001 3024 Day.gif" to "../records/001%203024%20Day.gif"
    _retPath=${_recordFile/"${ENV_OUTPUT_DIR}"/".."}
    _retPath=${_retPath// /%20}

    # Transform "output/records/001 3024 Day.gif" to "3024 Day"
    _retName=${_recordFile#"${ENV_OUTPUT_DIR}"/records/}
    _retName="${_retName:4}"
    _retName="${_retName%.gif}"
}

# With 'declare -n' I can pass (and update without eval) return value, and also pass an array
getPagination(){
    declare -n _retPagination="${1}"
    declare -nr _recordFiles4="${2}"

    declare -ir _totalRecords="${#_recordFiles4[@]}"
    if (( "${ENV_PAGINATION:?}" == -1 )); then
        readonly _retPagination="${_totalRecords}"
    else
        readonly _retPagination="${ENV_PAGINATION}"
    fi
}

# https://stackoverflow.com/questions/2395284/round-a-divided-number-in-bash
# To do rounding up in truncating arithmetic, simply add (denom-1) to the numerator.
getTotalPages() {
    declare -n _retTotalPages="${1}"
    declare -nr _recordFiles2="${2}"
    declare -ir _totalRecords="${#_recordFiles2[@]}"
    declare -i _pagination
    getPagination _pagination _recordFiles2
    _retTotalPages=$(( (_totalRecords + (_pagination-1)) / _pagination ))
}

getFromRecordIndexAndLength(){
    declare -n _retFromIndex="${1}"
    declare -n _retLength="${2}"
    declare -nr _recordFiles3="${3}"
    declare -ir _pageNo="${4}"

    declare -i _pagination
    getPagination _pagination _recordFiles3
    declare -i _totalPages
    getTotalPages _totalPages _recordFiles3

    _retFromIndex=$(( (_pageNo*_pagination)-_pagination ))
    declare -ir _totalRecords="${#_recordFiles3[@]}"
    if (( _pageNo*_pagination < _totalRecords ));then
        _retLength="${_pagination}"
    else
        _retLength=$(( (_pageNo*_pagination)-(_pageNo*_pagination-_totalRecords) ))
    fi
}

constructPagePath() {
    declare -n _retPath="${1}"
    declare -r _pageName="${2}"
    declare -ri _pageNo="${3}"
    _retPath="${ENV_OUTPUT_DIR:?}/pages/page_${_pageName}_${_pageNo}.md"
}

printPageBody(){
    declare -nr _recordFiles1="${1}"
    declare -r _pageName1="${2}"
    declare -ir _pageNo="${3}"

    local _pagePath=""
    constructPagePath _pagePath "${_pageName1}" "${_pageNo}"

    logInfo "Create page '${_pagePath}'"
    printf "|||\n" > "${_pagePath}"
    printf "|:---:|:---:|\n" >> "${_pagePath}"

    declare -i _fromIndex
    declare -i _length
    getFromRecordIndexAndLength _fromIndex _length _recordFiles1 "${_pageNo}"

    declare -i _recordCounter="${_fromIndex}"
    local _recordCellOne=""
    for _recordFile in "${_recordFiles1[@]:${_fromIndex}:${_length}}";do
        ((_recordCounter+=1))
        local _path=""
        local _name=""
        getRecordRelativePathAndName _path _name "${_recordFile}"
        local _recordCellTwo="![${_name}](${_path})<br>${_recordCounter}. ${_name}"
        if [[ "${_recordCellOne}" == "" ]];then
            _recordCellOne="${_recordCellTwo}"
        else
            printf "| %s | %s |\n" "${_recordCellOne}" "${_recordCellTwo}" >> "${_pagePath}"
            _recordCellOne=""
        fi
    done
    if [[ "${_recordCellOne}" != "" ]];then
        printf "| %s | %s |\n" "${_recordCellOne}" "${_recordCellOne}" >> "${_pagePath}"
    fi
}

createPages() {
    declare -nr _recordFiles="${1}"
    declare -r _pageName2="${2}"

    declare -i _totalPages=0
    getTotalPages _totalPages _recordFiles

    for _pageNo in $(seq 1 "${_totalPages}"); do
        printPageBody _recordFiles "${_pageName2}" "${_pageNo}"
    done
}

createPageIndex(){
    declare -nr _recordFiles="${1}"
    declare -r _indexPath="${ENV_OUTPUT_DIR}/pages/page_index.md"
    logInfo "Create ${_indexPath}"
    printf "" > "${_indexPath}"
    local _path
    local _name
    for _recordFile in "${_recordFiles[@]}"; do
        getRecordRelativePathAndName _path _name "${_recordFile}"
        printf "1. [%s](%s)\n" "${_name}" "${_path}" >> "${_indexPath}"
    done
}

getPageName() {
    declare -n _retPageName="${1}"
    declare -r _pageFile="${2}"

    # Transform "output/pages/page_all_1.md" to "all_1"
    _retPageName="${_pageFile#"${ENV_OUTPUT_DIR}"/pages/page_}"
    _retPageName="${_retPageName%.md}"
}

getPageFilename() {
    declare -n _retPageFilename="${1}"
    declare -r _pageFile="${2}"

    # Transform "output/pages/page_all_1.md" to "page_all_1.md"
    _retPageFilename="${_pageFile#${ENV_OUTPUT_DIR}/pages/}"
}

getMarkdownPagesLinks() {
    declare -n _retPageLinks="${1}"
    declare -nr _pageFiles="${2}"

    _retPageLinks="[[source](../../main)] [[index](page_index.md)]"
    local _pageLink
    for _pageFile in "${_pageFiles[@]}"; do
        if [[ "${_pageFile}" =~ index\.md ]]; then
            continue
        fi
        local _pageName
        getPageName _pageName "${_pageFile}"
        local _pageFilename
        getPageFilename _pageFilename "${_pageFile}"
        printf -v _pageLink "[[%s](%s.md)]" "${_pageName}" "${_pageFilename}"
        _retPageLinks="${_retPageLinks} ${_pageLink}"
    done
}

printHeaderAndFooterToPages() {
    declare -ir _totalRecords="${1}"
    local _vhsVersion
    _vhsVersion=$(vhs --version)
    declare -a _pageFiles1
    # shellcheck disable=SC2312
    mapfile -t _pageFiles1 < <(find "${ENV_OUTPUT_DIR}"/pages/*.md | LC_ALL=C sort -f)
    local _pageLinks
    getMarkdownPagesLinks _pageLinks _pageFiles1
    for _pageFile in "${_pageFiles1[@]}"; do
        local _pageName1
        getPageName _pageName1 "${_pageFile}"
        local _content
        _content=$(cat <<EOF
Page: ${_pageName1}
Total of ${_totalRecords} records (themes) generated with \`${_vhsVersion}\`.
${_pageLinks}
> Tip: Resize the records by resizing the page
EOF
)
        local _tmpFile
        _tmpFile=$(mktemp)
        # Header
        printf "# VHS Themes - %s\n\n%s\n\n" "${_pageName1}" "${_content}" | cat - "${_pageFile}" > "${_tmpFile}"
        # Footer
        printf "\n%s" "${_content}" >> "${_tmpFile}"
        # Replace file
        cp -f "${_tmpFile}" "${_pageFile}"
    done
}

# This creates a README inside output dir
# This is done here so it can be tested before calling publish
createREADME() {
    declare -r _readmePath="${ENV_OUTPUT_DIR}/README.md"
    logInfo "Create ${_readmePath}"
    rm -fr "${_readmePath}"
    cp "${ENV_OUTPUT_DIR}"/pages/page_all_1.md "${_readmePath}"
    sed -i 's/..\/records\//records\//g' "${_readmePath}"
    sed -i 's/(..\/..\/main)/(..\/main)/' "${_readmePath}"
    sed -i 's/(page_/(pages\/page_/g' "${_readmePath}"
}

rm -fr "${ENV_OUTPUT_DIR:?}"/pages
mkdir -p "${ENV_OUTPUT_DIR}"/pages

declare -a recordsFiles
getFilteredRecordFiles recordsFiles ".*\.gif"
createPages recordsFiles "all"
createPageIndex recordsFiles
declare -i totalRecords="${#recordsFiles[@]}"

getFilteredRecordFiles recordsFiles ".*(dark|night).*\.gif"
createPages recordsFiles "dark_and_night"

getFilteredRecordFiles recordsFiles ".*(light|day).*\.gif"
createPages recordsFiles "light_and_day"

printHeaderAndFooterToPages "${totalRecords}"

createREADME

logInfo "Paging done!"
