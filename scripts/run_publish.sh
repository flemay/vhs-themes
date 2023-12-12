#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# Inspired by https://gist.github.com/joncardasis/e6494afd538a400722545163eb2e1fa5

source scripts/env.sh
logInfo "Publishing to branch '${ENV_PUBLISH_BRANCH}' started..."
source scripts/metadata.sh
checkMetadataLock
generateMetadata

# preparePublishBranch creates a new local orphan branch (which has no history and tracked files).
# According to Git:
# --orphan <new-branch>
#     Create a new orphan branch, named <new-branch>. All tracked files are removed.
# All of this creation is done from a copy of the current dir to another one so that anything that happens won't have any effect on the current dir.
# The publish branch contents is basically the output dir with a clean up to ensure unwanted files are not going to be published.
# So far the best way to only get the correct contents on the publish branch is to create a specific .gitignore files.
# References
# - https://git-scm.com/docs/git-switch/2.23.0
preparePublishBranch() {
    declare -r tmpRepoDir="/tmp/${ENV_GIT_REPO_NAME:?}"
    rm -fr "${tmpRepoDir}"
    mkdir "${tmpRepoDir}"
    cp -r . "${tmpRepoDir}"/

    cd "${tmpRepoDir}"

    git restore .
    git branch -D "${ENV_PUBLISH_BRANCH:?}" &> /dev/null || true
    git switch --orphan "${ENV_PUBLISH_BRANCH:?}"
    # remove all files/dirs that are not tracked (excluding output dir)
    git clean -d --exclude="${ENV_OUTPUT_DIR:?}" --force

    # create a new .gitignore specifically for publish branch
    printf "*\n" > .gitignore
    {
        printf "!README.md\n"
        printf "!records\n"
        printf "!records/*.gif\n"
        printf "!pages\n"
        printf "!pages/*.md\n"
        printf "!metadata.txt\n"
    } >> .gitignore

    cp -r "${ENV_OUTPUT_DIR:?}"/* .
    rm -fr "${ENV_OUTPUT_DIR}"

    # Checksum based on git status (that was before metadata)
    # https://stackoverflow.com/questions/35326218/git-ls-files-how-to-escape-spaces-in-files-paths
    # rm -fr checksum.txt
    # git status -suall \
    #    | cut -c 4- \
    #    | LC_ALL=C sort \
    #    | tr '\n' '\0' \
    #    | tr -d '"' \
    #    | xargs -0 -n 1 sha256sum \
    #    | sha256sum \
    #    > checksum.txt
}

# checkGitStatus makes sure the publish branch does not have commits or staged files
# It also checks unstaged files are the expected ones such as .gitignore, README.md, pageXX.md, records/*.gif.
# This is to prevent pushing unwanted files.
# Some checks are perhaps overkill but better be safe than sorry.
# The command git status -suall shows something like
#?? .gitignore
#?? README.md
#?? "records/3024 Day.gif"
#?? records/Abernathy.gif
#?? page1.md
#?? metadata.txt
checkGitStatus() {
    # Expect git log to return an error
    ! git log &> /dev/null || {
        logError "Publish branch ${ENV_PUBLISH_BRANCH} should not have any commits"
        exit 1
    }

    # https://www.shellcheck.net/wiki/SC2155
    declare -i _totalStagedFiles
    _totalStagedFiles=$(git status -s -uno | wc -l)
    declare -r _totalStagedFiles
    (( _totalStagedFiles == 0 )) || {
        logError "Expected number of staged files to be 0"
        git status 1>&2
        exit 1
    }

    declare -r _unstagedFilesRegExp="^README\.md$|^page.+\.md$|^[\"]?records/.*\.gif[\"]?$|^metadata.txt$"
    if git status -suall \
        | cut -c 4- \
        | grep -Ev "${_unstagedFilesRegExp}"; then
        logError "There are files that should not be part of git status"
        git status -suall \
            | cut -c 4- \
            | grep -Ev "${_unstagedFilesRegExp}" 1>&2
        exit 1
    fi
}

configureGitConfig() {
    git config user.email "${ENV_GIT_EMAIL:?}"
    git config user.name "${ENV_GIT_NAME:?}"
    git remote remove originForPublishing &> /dev/null || true
    git remote add originForPublishing "${ENV_GIT_REPO_URL:?}"
}

commitAndPush() {
    git add .
    git commit -m "Publish themes"
    # shellcheck disable=SC2310
    gitAuth push originForPublishing -d "${ENV_PUBLISH_BRANCH:?}" &> /dev/null || true
    gitAuth push originForPublishing "${ENV_PUBLISH_BRANCH:?}"
}

cleanup() {
    rm -fr /tmp/"${ENV_GIT_REPO_NAME}"
}

preparePublishBranch
checkGitStatus
configureGitConfig
commitAndPush
cleanup

logInfo "Publishing to branch '${ENV_PUBLISH_BRANCH}' is done!"
