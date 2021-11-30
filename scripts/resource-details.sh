#!/bin/bash

usage() {
  cat 1>&2 <<EOF
Display details of all resources in a CloudFormation stack.

USAGE:

  ./scripts/resource-details.sh [stack-name]

If no stack name is provided, "aws-cli-workshop" will be used.

EOF
}

case "$1" in
  -h|--help)
        usage
    exit 0
      ;;
esac


STACK_NAME="${1:-aws-cli-workshop}"

query() {
  jp -u "$2" <<<"$1"
}

resource_exists() {
  # Run a command with an added --query length(...)
  # and check if it results in at least a 1 element list.
  if [[ -z "$2" ]]
  then
    command="$1 --query length(*[0])"
  else
    command="$1 --query $2"
  fi
  num_matches=$($command)
  if [[ "$?" -ne 0 ]]
  then
    echo "Could not check if resource exists, exiting."
    exit 2
  fi
  if [[ "$num_matches" -gt 0 ]]
  then
    # RC of 0 mean the resource exists, "success"
    return 0
  else
    return 1
  fi
}

show_aws_iam_role() {
  role_name="$1"
  role=$(aws iam list-roles --query "Roles[?RoleName=='$1'] | [0]")
  echo
  echo "ARN: $(query "$role" Arn)"
  echo
  echo "Trust policy:"
  echo
  query "$role" AssumeRolePolicyDocument
  if resource_exists "aws iam list-role-policies --role-name $role_name"; then
    echo "You have role policies"
  elif resource_exists "aws iam list-attached-role-policies --role-name $role_name"; then
    # Managed policies
    echo
    echo "You have managed role policies attached"
    echo
    policy_arns=$(aws iam list-attached-role-policies \
      --role-name $role_name \
      --query "AttachedPolicies[].[PolicyArn]" \
      --output text)
    for policy_arn in $policy_arns; do
      active_version=$(aws iam list-policy-versions \
        --policy-arn "$policy_arn" \
        --query 'Versions[?IsDefaultVersion] | [0].VersionId' \
        --output text)
      echo "Managed policy: $policy_arn, version: $active_version"
      echo
      aws iam get-policy-version \
        --policy-arn "$policy_arn" \
        --version-id "$active_version"
    done
  fi

}

# Exercise for the reader, try and implement the remaining resource types.
#
#show_aws_codebuild_project() {
#  resource_id="$1"
#}
#
#show_aws_iam_role() {
#  resource_id="$1"
#}
#
#show_aws_ecr_repository() {
#  resource_id="$1"
#}
#
#show_aws_codecommit_repository() {
#  resource_id="$1"
#}
#
#show_aws_events_rule() {
#  resource_id="$1"
#}
#
#show_aws_iam_managedpolicy() {
#  resource_id="$1"
#}



all_resources=$(aws cloudformation describe-stack-resources --stack-name "$STACK_NAME" \
  --query StackResources[].[ResourceType,PhysicalResourceId] --output text)
while IFS= read -r line; do
  resource_type=$(cut -d' ' -f 1 <<< $line)
  physical_id=$(cut -d' ' -f 2 <<< $line)
  handler=$(tr '[:upper:]' '[:lower:]' <<< $resource_type)
  handler_name="show_$(sed s/::/_/g <<< $handler)"
  if [[ $(type -t ${handler_name}) == function ]]
  then
    echo -ne '\033[1m=== Details for '
    echo -n "$physical_id ($resource_type) ==="
    echo -e '\033[0m'
    ${handler_name} $physical_id
    echo
  fi
done <<< "$all_resources"
