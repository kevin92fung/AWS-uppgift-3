#!/bin/bash

# Set variables for the template file and stack name
TEMPLATE_FILE="CloudFormation.yaml"  # Change this to the path of your CloudFormation template file
STACK_NAME="test"  # Change this to your stack name

# Deploy the CloudFormation stack using the variables
aws cloudformation deploy \
  --template-file "$TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --capabilities CAPABILITY_NAMED_IAM
