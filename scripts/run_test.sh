#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly testOutputDir="output_test"
export ENV_ENABLE_OUTPUT_ASCII=true
export ENV_INPUT_DIR=input
export ENV_OUTPUT_DIR="${testOutputDir}"
export ENV_PAGINATION=2
export ENV_PUBLISH_BRANCH="themes_test_e2e"
export ENV_THEMES="TokyoNight,adventure,3024 Day,Adventure,Aurora"
export ENV_THEMES_LIMIT=3

source scripts/env.sh
source scripts/metadata.sh

logInfo "Testing started..."

testMetadata(){
    generateMetadata
    declare -r _expectedMetadata="Themes: TokyoNight,adventure,3024 Day,Adventure,Aurora
Themes limit: 3
Pagination: 2
Themes recorded count: 3
Themes recorded: 3024 Day,Adventure,Aurora
Duplicate themes count: 1
Duplicate themes: adventure"

    local _metadata
    # remove 1st and 5th lines for now
    _metadata=$(sed '1d;5d' "${metadataFilePath}")

    if [[ "${_metadata}" != "${_expectedMetadata}" ]]; then
        logError "Expected and actual metadata differ"
        printf "Expected:\n%s\nGot:\n%s\n" "${_expectedMetadata}" "${_metadata}" 1>&2
        exit 1
    fi
}

testRecordAndPage(){
    removeMetadataLock
    ./scripts/run_record.sh
    ./scripts/run_page.sh

    declare -r _expectedOutputFilesAndDirs="${testOutputDir}
${testOutputDir}/README.md
${testOutputDir}/pages
${testOutputDir}/pages/index.md
${testOutputDir}/pages/page_l1_1.md
${testOutputDir}/pages/page_l1_2.md
${testOutputDir}/pages/page_l2_1.md
${testOutputDir}/pages/page_l2_2.md
${testOutputDir}/records
${testOutputDir}/records/3024 Day.ascii
${testOutputDir}/records/3024 Day.gif
${testOutputDir}/records/Adventure.ascii
${testOutputDir}/records/Adventure.gif
${testOutputDir}/records/Aurora.ascii
${testOutputDir}/records/Aurora.gif"

    _outputFilesAndDirs=$(find "${ENV_OUTPUT_DIR}" | LC_ALL=C sort)

    if [[ "${_outputFilesAndDirs}" != "${_expectedOutputFilesAndDirs}" ]]; then
        logError "Expected and actual generated contents differ"
        printf "Expected:\n%s\nGot:\n%s\n" "${_expectedOutputFilesAndDirs}" "${_outputFilesAndDirs}" 1>&2
        exit 1
    fi
}

testPublish(){
    declare -r _outputFilePath="/tmp/output.txt"
    # Output error to stdout and save output to a file for later comparison
    ./scripts/run_publish.sh 2>&1 | tee "${_outputFilePath}"
    _expectedMessage="Publishing to branch '${ENV_PUBLISH_BRANCH}' is done"
    if ! grep -q "${_expectedMessage}" "${_outputFilePath}";then
        logError "Expected message: ${_expectedMessage}"
        exit 1
    fi

    ./scripts/run_check_metadata.sh

    # Add unwanted file
    printf "This file should not be part of the publish branch\n" > "${ENV_OUTPUT_DIR}"/test.txt

    _expectedMessage="Metadata check: stop the script because '${testOutputDir}/metadata.lock' exists"

    ./scripts/run_publish.sh 2>&1 | tee "${_outputFilePath}"
    if ! grep -q "${_expectedMessage}" "${_outputFilePath}";then
        logError "Expected message: ${_expectedMessage}"
        exit 1
    fi
}

testDownload(){
    rm -fr "${testOutputDir}"
    ./scripts/run_download.sh
    ./scripts/run_check_metadata.sh

    declare -r _outputFilePath="/tmp/output.txt"
    ./scripts/run_publish.sh 2>&1 | tee "${_outputFilePath}"

    _expectedMessage="Metadata check: stop the script because '${testOutputDir}/metadata.lock' exists"

    if ! grep -q "${_expectedMessage}" "${_outputFilePath}";then
        logError "Expected message: ${_expectedMessage}"
        exit 1
    fi
}

rm -fr "${testOutputDir}"
shellcheck --enable all scripts/*.sh
testMetadata
testRecordAndPage

if [[ "${ENV_INT_TEST_E2E:?}" == "true" ]]; then
    testPublish
    testDownload
fi

rm -fr "${testOutputDir}"

logInfo "Testing done!"
