# Quick Start Guide

This guide will help you get started with the Yeojeong CI/CD pipeline in 15 minutes.

## Prerequisites

- AWS Account
- GitHub Account
- AWS CLI installed and configured
- Node.js 18+ installed (for local development)
- Docker installed (for ECS local testing)

## Step 1: Fork/Clone the Repository

```bash
git clone https://github.com/gl1290/Yeojeong.git
cd Yeojeong
```

## Step 2: Set Up AWS Infrastructure

Run the automated setup script:

```bash
chmod +x scripts/setup-aws.sh
./scripts/setup-aws.sh
```

This script will create:
- ECR repository for Docker images
- IAM role for CodeBuild
- Three CodeBuild projects (Lambda, ECS, Infrastructure)

**Or** manually create resources following the instructions in [README.md](README.md#setup).

## Step 3: Configure GitHub

### Add Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Add the following secrets:
   - `AWS_ACCESS_KEY_ID` - Your AWS access key
   - `AWS_SECRET_ACCESS_KEY` - Your AWS secret key

### Create Environments

1. Go to **Settings** → **Environments**
2. Create three environments:
   - `dev`
   - `staging`
   - `prod`

## Step 4: Deploy Initial Infrastructure

Deploy the S3 and API Gateway stacks:

```bash
# Deploy S3 buckets
cd infrastructure
sam deploy \
  --template-file s3/template.yaml \
  --stack-name yeojeong-dev-s3 \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides Environment=dev ProjectName=yeojeong \
  --region us-east-1

# Deploy API Gateway and Lambda
sam deploy \
  --template-file api-gateway/template.yaml \
  --stack-name yeojeong-dev-api-gateway \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --parameter-overrides Environment=dev ProjectName=yeojeong \
  --region us-east-1
```

## Step 5: Test the Pipeline

### Test Lambda Deployment

1. Make a small change to `lambda/hello-world/index.js`
2. Commit and push:
   ```bash
   git add lambda/
   git commit -m "Test Lambda deployment"
   git push
   ```
3. Go to **GitHub Actions** and watch the deployment
4. Test the deployed function:
   ```bash
   # Get API URL from stack outputs
   API_URL=$(aws cloudformation describe-stacks \
     --stack-name yeojeong-dev-api-gateway \
     --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' \
     --output text)
   
   # Test the endpoint
   curl $API_URL/hello
   ```

### Test Manual Deployment

1. Go to **GitHub Actions**
2. Select "Deploy Lambda Functions"
3. Click **Run workflow**
4. Select environment: `dev`
5. Click **Run workflow**

## Step 6: (Optional) Set Up ECS

To use the ECS services:

1. Create an ECS cluster:
   ```bash
   aws ecs create-cluster --cluster-name yeojeong-dev-cluster
   ```

2. Create task definitions using the templates in `ecs/task-definitions/`
   (replace placeholders with your account ID and ECR URI)

3. Create ECS services for API and Worker

4. Push changes to trigger deployment:
   ```bash
   git add ecs/
   git commit -m "Test ECS deployment"
   git push
   ```

## Verify Everything Works

### Check Lambda

```bash
# Get API URL
API_URL=$(aws cloudformation describe-stacks \
  --stack-name yeojeong-dev-api-gateway \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' \
  --output text)

# Test endpoint
curl $API_URL/hello
```

Expected response:
```json
{
  "message": "Hello from Yeojeong Lambda!",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "requestId": "...",
  "environment": "dev"
}
```

### Check S3 Buckets

```bash
# List S3 buckets
aws s3 ls | grep yeojeong-dev
```

You should see three buckets:
- `yeojeong-dev-app-data-{ACCOUNT_ID}`
- `yeojeong-dev-static-{ACCOUNT_ID}`
- `yeojeong-dev-logs-{ACCOUNT_ID}`

### Check CodeBuild Projects

```bash
# List CodeBuild projects
aws codebuild list-projects | grep yeojeong
```

You should see:
- `yeojeong-lambda-deploy`
- `yeojeong-ecs-deploy`
- `yeojeong-infrastructure-deploy`

## Next Steps

1. **Customize Lambda Functions**: Add your own functions in the `lambda/` directory
2. **Customize ECS Services**: Modify the API and Worker services in `ecs/`
3. **Add Infrastructure**: Create new CloudFormation/SAM templates in `infrastructure/`
4. **Configure Environments**: Set up staging and prod environments
5. **Add Tests**: Add unit and integration tests to the services
6. **Monitor**: Set up CloudWatch alarms and dashboards

## Troubleshooting

### CodeBuild Fails

Check the logs:
```bash
aws logs tail /aws/codebuild/yeojeong-lambda-deploy --follow
```

### Lambda Errors

Check Lambda logs:
```bash
aws logs tail /aws/lambda/yeojeong-dev-hello-world --follow
```

### Permission Errors

Make sure your IAM user/role has permissions:
- CodeBuild access
- Lambda access
- ECS access
- ECR access
- CloudFormation access
- S3 access

### GitHub Actions Fails

Check:
1. AWS credentials are correctly set in GitHub secrets
2. GitHub environments are created
3. CodeBuild projects exist in AWS

## Getting Help

- Check the main [README.md](README.md) for detailed documentation
- Review AWS CloudWatch logs for errors
- Check GitHub Actions logs for deployment issues

## Clean Up

To delete all resources:

```bash
# Delete Lambda functions and API Gateway
aws cloudformation delete-stack --stack-name yeojeong-dev-api-gateway

# Empty and delete S3 buckets
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 rm s3://yeojeong-dev-app-data-${AWS_ACCOUNT_ID} --recursive
aws s3 rm s3://yeojeong-dev-static-${AWS_ACCOUNT_ID} --recursive
aws s3 rm s3://yeojeong-dev-logs-${AWS_ACCOUNT_ID} --recursive
aws cloudformation delete-stack --stack-name yeojeong-dev-s3

# Delete CodeBuild projects
aws codebuild delete-project --name yeojeong-lambda-deploy
aws codebuild delete-project --name yeojeong-ecs-deploy
aws codebuild delete-project --name yeojeong-infrastructure-deploy

# Delete ECR repository
aws ecr delete-repository --repository-name yeojeong-app --force

# Delete IAM role
aws iam detach-role-policy --role-name YeojeongCodeBuildServiceRole --policy-arn arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess
aws iam detach-role-policy --role-name YeojeongCodeBuildServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess
aws iam detach-role-policy --role-name YeojeongCodeBuildServiceRole --policy-arn arn:aws:iam::aws:policy/AWSLambda_FullAccess
aws iam detach-role-policy --role-name YeojeongCodeBuildServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess
aws iam detach-role-policy --role-name YeojeongCodeBuildServiceRole --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
aws iam detach-role-policy --role-name YeojeongCodeBuildServiceRole --policy-arn arn:aws:iam::aws:policy/AWSCloudFormationFullAccess
aws iam delete-role --role-name YeojeongCodeBuildServiceRole
```
