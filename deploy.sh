#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Set variables for the template file and stack name
TEMPLATE_FILE="Cloudformation.yaml"  # Change this to the path of your CloudFormation template file
STACK_NAME="glenn"  # Change this to your stack name

# Deploy the CloudFormation stack using the variables from .env
aws cloudformation deploy \
  --template-file "$TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    FromEmail="$FROM_EMAIL" \
    ToEmail="$TO_EMAIL"
