#!/bin/bash

usage() {
  cat 1>&2 <<EOF
Runs and displays progress of a CodeBuild project build
USAGE:
    run-build.sh [-h|--help] <project-name> [FLAGS] [OPTIONS]

This script accepts all valid parameters for aws codebuild start-build command.
If --debug-session-enabled is set, it will automatically open a session to
the in-progress build.
EOF
}


parse_commandline() {
  case "$1" in
    -h|--help)
	  usage
      exit 0
	;;
  esac
  if [ -z "$1" ]; then
    echo "Must provide the <project-name> argument." 1>&2
    exit 1
  fi
  PROJECT_NAME="$1"
  EXTRA_START_ARGS="${*:2}"
}


start_codebuild() {
  build_id=$(aws codebuild start-build --project-name "$PROJECT_NAME" $EXTRA_START_ARGS --query build.id --output text)
  echo "Started build: $build_id"
}

wait_for_build_phase() {
  expected_status="$1"
  until [ $(aws codebuild batch-get-builds --ids "$build_id" --query builds[].currentPhase --output text) == "$expected_status" ]
  do
    sleep 1
  done
}

tail_build() {
  build_logs=$(aws codebuild batch-get-builds --ids "$build_id" --query 'builds[].logs.[groupName,streamName]' --output text)
  log_name=$(echo "$build_logs" | cut -f 1)
  stream_name=$(echo "$build_logs" | cut -f 2)
  aws logs tail "$log_name" --log-stream-names "$stream_name" --follow --format short
}

connect_ssm() {
  session_target=$(aws codebuild batch-get-builds --ids $build_id --query 'builds[].debugSession[].sessionTarget' --output text)
  until [[ ! -z "$session_target" ]]
  do
    sleep 1
    session_target=$(aws codebuild batch-get-builds --ids $build_id --query 'builds[].debugSession[].sessionTarget' --output text)
  done
  sleep 15  # Wait for logs to get propagated before starting session
  aws ssm start-session --target "$session_target"
}

main() {
  parse_commandline "$@"
  start_codebuild
  wait_for_build_phase PROVISIONING
  tail_build &
  if [[ "$*" == *--debug-session-enabled* ]]
  then
    connect_ssm
  fi
  wait_for_build_phase COMPLETED
  sleep 15  # Wait for logs to get propagated
  kill "$!"
  exit 0
}

main "$@" || exit 1
