#!/bin/bash
# Given a role name, display information about the role.
# Usage: ./role-info MyAppRole
# read-only-access, does not perform any modifications to resources
if [ -z "$1" ]; then
  echo "Must provide a role name as an argument." 1>&2
  exit 1
fi

export AWS_PAGER="cat"
ROLE_NAME="$1"

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

display_role_attributes() {
  echo "Not implemented"
#  # Tip: Use the query pattern by saving resources as JSON and using "jp" to query them.
#  role_name="$1"
#  role=$(<FILL IN THE AWS CLI COMMAND>)
#  echo "ARN: $(<FILL IN THE AWS CLI COMMAND>)"
#  echo
#  echo "Trust policy:"
#  echo
#  <FILL IN THE QUERY FOR THE TRUST POLICY>
}

display_inline_role_policies() {
  echo "Not implemented"
#  # Tip: Use query and text output to create iterable lists of resources
#  role_name="$1"
#  policy_names=$(AWS CLI COMMAND TO GET A LIST OF POLICY NAMES>)
#  for policy_name in $policy_names; do
#    echo "$policy_name:"
#    aws iam get-role-policy --role-name "$role_name" <POLICY NAME PARAM>
#    echo
#  done
}

display_default_policy_version() {
  echo "Not implemented"
#  # Tip: Use command substitution to map one output to
#  # one input of another command.
#  role_name="$1"
#  policy_arn="$2"
#  active_version=$(FILL IN AWS CLI COMMAND>)
#  echo "Managed policy: $policy_arn, version: $active_version"
#  echo
#  aws iam get-policy-version \
#    <FILL IN THE REMAINING PARAMETERS>
}

display_managed_policies() {
  role_name="$1"
  policy_arns=$(aws iam list-attached-role-policies \
    --role-name "$role_name" \
    --query "AttachedPolicies[].[PolicyArn]" \
    --output text)
  for policy_arn in $policy_arns; do
    display_default_policy_version "$role_name" "$policy_arn"
  done
}

role_policies() {
  role_name="$1"
  echo "Role: $role_name"
  display_role_attributes "$role_name"
  if resource_exists "aws iam list-role-policies --role-name $role_name"; then
    echo
    echo "You have inline role policies:"
    echo
    display_inline_role_policies "$role_name"
  fi
  if resource_exists "aws iam list-attached-role-policies --role-name $role_name"; then
    echo
    echo "You have managed role policies attached:"
    echo
    display_managed_policies "$role_name"
  fi
}

role_policies "$ROLE_NAME"
