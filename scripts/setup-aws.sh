#!/bin/bash

# Yeojeong AWS Setup Script
# This script helps set up the AWS infrastructure needed for the pipeline

set -e

echo "================================================"
echo "Yeojeong AWS Infrastructure Setup"
echo "================================================"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    echo "Visit: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if user is logged in to AWS
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: Not authenticated with AWS. Please run 'aws configure' first."
    exit 1
fi

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-east-1}

echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"
echo ""

# Prompt for confirmation
read -p "Do you want to proceed with setup? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo "Step 1: Creating ECR Repository..."
if aws ecr describe-repositories --repository-names yeojeong-app --region $AWS_REGION &> /dev/null; then
    echo "✓ ECR repository 'yeojeong-app' already exists"
else
    aws ecr create-repository \
        --repository-name yeojeong-app \
        --region $AWS_REGION \
        --image-scanning-configuration scanOnPush=true
    echo "✓ ECR repository 'yeojeong-app' created"
fi

echo ""
echo "Step 2: Creating CodeBuild Service Role..."
ROLE_NAME="YeojeongCodeBuildServiceRole"

if aws iam get-role --role-name $ROLE_NAME &> /dev/null; then
    echo "✓ IAM role '$ROLE_NAME' already exists"
else
    # Create trust policy
    cat > /tmp/trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    # Create role
    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file:///tmp/trust-policy.json \
        --description "Service role for Yeojeong CodeBuild projects"

    # Attach policies
    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess

    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/AWSLambda_FullAccess

    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess

    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/AWSCloudFormationFullAccess

    echo "✓ IAM role '$ROLE_NAME' created with necessary permissions"
    
    # Wait for role to be available
    sleep 10
fi

ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"

echo ""
echo "Step 3: Creating CodeBuild Projects..."

# Lambda CodeBuild Project
PROJECT_NAME="yeojeong-lambda-deploy"
if aws codebuild batch-get-projects --names $PROJECT_NAME --region $AWS_REGION &> /dev/null; then
    echo "✓ CodeBuild project '$PROJECT_NAME' already exists"
else
    aws codebuild create-project \
        --name $PROJECT_NAME \
        --source type=GITHUB,location=https://github.com/gl1290/Yeojeong.git \
        --artifacts type=NO_ARTIFACTS \
        --environment type=LINUX_CONTAINER,image=aws/codebuild/standard:7.0,computeType=BUILD_GENERAL1_SMALL,privilegedMode=false \
        --service-role $ROLE_ARN \
        --region $AWS_REGION \
        --buildspec buildspecs/lambda-buildspec.yml
    echo "✓ CodeBuild project '$PROJECT_NAME' created"
fi

# ECS CodeBuild Project
PROJECT_NAME="yeojeong-ecs-deploy"
if aws codebuild batch-get-projects --names $PROJECT_NAME --region $AWS_REGION &> /dev/null; then
    echo "✓ CodeBuild project '$PROJECT_NAME' already exists"
else
    aws codebuild create-project \
        --name $PROJECT_NAME \
        --source type=GITHUB,location=https://github.com/gl1290/Yeojeong.git \
        --artifacts type=NO_ARTIFACTS \
        --environment type=LINUX_CONTAINER,image=aws/codebuild/standard:7.0,computeType=BUILD_GENERAL1_SMALL,privilegedMode=true \
        --service-role $ROLE_ARN \
        --region $AWS_REGION \
        --buildspec buildspecs/ecs-buildspec.yml
    echo "✓ CodeBuild project '$PROJECT_NAME' created"
fi

# Infrastructure CodeBuild Project
PROJECT_NAME="yeojeong-infrastructure-deploy"
if aws codebuild batch-get-projects --names $PROJECT_NAME --region $AWS_REGION &> /dev/null; then
    echo "✓ CodeBuild project '$PROJECT_NAME' already exists"
else
    aws codebuild create-project \
        --name $PROJECT_NAME \
        --source type=GITHUB,location=https://github.com/gl1290/Yeojeong.git \
        --artifacts type=NO_ARTIFACTS \
        --environment type=LINUX_CONTAINER,image=aws/codebuild/standard:7.0,computeType=BUILD_GENERAL1_SMALL,privilegedMode=false \
        --service-role $ROLE_ARN \
        --region $AWS_REGION \
        --buildspec buildspecs/infrastructure-buildspec.yml
    echo "✓ CodeBuild project '$PROJECT_NAME' created"
fi

echo ""
echo "================================================"
echo "Setup Complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Add GitHub secrets to your repository:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo ""
echo "2. Create GitHub environments:"
echo "   - dev"
echo "   - staging"
echo "   - prod"
echo ""
echo "3. Deploy initial infrastructure:"
echo "   cd infrastructure"
echo "   sam deploy --template-file s3/template.yaml --stack-name yeojeong-dev-s3 --capabilities CAPABILITY_IAM --parameter-overrides Environment=dev"
echo "   sam deploy --template-file api-gateway/template.yaml --stack-name yeojeong-dev-api-gateway --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM --parameter-overrides Environment=dev"
echo ""
echo "4. Push code to trigger automated deployments!"
echo ""
