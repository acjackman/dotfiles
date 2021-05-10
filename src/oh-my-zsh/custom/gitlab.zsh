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
    glab mr create --remove-source-branch --target-branch=$RELEASE_BRANCH --fill --yes $@
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

function glab-prune-merged()(
    PROJECT_PATH=$(glab api graphql -F words=:fullpath -f query='
    query($words: String!) {
      echo(text: $words)
    }' | jq -r '.data.echo' | sed 's/.*says: //' | sed 's|%2F|/|g')

    CHECK_BRANCHES=($(git branch | cut -c3- | sed -e 's/\s+//g' | sed -E '/^(master|release)\/?.*$/d' | sed -e '/^$/d'))
    # echo "branches=$CHECK_BRANCHES"

    for BRANCH in "${CHECK_BRANCHES[@]}"; do
        # echo "Checking \"$BRANCH\""
        BRANCH_DATA=$(glab api graphql -f repo=$PROJECT_PATH -f branch=$BRANCH -f query='
        query($repo: ID!, $branch: String!) {
          project(fullPath: $repo) {
            name
            mergeRequests(sourceBranches: [$branch]){
              nodes {
                iid
                title
                sourceBranch
                mergedAt
              }
            }
          }
        }')
        MERGED_AT=$(echo $BRANCH_DATA | jq -r '.data.project.mergeRequests.nodes[0].mergedAt' | sed "s/null//")
        if [[ "$MERGED_AT" != "" ]]; then
            echo $BRANCH_DATA | jq -r '.data.project.mergeRequests.nodes[0] | "Branch \"" + .sourceBranch + "\" merged at " + .mergedAt + " with !" + .iid + " " + .title'
            git branch -D "$BRANCH"
        fi
    done
)


function glab-prune-release(){
    git branch  | cut -c3- | egrep "^(release|hotfix)/" | xargs git branch -D
}

alias glab-mr-browse="glab mr view --web"
alias glab-mr-ready="lab mr update --ready"
alias lab-browse="lab project browse"
