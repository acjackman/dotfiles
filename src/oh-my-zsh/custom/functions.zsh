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
  aws cloudformation describe-stacks \
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
}


function awswho() {
    echo AWS_PROFILE=${AWS_PROFILE}
    awswhoami
}
