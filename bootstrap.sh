#!/bin/bash
PROFILE_NAME=default
if [ ! -z "$AWS_PROFILE" ]
then
  PROFILE_NAME=$AWS_PROFILE
fi
copilot app init cli-workshop-app
# As far as I can tell `--default-config` is a lie, it won't
# touch the environment manifest file if it already exists,
# we just need to specify it so it doesn't prompt us.
copilot env init --name dev --profile ${PROFILE_NAME} --default-config
#copilot env init --name prod --profile ${PROFILE_NAME} --default-config
copilot env deploy --name dev
#copilot env deploy --name prod
copilot svc init --name cli-workshop-svc
copilot svc deploy --name cli-workshop-svc --env dev
copilot svc show --name cli-workshop-svc --json | jp -u routes[0].url > dev-endpoint-url
