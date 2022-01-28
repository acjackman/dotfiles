function op_value {
    op get item $1 | read ITEM
    if [[ $2 =~ ^(username|user|u)$ ]]; then
        echo $ITEM | jq -e -r ".details.fields[] | select(.name==\"username\" or .designation==\"username\") | .value"
    elif [[ $2 =~ ^(password|pwd|p)$ ]]; then
        echo $ITEM | jq -e -r ".details.fields[] | select(.name==\"password\" or .designation==\"password\") | .value"
    else
        local SECTION_TITLE=$2
        local FIELD_TITLE=$3
        echo $ITEM | jq -e -r ".details.sections[] | select(.title==\"$SECTION_TITLE\") | .fields[] | select(.t==\"$FIELD_TITLE\") | .v"
    fi
}

function op_dburl() {
    # Usage op_dburl "<DB item name>"

    # Get item from argument, and exit if unable
    op get item $1  | read DB_ITEM
    if [ $? -ne 0 ]; then
        return 2
    fi
    # Check that 1Password item is a database
    if [ $(echo $DB_ITEM | jq -r '.templateUuid') -ne "102" ]; then
        >&2 echo "1Password Item is not a database"
        return 3
    fi

    # Select the fields
    DB_FIELDS=$(echo $DB_ITEM | jq '.details.sections[0].fields[]')
    function jqs() {
        echo $DB_FIELDS | jq -r $@
    }

    # extract the parts of the db
    TYPE=$(jqs 'select(.n=="database_type") | .v ')
    USER=$(jqs 'select(.n=="username") | .v ')
    PASSWORD=$(jqs 'select(.n=="password") | .v ')
    HOST=$(jqs 'select(.n=="hostname") | .v ')
    PORT=$(jqs 'select(.n=="port") | .v ')
    DATABASE=$(jqs 'select(.n=="database") | .v ')

    # Echo the formatted url to standard out
    echo "$TYPE://${USER}:${PASSWORD}@${HOST}:${PORT}/${DATABASE}"
}

function cfoutput() {
  local STACK=$1
  local VAR=$2
  aws-cli cloudformation describe-stacks \
    --stack-name $STACK \
    --output text \
    --query "Stacks[0].Outputs[?OutputKey==\`$VAR\`].OutputValue | [0]" \
  | cat
}

function awslogout() {
    export AWS_PROFILE=
    export AWS_ACCESS_KEY_ID=
    export AWS_SECRET_ACCESS_KEY=
    export AWS_SESSION_TOKEN=
    rm -rf ~/.aws/cli
    rm -rf ~/.aws/sso
}


function awswho() {
    echo AWS_PROFILE=${AWS_PROFILE}
    awswhoami
}


function awsso() {
    # Only login if credentials have timed out
    # Usage: `awsso $AWS_PROFILE`
    local PROFILE=$1

    aws-cli sts get-caller-identity --profile $PROFILE > /dev/null
    if [ $? -ne 0 ]; then
        # Login if unable to get caller identity
        aws-cli sso login --profile $PROFILE
    fi

    export AWS_PROFILE=$PROFILE
}

function export_sso_creds() (
    # Export CLI credentials for boto+other apps to use SSO role
    # Usage: `eval $(export_sso_creds $AWS_PROFILE)`
    set -e -o pipefail
    local PROFILE="$1"

    [ -v "$PROFILE" ] && {
        # Fallback on AWS_PROFILE
        echo "# No profile provided falling back to AWS_PROFILE='$AWS_PROFILE'"
        PROFILE=$AWS_PROFILE
    }
    [[ $PROFILE =~ ^[_A-z0-9-]+$ ]] || {
        echo "Must specify an PROFILE with only [_A-z0-9-]. Got '$1'"
        exit 1
    }
    echo "# Getting credentials for profile '$PROFILE'"

    local CONFIG_SCRIPT='import configparser, json, os, sys; config = configparser.ConfigParser(); config.read(os.path.expanduser("~/.aws/config")); profile = config[f"profile {sys.argv[1]}"]; data = dict(account_id=profile["sso_account_id"], role_name=profile["sso_role_name"]); print(json.dumps(data));'
    config=$(python -c $CONFIG_SCRIPT $PROFILE) || { echo "# profile does not exist in aws config"; exit 1 }
    echo "# Found in AWS config: $config"
    local ACCOUNT_ID=$(echo $config | jq -r ".account_id")
    local ROLE_NAME=$(echo $config | jq -r ".role_name")

    # Borrow the access token from the aws cli rather than generating our own.
    local ACCESS_TOKEN=$(cat $(ls -1d ~/.aws/sso/cache/* | grep -v botocore) |  jq -r "{accessToken} | .[]")

    creds="$(aws-cli sso get-role-credentials --role-name $ROLE_NAME --account-id $ACCOUNT_ID --access-token $ACCESS_TOKEN --query roleCredentials --output json)"
    echo $creds | jq -r '"export AWS_ACCESS_KEY_ID=" + .accessKeyId'
    echo $creds | jq -r '"export AWS_SECRET_ACCESS_KEY=" + .secretAccessKey'
    echo $creds | jq -r '"export AWS_SESSION_TOKEN=" + .sessionToken'
)
# Usage
# export AWS_PROFILE=fulcrum-dev  # Or any profile from ~/.aws/config
# awssso $AWS_PROFILE  # logs into the AWS CLI with the specified profile
# eval "$(export_sso_creds $AWS_PROFILE)"


function okta_aws() (
  # Usage: okta_aws c-networking

  set -e -o pipefail

  if [[ -z "$OP_ITEM_OKTA" ]]  then
    echo "\$OP_ITEM_OKTA is not set"
    exit 1
  fi

  if [ $# -eq 0 ]
  then
    echo "No profiles specified"
  fi

  while [[ $# -ne 0 ]]; do
    local PROFILE_NAME=$1
    shift

    local MFA_CODE=$(op get totp "$OP_ITEM_OKTA")
    if [[ $MFA_CODE =~ ^[0-9]{6}$ ]] then
      echo "Authenticating for $PROFILE_NAME"
      gimme-aws-creds --mfa-code=$MFA_CODE --profile=$PROFILE_NAME --remember-device
    else
      echo "Unable to fetch MFA code from '$OP_ITEM_OKTA'"
      exit 2
    fi

    if [[ $# -ne 0 ]] then
      echo "Waiting for next MFA code..."
      sleep 32
    fi
  done
)


function oktap_aws() (
  # Usage: okta_aws c-networking

  set -e -o pipefail

  if [ $# -eq 0 ]
  then
    echo "No profiles specified"
  fi

  while [[ $# -ne 0 ]]; do
    local PROFILE_NAME=$1
    shift

      echo "Authenticating for $PROFILE_NAME"
      gimme-aws-creds --profile=$PROFILE_NAME --remember-device

  done
)


function pylv() {
    DIRNAME=${PWD##*/}
    LATEST_PY=$(pyenv versions --bare --skip-aliases | sed '/\//d' | tail -1)
    PY_VERSION=${1:-$LATEST_PY}
    # DEFAULT_NAME=$DIRNAME$(echo $PY_VERSION | sed -E 's/([0-9]+).([0-9]+).([0-9]+)/\1.\2/')
    DEFAULT_NAME=$DIRNAME
    ENV_NAME=${2:-$DEFAULT_NAME}
    echo "pyenv virtualenv $PY_VERSION $ENV_NAME && pyenv local $ENV_NAME"
    pyenv virtualenv $PY_VERSION $ENV_NAME \
      && pyenv local $ENV_NAME \
      && pip install --upgrade pip \
      && pip install ipython importmagic epc
}

function pydel() {
    pyenv virtualenv-delete $(pyenv version-name)
    [[ -f ".python-version" ]] && {
        rm .python-version
    }
}


function repo-setup(){
    git config alias.pull-trunk 'fetch origin main:main'
    pre-commit install
}

function headphones(){
  SwitchAudioSource -t output -s "Adam’s AirPods Max"
  SwitchAudioSource -t input -s "Adam’s AirPods Max"
}


# fd - cd to selected directory
fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

# fh - search in your command history and execute selected command
fh() {
  eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
}
