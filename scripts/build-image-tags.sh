#!/bin/bash

usage() {
  cat 1>&2 <<EOF
Builds images for each tag in a git repository
USAGE:
    build-image-tags.sh [-m] [-r <git-repository-path>] [-h|--help] <repo-uri-name>

FLAGS:
    -h, --help                Prints help information

OPTIONS:
    -m, --only-missing-upstream               Only build the tags missing from the
                                              upstream ECR image repository.
    -r, --repository <git-repository-path>    The git repository to build tags from.
                                              By default, it will build images from
                                              git tags in the current working directory.
EOF
}

parse_commandline() {
  while test $# -gt 0
  do
    key="$1"
	case "$key" in
	  -h|--help)
	    usage
        exit 0
	  ;;
	  -m|--only-missing-upstream)
	    ONLY_MISSING_UPSTREAM="yes"
	   ;;
	  -r|--repository)
	    GIT_REPOSITORY="$2"
        shift
      ;;
	  *)
	    IMAGE_NAME="$1"
	    ECR_REPO_NAME=$(echo "$IMAGE_NAME" | cut -d'/' -f '2-')
	  ;;
    esac
	shift
  done
}

validate_clean_repository() {
  git diff-index --quiet HEAD || die "Git repository is not clean. Please commit any needed changes" 
}

build_tags() {
  if [ "$ONLY_MISSING_UPSTREAM" == "yes" ]
  then
    upstream_image_tags=$(aws ecr describe-images --repository-name "$ECR_REPO_NAME" --query imageDetails[].imageTags[])
  fi
  for tag in $(git tag -l)
  do
    if [ -z "$upstream_image_tags" ] || [ $(echo "$upstream_image_tags" | jq -c ". | index(\"$tag\")") == null ]
    then
      echo "Building image for tag: $tag"
      git checkout "$tag" &> /dev/null
      docker build . -t "$IMAGE_NAME:$tag"
    fi
  done 
}

main() {
  GIT_REPOSITORY="."
  parse_commandline "$@"
  pushd "$GIT_REPOSITORY" > /dev/null
  validate_clean_repository
  current_branch=$(git branch --show-current)
  build_tags
  popd > /dev/null
  git checkout "$current_branch" &> /dev/null
  exit 0
}

die() {
	err_msg="$1"
	echo "$err_msg" >&2
	exit 1
}

main "$@" || exit 1
