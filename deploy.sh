#!/bin/bash

# Load environment variables from the .env file
source .env

# Set variables for the template file and stack name
TEMPLATE_FILE="cf.yaml"  # Change this to the path of your CloudFormation template file
STACK_NAME="glenn"  # Change this to your stack name

# Deploy the CloudFormation stack using the loaded environment variables
aws cloudformation deploy \
  --template-file "$TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    FromEmail="$FROM_EMAIL" \
    ToEmail="$TO_EMAIL" \
    GitHubRepositoryId="$GITHUB_REPOSITORY_ID"