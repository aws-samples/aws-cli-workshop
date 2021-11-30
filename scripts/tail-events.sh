#!/bin/bash
set -e

usage() {
  cat 1>&2 <<EOF
Tail a CloudWatch Logs group for EventBridge events
USAGE:
    tail-events.sh <LOG_GROUP_NAME> [--create] [--service <SERVICE>|--event-pattern <EVENT_PATTERN>] [--no-cleanup] [-h|--help]
FLAGS:
    --create                  Create a new EventBridge rule that targets
                              the specified CloudWatch Logs group
    --service                 If --create is specified, the rule created will use an
                              event pattern that catches all events for the specified
                              service
    --event-pattern           If --create is specified, the rule created will use
                              the event pattern specified. You can specify an event pattern
                              from a file by prefixing its path with file://
                              (e.g. file://path/to/event_pattern.json)
    --no-cleanup              Do not delete the created EventBridge rule after tailing logs. By
                              default, if a rule is created in this script, it will be deleted after
                              the tailing ends.
    -h, --help                Prints help information
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
    --create)
	    CREATE="yes"
	  ;;
    --no-cleanup)
	    CLEANUP="no"
	  ;;
		-s|--service)
	    SERVICE="$2"
		  shift
	  ;;
	  -e|--event-pattern)
	    EVENT_PATTERN="$2"
		  shift
	  ;;
	  *)
	    GROUP_NAME="$1"
	  ;;
  esac
	shift
  done
}

set_global_vars() {
  set_logs_group_arn
  set_event_rule_name
  set_create
  set_cleanup
}

set_logs_group_arn() {
  GROUP_ARN=$(aws logs describe-log-groups --log-group-name-prefix "$GROUP_NAME" --query "logGroups[].arn" --output text)
}

set_event_rule_name() {
  if [ -n "${SERVICE}" ]; then
    EVENT_RULE_NAME="LogEvents-$SERVICE"
  else
    EVENT_RULE_NAME="LogEvents"
  fi
}

set_event_pattern() {
  if [ -z "${EVENT_PATTERN}" ]; then
    set_catchall_event_pattern
  fi
}

set_catchall_event_pattern() {
  EVENT_PATTERN="{\"source\":[\"aws.$SERVICE\"]}"
}

set_create() {
  CREATE=${CREATE:-no}
}

set_cleanup() {
  if [ "$CREATE" = "yes" ]; then
    CLEANUP=${CLEANUP:-yes}
  else
    CLEANUP="no"
  fi
}

tail_logs() {
  echo "Tailing CloudWatch Logs group: $GROUP_NAME"
  aws logs tail "$GROUP_NAME" --follow --format json --since 1s
}

create() {
  set_event_pattern
  set_logs_group_arn
  echo "Creating EventBridge rule: $EVENT_RULE_NAME with event pattern: $EVENT_PATTERN"
  create_log_events_rule > /dev/null
}

create_log_events_rule() {
  aws events put-rule \
    --name "$EVENT_RULE_NAME" \
    --description 'Logs EventBridge events to CloudWatch Logs' \
    --event-pattern "$EVENT_PATTERN" \
    --query RuleArn --output text

  aws logs put-resource-policy \
    --policy-name 'WriteEventLogs' \
    --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"TrustEventsToStoreLogEvent\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":[\"delivery.logs.amazonaws.com\",\"events.amazonaws.com\"]},\"Action\":[\"logs:CreateLogStream\",\"logs:PutLogEvents\"],\"Resource\":\"$GROUP_ARN:*\"}]}"

  aws events put-targets \
    --rule "$EVENT_RULE_NAME" \
    --targets "Id=cli-wizard-0,Arn=$GROUP_ARN"
}

cleanup() {
  echo "Deleting EventBridge rule: $EVENT_RULE_NAME"
  delete_event_rule_and_permissions > /dev/null
}

delete_event_rule_and_permissions() {
  target_ids=$(aws events list-targets-by-rule --rule "$EVENT_RULE_NAME" --query Targets[].Id)
  aws events remove-targets --rule "$EVENT_RULE_NAME" --ids="$target_ids"
  aws events delete-rule --name "$EVENT_RULE_NAME"
  aws logs delete-resource-policy --policy-name "WriteEventLogs"
}

main() {
  parse_commandline "$@"
  set_global_vars

  if [ "$CREATE" = "yes" ]
  then
    create
  fi

  tail_logs

  if [ "$CLEANUP" = "yes" ]
  then
    cleanup
  fi

  exit 0
}

main "$@"
