function glab-mr-release()(
    # usage: glab-mr-release 0.0.0 --draft --title="MR Title"
    [[ -z "$(git status --porcelain)" ]] || exit 1

    VERSION=$1
    shift
    set -e

    GITLAB_REMOTE=${GITLAB_REMOTE:-origin}
    GITLAB_TRUNK=${GITLAB_TRUNK:-master}
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    RELEASE_BRANCH=release/$VERSION

    git push -u $GITLAB_REMOTE $CURRENT_BRANCH
    local existed_in_remote=$(git ls-remote --heads origin ${RELEASE_BRANCH})
    if [[ -z ${existed_in_remote} ]]; then
        glab api --silent -X POST "projects/:fullpath/repository/branches?ref=master&branch=$RELEASE_BRANCH"
    else
        echo $RELEASE_BRANCH already exists.
        exit 1
    fi
    glab mr create  --remove-source-branch --squash --target-branch $RELEASE_BRANCH $@
)

glab-mr-retarget()(
    # usage: glab-mr-retarget 0.0.1
    [[ -z "$(git status --porcelain)" ]] || exit 1

    VERSION=$1
    shift
    set -e

    GITLAB_REMOTE=${GITLAB_REMOTE:-origin}
    GITLAB_TRUNK=${GITLAB_TRUNK:-master}
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    RELEASE_BRANCH=release/$VERSION

    git push -u $GITLAB_REMOTE $CURRENT_BRANCH
    git fetch
    local existed_in_remote=$(git ls-remote --heads origin ${RELEASE_BRANCH})
    if [[ -z ${existed_in_remote} ]]; then
        glab api --silent -X POST "projects/:fullpath/repository/branches?ref=master&branch=$RELEASE_BRANCH"
    else
        echo $RELEASE_BRANCH already exists.
        exit 1
    fi
    glab mr update --target-branch $RELEASE_BRANCH
)

alias glab-mr-browse="glab mr view --web"
alias glab-mr-ready="lab mr update --ready"
alias lab-browse="lab project browse"
