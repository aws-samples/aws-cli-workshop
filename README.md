# aws-cli-workshop
This repository hosts the code needed to work through the
AWS CLI workshop.

## Repository layout

The repository consists of the following layout:

* `scripts/` - This directory contains any of the scripts that will
   be used in the workshop.
* `infra/` - This directory contains any of the core CloudFormation
   templates used in the workshop.
* `assets/` - This directory contains any additional files that to be
   included in the repository (e.g. AWS CLI wizard snippets and sample
   EventBridge patterns)
* `Dockerfile` - Allows us to build an image of this repository for easy
   access to its scripts and any additional tooling we may want.
* `buildspec.yml` - CodeBuild build specification to build the repository
   docker image and deploy it to an Amazon ECR repository.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

