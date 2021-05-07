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
    glab mr create --remove-source-branch --target-branch=$RELEASE_BRANCH $@
)

function glab-mr-wip()(
    # usage: glab-mr-release --title="MR Title"
    [[ -z "$(git status --porcelain)" ]] || exit 1
    set -e

    GITLAB_REMOTE=${GITLAB_REMOTE:-origin}
    GITLAB_TRUNK=${GITLAB_TRUNK:-master}
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    RELEASE_BRANCH=release/$VERSION

    git push -u $GITLAB_REMOTE $CURRENT_BRANCH
    glab mr create --remove-source-branch --target-branch=$GITLAB_TRUNK --draft -d '' --fill --yes $@
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

function glab-prune-merged(){
    PAGE=${1:-1}
    BRANCHES=($(
        glab mr list --merged --per-page=50 --page=$PAGE \
        | grep -E '^!' \
        | sed 's/.*← (\(.*\))/\1/g' \
        | sed '/^$/d' \
        | sed '/(master)/d'
    ))
    for BRANCH in "${BRANCHES[@]}"; do
        git rev-parse --quiet --verify "$BRANCH" && {
            git branch -D "$BRANCH"
        } || {
            # pass
        }
    done
}


alias glab-mr-browse="glab mr view --web"
alias glab-mr-ready="lab mr update --ready"
alias lab-browse="lab project browse"
