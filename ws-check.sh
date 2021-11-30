#!/bin/bash

usage() {
  cat 1>&2 <<EOF
Check your progress in the AWS CLI workshop against the final versions.

USAGE:
    ./ws-check.sh [-d | --diff] [-p | --print] [-c | --copy] FILENAME

The --diff option will diff a file in your workspace against the final version.

    ./ws-check.sh --diff ./scripts/tail-events.sh

The --print option will print the final version of a final.

    ./ws-check.sh --print ./scripts/tail-events.sh

The --copy option will copy the final version of a file into your current workspace.

    ./ws-check.sh --copy ./scripts/tail-events.sh

EOF
}

if [ -z "$1" ]
then
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -h|--help)
      usage
      exit 0
      ;;
    -d|--diff)
      FILENAME="$2"
      git diff -R refs/remotes/origin/final -- "${FILENAME}"
      shift
      shift
      ;;
    -p|--print)
      FILENAME="$2"
      git show "refs/remotes/origin/final:${FILENAME}"
      shift
      shift
      ;;
    -c|--copy)
      FILENAME="$2"
      git show "refs/remotes/origin/final:${FILENAME}" > "${FILENAME}"
      shift
      shift
      ;;
    *)
      echo "Unknown option $1" 1>&2
      echo
      shift
      usage
      exit 1
      ;;
  esac
done
