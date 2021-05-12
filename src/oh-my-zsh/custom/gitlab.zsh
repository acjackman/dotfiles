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

    # check if there is already a open MR for this branch, and error if so
    PROJECT_PATH=$(git remote -v | awk '{ print $2}' | sort | uniq | grep "git@gitlab.com" | sed 's/git@gitlab\.com://' | sed 's/\.git//')
    OPEN_MR=$(glab api graphql -f repo=$PROJECT_PATH -f branch=$CURRENT_BRANCH -f state=opened -f query='
        query($repo: ID!, $branch: String!, $state: MergeRequestState) {
          project(fullPath: $repo) {
            name
            mergeRequests(sourceBranches: [$branch], state: $state){
              nodes {
                iid
                title
                sourceBranch
                webUrl
              }
            }
          }
        }' | jq -c '.data.project.mergeRequests.nodes[]' | sed 's/}/}\n/g' | head -1)
    if [[ $OPEN_MR != "" ]]; then
        echo "Merge request already exists for '${CURRENT_BRANCH}': !$(echo $OPEN_MR | jq -r '.iid') $(echo $OPEN_MR | jq -r '.title') ($(echo $OPEN_MR | jq -r '.webUrl'))"
        exit 1
    fi

    # Make sure current branch is on gitlab
    git push -u $GITLAB_REMOTE $CURRENT_BRANCH

    # Check not targeting an existing release
    local existed_in_remote=$(git ls-remote --heads origin ${RELEASE_BRANCH})
    if [[ -z ${existed_in_remote} ]]; then
        echo "Creating '$RELEASE_BRANCH'"
        glab api --silent -X POST "projects/:fullpath/repository/branches?ref=master&branch=$RELEASE_BRANCH"
    else
        echo "Release branch '$RELEASE_BRANCH' already exists."
        exit 1
    fi
    git fetch > /dev/null  # glab needs to know about the release branch to work

    # Create the merge request
    glab mr create --assignee=$GITLAB_USER --remove-source-branch --target-branch="$RELEASE_BRANCH" --fill --yes $@
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
    glab mr create --remove-source-branch --target-branch=wip --draft -d '' --fill --yes $@
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
    PROJECT_PATH=$(git remote -v | awk '{ print $2}' | sort | uniq | grep "git@gitlab.com" | sed 's/git@gitlab\.com://' | sed 's/\.git//')

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
function glab-path(){
    git remote -v | awk '{ print $2 }' | sort | uniq | grep 'git@gitlab.com' | sed 's/git@gitlab\.com://' | sed 's/\.git//'
}


function check-versions(){
    echo "master: $(pyv-master)"
    echo "Open MRs:"
    PROJECT_PATH=$(glab-path)
    glab api graphql --paginate -f fullPath=$PROJECT_PATH -f state=opened -f query='
    query ($fullPath: ID!, $state: MergeRequestState, $endCursor: String) {
      project(fullPath: $fullPath) {
        mergeRequests(state: $state, after: $endCursor) {
          nodes {
            targetBranch
            sourceBranch
            iid
            title
            assignees(first:10){
              nodes {
                username
              }
            }
          }
          pageInfo{
            endCursor
            hasNextPage
          }
        }
      }
    }'\
    | jq -r '
      .data.project.mergeRequests.nodes[]
      | .assignee_mentions = (.assignees.nodes[0] | .username)
      |.targetBranch + " ← " + .sourceBranch + "  @" + .assignee_mentions  + "  !" + .iid + " " + .title
    ' \
    | grep -E '^(release|hotfix)/.+' | cat
    echo "Recently Merged:"
    glab api graphql -f fullPath=$PROJECT_PATH -f state=merged -f sort=MERGED_AT_DESC -f query='
    query ($fullPath: ID!, $state: MergeRequestState, $sort: MergeRequestSort) {
      project(fullPath: $fullPath) {
        mergeRequests(first: 20, state: $state, sort: $sort) {
          nodes {
            targetBranch
            sourceBranch
            iid
            title
            assignees(first:10){
              nodes {
                username
              }
            }
          }
        }
      }
    }'\
    | jq -r '
      .data.project.mergeRequests.nodes[]
      | .assignee_mentions = (.assignees.nodes[0] | .username)
      |.targetBranch + " ← " + .sourceBranch + "  @" + .assignee_mentions  + "  !" + .iid + " " + .title
    ' \
    | grep -E '^(release|hotfix)/.+' | head -3
}
alias gpw="git push && glab ci view"
alias glab-mr-url="glab mr view | sed '/--/d' | yq eval '.url' -"
