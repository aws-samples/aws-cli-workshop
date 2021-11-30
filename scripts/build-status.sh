#!/bin/bash

usage() {
  cat 1>&2 <<EOF
Monitor the status of the latest codebuild job.

We recommend running this script with the watch command:

  watch ./scripts/build-status.sh

EOF
}

case "$1" in
  -h|--help)
        usage
    exit 0
      ;;
esac
if [ -z "$1" ]; then
  PROJECT_NAME="aws-cli-workshop"
else
  PROJECT_NAME="$1"
fi

latest_build_id=$(aws codebuild list-builds-for-project --project-name \
  "$PROJECT_NAME" --query ids[0] --output text)
status=$(aws codebuild batch-get-builds \
  --ids "$latest_build_id" --query builds[0])
phases=$(aws codebuild batch-get-builds \
  --ids "$latest_build_id" --query builds[0].phases[].[phaseType,phaseStatus] \
  --output text)
current_phase=$(jp -u currentPhase <<< $status)
build_status=$(jp -u buildStatus <<< $status)
build_number=$(jp -u buildNumber <<< $status)

echo $PROJECT_NAME $build_status
echo "  - Build:  ${build_number}"
echo "  - Status: ${current_phase}"
echo "  - Phases:"
while IFS= read -r line; do
  phase_type=$(cut -d' ' -f 1 <<< $line)
  phase_status=$(cut -d' ' -f 2 <<< $line)
  if [[ "$phase_status" == "None" ]]
  then
    echo "     - ${phase_type}"
  else
    printf '     - %-20s %-20s\n' $phase_type $phase_status
  fi
done <<< "$phases"
