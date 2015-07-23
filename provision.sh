#!/usr/bin/env bash
# This script acts as a wrapper to Terraform.
# ensure you have aws cli installed:
#
#   sudo apt-get install awscli
#

ENVIRONMENTS=(dc0 dc2)
APP_NAME=elk
HELPARGS=("help" "-help" "--help" "-h" "-?")

ACTION=$1
ENVIRONMENT=$2

function help {
    echo "USAGE: ${0} <action> <environment>"
    echo -n "Valid environments are: "
    local i
    for i in "${ENVIRONMENTS[@]}"; do
        echo -n "$i "
    done
    echo ""
    exit 1
}

function contains_element () {
    local i
    for i in "${@:2}"; do
        [[ "$i" == "$1" ]] && return 0
    done
    return 1
}

# Is terraform in PATH?  If not, it should be.
if which terraform > /dev/null;then
    PATH=$PATH:/usr/local/bin/terraform
fi

# Is this a cry for help?
contains_element "$1" "${HELPARGS[@]}"
if [ "${1}x" == "x" ]; then
    help
fi

# Did we want to generate symlinks?
if [ "$1" == "setup" ]; then
    remake_symlinks
    exit 0
fi

# All of the args are mandatory.
if [ $# != 2 ]; then
    help
fi

# Validate the desired role.
contains_element "$2" "${ENVIRONMENTS[@]}"
if [ $? -ne 0 ]; then
    echo "ERROR: $3 is not a valid environment"
    exit 1
fi

source ./.terraform.cfg
source $CONFIG_LOCATION/.aws.$ENVIRONMENT

# Pre-flight check is good, let's continue.

TFVARS="-var-file=${CONFIG_LOCATION}/${APP_NAME}/${ENVIRONMENT}.tfvars"
echo $TFVARS
# Be verbose and bail on errors.
set -ex

# Nab the latest tfstate.
aws s3 sync --region=$REGION --exclude="*" --include="terraform.tfstate" "s3://${BUCKET}/${BUCKET_KEY}" ./

# Run TF; if this errors out we need to keep going.
set +e
terraform $ACTION $TFVARS
EXIT_CODE=$?
set -e

# Upload tfstate to S3.
aws s3 sync --region=$REGION --exclude="*" --include="terraform.tfstate" ./ "s3://${BUCKET}/${BUCKET_KEY}"

exit $EXIT_CODE
