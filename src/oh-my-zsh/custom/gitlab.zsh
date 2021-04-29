function lab-mr-release()(
    # usage: lab-mr-release 0.0.0 --draft -m "MR Title"
    [[ -z "$(git status --porcelain)" ]] || exit 1

    VERSION=$1
    shift
    set -e

    if [[ -z ${existed_in_remote} ]]; then
        # Nothing
    else
        echo GITLAB_USER must be set.
        exit 1
    fi

    GITLAB_REMOTE=${GITLAB_REMOTE:-origin}
    GITLAB_REMOTE=${GITLAB_REMOTE:-origin}
    GITLAB_TRUNK=${GITLAB_TRUNK:-master}
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    RELEASE_BRANCH=release/$VERSION

    git push -u $GITLAB_REMOTE $CURRENT_BRANCH
    local existed_in_remote=$(git ls-remote --heads origin ${RELEASE_BRANCH})
    if [[ -z ${existed_in_remote} ]]; then
        git checkout $GITLAB_TRUNK
        git pull
        git checkout -b $RELEASE_BRANCH
        git push -u $GITLAB_REMOTE $RELEASE_BRANCH
        git checkout $CURRENT_BRANCH
    else
        echo $RELEASE_BRANCH already exists.
        exit 1
    fi
    lab merge-request -a $GITLAB_USER --remove-source-branch --squash $GITLAB_REMOTE $RELEASE_BRANCH $@
)

lab-mr-retarget()(
    # usage: lab-mr-retarget 0.0.1
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
        git checkout $GITLAB_TRUNK
        git pull
        git checkout -b $RELEASE_BRANCH
        git push -u $GITLAB_REMOTE $RELEASE_BRANCH
        git checkout $CURRENT_BRANCH
    else
        echo $RELEASE_BRANCH already exists.
        exit 1
    fi
    lab mr edit --target-branch $RELEASE_BRANCH
)

alias lab-mr-browse="lab mr browse"
alias lab-mr-ready="lab mr edit --ready"
alias lab-browse="lab project browse"
