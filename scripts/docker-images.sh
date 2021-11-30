#!/bin/bash

REPO_NAME="aws-cli/workshop"
PROG_NAME=$(basename "$0")

usage() {
  cat 1>&2 <<EOF
Manage the docker images for this repo on a local dev machine.
This script is intended to be run outside of a docker image on the
host machine.  This utility script will help pull and run images
from your Amazon ECR repo.

USAGE:
    $PROG_NAME [-h|--help] <unsynced | pull | list | shell>

UNSYNCED

Shows tags that exist in the remote ECR repo but have not been pulled locally.

LIST

List all workhop images available locally.

PULL

Pull remote images locally.  With no args specified it will pull all unsynced
tags, otherwise you can specify a single tag.
Examples:

    $PROG_NAME pull
    $PROG_NAME pull 0.0.5

SHELL

Start an interactive shell for the specified image tag.  You can the list
of available image tags from the "list" command.
Example:

    $PROG_NAME shell 1234.dkr.ecr.us-west-2.amazonaws.com/aws-cli/workshop:0.10.0

EOF
}

errexit() {
  echo "ERROR: $(basename "$0"): ${1:-"Unknown Error"}" 1>&2
  exit 1
}


cmd_pull(){
    requested_tag="$1"
    repo_uri=$(aws ecr describe-repositories --repository-names "$REPO_NAME" --query repositories[].repositoryUri --output text)
    if [ -z $requested_tag ]
    then
      echo Syncing all unsynced tags
      image_tags=$(cmd_unsynced)
    else
      echo Syncing tag ${requested_tag}
      image_tags=$requested_tag
    fi
    aws ecr get-login-password | docker login --username AWS --password-stdin "${repo_uri}"
    for image_tag in ${image_tags}
    do
      echo "Pulling image tag ${image_tag}"
      docker pull ${repo_uri}:${image_tag}
    done
}


cmd_list(){
    repo_uri=$(aws ecr describe-repositories --repository-names "$REPO_NAME" --query repositories[].repositoryUri --output text)
    docker image ls --format '{{.Repository}}:{{.Tag}}' | grep "${repo_uri}"
}


cmd_shell(){
  if [ -z "$1" ]
  then
    errexit "Must provide the image name (use \"$PROG_NAME list\")"
  fi
  image_name="$1"
  docker run --rm -it -v ~/.aws:/home/workshop-user/.aws ${image_name} /bin/bash
}

cmd_unsynced(){
    repo_uri=$(aws ecr describe-repositories --repository-names "$REPO_NAME" --query repositories[].repositoryUri --output text)
    image_tags=$(aws ecr describe-images --repository-name "$REPO_NAME" --query imageDetails[].imageTags --output text)
    local_images=$(docker image ls --format '{{.Repository}}:{{.Tag}}')
    for image_tag in ${image_tags}
    do
      remote_tag=${repo_uri}:${image_tag}
      if ! grep -q ${remote_tag} <<< ${local_images}
      then
	# Tag exists in ECR repo but not locally.
	echo ${image_tag}
      fi
    done
}


subcommand=$1
case $subcommand in
    "" | "-h" | "--help")
        usage
        exit 0
        ;;
    *)
        shift
        [[ $(type -t cmd_${subcommand}) == function ]] || errexit "Unknown command: ${subcommand}"
        cmd_${subcommand} $@
        ;;
esac
