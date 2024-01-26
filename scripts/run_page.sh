#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source scripts/env.sh
logInfo "Paging started..."

getRecordsDir() {
    declare -n _retRecordsDir="${1}"
    _retRecordsDir="${ENV_OUTPUT_DIR}"/records
}

getFilteredRecordFiles() {
    declare -n _retRecordFiles="${1}"
    declare -r _recordsFilter="${2}"

    local _recordsDir
    getRecordsDir _recordsDir
    mapfile -t _retRecordFiles < <(find "${_recordsDir}" -regextype egrep -iregex "${_recordsFilter}" | LC_ALL=C sort -f)
}

getRelativePathAndName(){
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

getPagePath() {
    declare -n _retPath="${1}"
    declare -r _pageNamePrefix="${2}"
    declare -ri _pageNo="${3}"
    _retPath="${ENV_OUTPUT_DIR:?}/pages/${_pageNamePrefix}_${_pageNo}.md"
}

getPageLinks() {
    declare -n _retPageLinks="${1}"
    declare -r _totalPages="${2}"
    declare -i _layoutNo="${3}"

    _retPageLinks=""
    local _pageLink
    for i in $(seq 1 "${_totalPages}");do
        printf -v _pageLink "[[Page %d](page_l%d_%d.md)]" "${i}" "${_layoutNo}" "${i}"
        _retPageLinks="${_retPageLinks} ${_pageLink}"
    done
}

printPageHeaderAndFooter(){
    declare -nr _recordFiles4="${1}"
    declare -r _pagePath="${2}"
    declare -i _pageNo="${3}"
    declare -i _layoutNo="${4}"
    declare -r _vhsVersion="${4}"

    declare -i _totalPages
    getTotalPages _totalPages _recordFiles4
    local _pageLinksLayout1=""
    getPageLinks _pageLinksLayout1 "${_totalPages}" 1
    local _pageLinksLayout2=""
    getPageLinks _pageLinksLayout2 "${_totalPages}" 2
    declare -ir _totalRecords="${#_recordFiles4[@]}"

    printf "# VHS Themes\n\n" > "${_pagePath}"
    local _layout1Links=""
    local _layout2Links=""
    if (( _layoutNo == 1 ));then
        _layout1Links="**Layout 1: ${_pageLinksLayout1}**"
        _layout2Links="Layout 2: ${_pageLinksLayout2}"
    else
        _layout1Links="Layout 1:${_pageLinksLayout1}"
        _layout2Links="**Layout 2:${_pageLinksLayout2}**"
    fi
    {
        printf "Page %d of %d (layout %d)\n\n" "${_pageNo}" "${_totalPages}" "${_layoutNo}"
        printf "Total of %d records (themes) generated with \`%s\`\n\n" "${_totalRecords}" "${_vhsVersion}"
        printf "[[< Home](../../main)] [[Index](index.md)]<br>\n"
        printf "%s<br>\n" "${_layout1Links}"
        printf "%s<br>\n" "${_layout2Links}"
        printf "> Tip: Resize the records by resizing the page\n\n"
    } >> "${_pagePath}"
}

printPageBody(){
    declare -nr _recordFiles1="${1}"
    declare -r _pageNamePrefix="${2}"
    declare -ir _pageNo="${3}"

    local _pagePath=""
    getPagePath _pagePath "${_pageNamePrefix}" "${_pageNo}"

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
        getRelativePathAndName _path _name "${_recordFile}"
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
    declare -r _pagePrefixName="${2}"

    declare -i _totalPages=0
    getTotalPages _totalPages _recordFiles

    for _pageNo in $(seq 1 "${_totalPages}"); do
        printPageBody _recordFiles "${_pagePrefixName}" "${_pageNo}"
    done
}

# This creates a README inside output dir
# This is done here so it can be tested before calling publish
createREADME() {
    declare -r _readmePath="${ENV_OUTPUT_DIR}/README.md"
    logInfo "Create ${_readmePath}"
    rm -fr "${_readmePath}"
    cp "${ENV_OUTPUT_DIR}"/pages/page_1.md "${_readmePath}"
    sed -i 's/..\/records\//records\//g' "${_readmePath}"
    sed -i 's/(index.md)/(pages\/index.md)/g' "${_readmePath}"
    sed -i 's/(page_/(pages\/page_/g' "${_readmePath}"
    sed -i 's/(..\/..\/main)/(..\/main)/' "${_readmePath}"
}

createIndex(){
    declare -nr _recordFiles="${1}"
    declare -r _indexPath="${ENV_OUTPUT_DIR}/pages/index.md"
    logInfo "Create ${_indexPath}"
    printf "# Index\n\n" > "${_indexPath}"
    local _path
    local _name
    for _recordFile in "${_recordFiles[@]}"; do
        getRelativePathAndName _path _name "${_recordFile}"
        printf "1. [%s](%s)\n" "${_name}" "${_path}" >> "${_indexPath}"
    done
}

rm -fr "${ENV_OUTPUT_DIR:?}"/pages
mkdir -p "${ENV_OUTPUT_DIR}"/pages

vhsVersion=$(vhs --version)
readonly vhsVersion
declare -a recordsFiles

getFilteredRecordFiles recordsFiles ".*\.gif"
createPages recordsFiles "page"
createIndex recordsFiles
getFilteredRecordFiles recordsFiles ".*(dark|night).*\.gif"
createPages recordsFiles "dark_or_night"
getFilteredRecordFiles recordsFiles ".*(light|day).*\.gif"
createPages recordsFiles "light_or_day"


createREADME

logInfo "Paging done!"
