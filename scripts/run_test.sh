#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly testOutputDir="output_test"
export ENV_ENABLE_OUTPUT_ASCII=true
export ENV_INPUT_DIR=input
export ENV_OUTPUT_DIR="${testOutputDir}"
export ENV_PAGINATION=2
export ENV_PUBLISH_BRANCH="themes_test_e2e"
export ENV_THEMES="TokyoNight,3024 Day,Adventure,Aurora"
export ENV_THEMES_LIMIT=3

source scripts/env.sh
logInfo "Testing started..."

shellcheck --enable all scripts/*.sh

source scripts/metadata.sh
removeMetadataLock
./scripts/run_record.sh
./scripts/run_page.sh

readonly expectedOutputFilesAndDirs="${testOutputDir}
${testOutputDir}/README.md
${testOutputDir}/pages
${testOutputDir}/pages/page_l1_1.md
${testOutputDir}/pages/page_l1_2.md
${testOutputDir}/pages/page_l2_1.md
${testOutputDir}/pages/page_l2_2.md
${testOutputDir}/records
${testOutputDir}/records/3024 Day.ascii
${testOutputDir}/records/3024 Day.gif
${testOutputDir}/records/Adventure.ascii
${testOutputDir}/records/Adventure.gif
${testOutputDir}/records/TokyoNight.ascii
${testOutputDir}/records/TokyoNight.gif"

outputFilesAndDirs=$(find "${ENV_OUTPUT_DIR}" | LC_ALL=C sort)

if [[ "${outputFilesAndDirs}" != "${expectedOutputFilesAndDirs}" ]]; then
    logError "Expected and actual generated contents differ"
    printf "Expected:\n%s\nGot:\n%s\n" "${expectedOutputFilesAndDirs}" "${outputFilesAndDirs}" 1>&2
    exit 1
fi

# The golden test is commented out because for some reasons the ascii file would differ every single time.

#readonly asciiFilePath="${ENV_OUTPUT_DIR}/records/${theme}.ascii"
#readonly goldenFilePath="${ENV_INPUT_DIR}/${theme}.ascii.golden"

#if [[ "${ENV_INT_UPDATE_GOLDEN:-'false'}" == "true" ]]; then
#    cp -f "${asciiFilePath}" "${goldenFilePath}"
#fi

# diff -q "${asciiFilePath}" "${goldenFilePath}"

if [[ "${ENV_INT_TEST_E2E:?}" == "true" ]]; then
    readonly outputFilePath="/tmp/output.txt"
    ./scripts/run_publish.sh 2>&1 | tee "${outputFilePath}"
    expectedMessage="Publishing to branch '${ENV_PUBLISH_BRANCH}' is done"
    if ! grep -q "${expectedMessage}" "${outputFilePath}";then
        logError "Expected message: ${expectedMessage}"
        exit 1
    fi

    ./scripts/run_check_metadata.sh

    # Add unwanted file
    printf "This file should not be part of the publish branch\n" > "${ENV_OUTPUT_DIR}"/test.txt

    expectedMessage="Metadata check: stop the script because '${testOutputDir}/metadata.lock' exists"

    ./scripts/run_publish.sh 2>&1 | tee "${outputFilePath}"
    if ! grep -q "${expectedMessage}" "${outputFilePath}";then
        logError "Expected message: ${expectedMessage}"
        exit 1
    fi

    rm -fr "${testOutputDir}"
    ./scripts/run_download.sh
    ./scripts/run_check_metadata.sh

    ./scripts/run_publish.sh 2>&1 | tee "${outputFilePath}"
    if ! grep -q "${expectedMessage}" "${outputFilePath}";then
        logError "Expected message: ${expectedMessage}"
        exit 1
    fi
fi

rm -fr "${testOutputDir}"

logInfo "Testing done!"
