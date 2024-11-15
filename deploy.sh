#!/bin/bash

# Load environment variables from .env file
set -a
source .env
set +a

# Validate that required environment variables are set
if [[ -z "$GITHUB_REPO_OWNER" || -z "$GITHUB_REPO_NAME" || -z "$GITHUB_BRANCH" || -z "$GITHUB_TOKEN" ]]; then
  echo "Error: Missing required environment variables in .env file."
  exit 1
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
    ToEmail="$TO_EMAIL" \
    GitHubRepoOwner=$GITHUB_REPO_OWNER \
    GitHubRepoName=$GITHUB_REPO_NAME \
    GitHubBranch=$GITHUB_BRANCH \
    GitHubToken=$GITHUB_TOKEN \

# Check if deployment was successful
if [ $? -eq 0 ]; then
  echo "CloudFormation stack deployed successfully!"
else
  echo "Error: CloudFormation stack deployment failed."
  exit 1
fi