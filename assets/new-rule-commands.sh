aws events put-rule \
  --name 'LogEvents-codecommit' \
  --description 'Logs EventBridge events to CloudWatch Logs' \
  --event-pattern '{"source": ["aws.codecommit"]}' \
  --query RuleArn --output text


aws logs put-resource-policy \
  --policy-name 'WriteEventLogs' \
  --policy-document '{"Version":"2012-10-17", "Statement":[{"Sid":"TrustEventsToStoreLogEvent","Effect":"Allow","Principal":{"Service":["delivery.logs.amazonaws.com","events.amazonaws.com"]},"Action":["logs:CreateLogStream","logs:PutLogEvents"],"Resource":"arn:aws:logs:us-west-2:123456789012:log-group:/aws/events/catchall/codecommit:*:*"}]}'

aws events put-targets \
  --rule 'LogEvents-codecommit' \
  --targets 'Id=cli-wizard-0,Arn=arn:aws:logs:us-west-2:123456789012:log-group:/aws/events/catchall/codecommit:*'

