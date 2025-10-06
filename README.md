# Yeojeong

A skeleton CI/CD pipeline project using GitHub Actions and AWS CodeBuild for deploying AWS services including Lambda, API Gateway, ECS, and S3.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Project Structure](#project-structure)
- [Deployment](#deployment)
- [GitHub Actions Workflows](#github-actions-workflows)
- [AWS CodeBuild Projects](#aws-codebuild-projects)
- [Environment Configuration](#environment-configuration)

## Overview

This project provides a complete skeleton pipeline for deploying AWS infrastructure and services using:

- **GitHub Actions**: For CI/CD orchestration and triggering deployments
- **AWS CodeBuild**: For building and deploying AWS resources
- **AWS Lambda**: Serverless functions
- **API Gateway**: RESTful API endpoints
- **ECS (Elastic Container Service)**: Containerized applications
- **S3**: Static assets and data storage

## Architecture

```
GitHub Repository
    │
    ├── GitHub Actions (CI/CD Orchestration)
    │   ├── CI Workflow (Build & Test)
    │   ├── Lambda Deployment
    │   ├── ECS Deployment
    │   └── Infrastructure Deployment
    │
    └── AWS CodeBuild (Build & Deploy)
        ├── Lambda BuildSpec
        ├── ECS BuildSpec
        └── Infrastructure BuildSpec
```

## Prerequisites

### AWS Resources

1. **AWS Account** with appropriate permissions
2. **IAM Roles**:
   - `ecsTaskExecutionRole` - For ECS task execution
   - `ecsTaskRole` - For ECS task permissions
3. **CodeBuild Projects** (see setup instructions below):
   - `yeojeong-lambda-deploy`
   - `yeojeong-ecs-deploy`
   - `yeojeong-infrastructure-deploy`
4. **ECR Repository**: `yeojeong-app`
5. **ECS Cluster**: `yeojeong-{environment}-cluster`

### GitHub Secrets

Configure the following secrets in your GitHub repository:

- `AWS_ACCESS_KEY_ID` - AWS access key for deployments
- `AWS_SECRET_ACCESS_KEY` - AWS secret key for deployments

### Local Development Tools

- Node.js 18+ (for Lambda and ECS services)
- Docker (for ECS container builds)
- AWS CLI v2
- AWS SAM CLI (for infrastructure deployments)

## Setup

### 1. AWS CodeBuild Projects Setup

Create three CodeBuild projects in your AWS account:

#### Lambda Deployment Project

```bash
aws codebuild create-project \
  --name yeojeong-lambda-deploy \
  --source type=GITHUB,location=https://github.com/gl1290/Yeojeong.git \
  --artifacts type=NO_ARTIFACTS \
  --environment type=LINUX_CONTAINER,image=aws/codebuild/standard:7.0,computeType=BUILD_GENERAL1_SMALL \
  --service-role arn:aws:iam::{ACCOUNT_ID}:role/CodeBuildServiceRole \
  --buildspec buildspecs/lambda-buildspec.yml
```

#### ECS Deployment Project

```bash
aws codebuild create-project \
  --name yeojeong-ecs-deploy \
  --source type=GITHUB,location=https://github.com/gl1290/Yeojeong.git \
  --artifacts type=NO_ARTIFACTS \
  --environment type=LINUX_CONTAINER,image=aws/codebuild/standard:7.0,computeType=BUILD_GENERAL1_SMALL,privilegedMode=true \
  --service-role arn:aws:iam::{ACCOUNT_ID}:role/CodeBuildServiceRole \
  --buildspec buildspecs/ecs-buildspec.yml
```

#### Infrastructure Deployment Project

```bash
aws codebuild create-project \
  --name yeojeong-infrastructure-deploy \
  --source type=GITHUB,location=https://github.com/gl1290/Yeojeong.git \
  --artifacts type=NO_ARTIFACTS \
  --environment type=LINUX_CONTAINER,image=aws/codebuild/standard:7.0,computeType=BUILD_GENERAL1_SMALL \
  --service-role arn:aws:iam::{ACCOUNT_ID}:role/CodeBuildServiceRole \
  --buildspec buildspecs/infrastructure-buildspec.yml
```

### 2. Create ECR Repository

```bash
aws ecr create-repository --repository-name yeojeong-app --region us-east-1
```

### 3. Deploy Initial Infrastructure

```bash
# Deploy S3 buckets
sam deploy \
  --template-file infrastructure/s3/template.yaml \
  --stack-name yeojeong-dev-s3 \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides Environment=dev ProjectName=yeojeong

# Deploy API Gateway and Lambda
sam deploy \
  --template-file infrastructure/api-gateway/template.yaml \
  --stack-name yeojeong-dev-api-gateway \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --parameter-overrides Environment=dev ProjectName=yeojeong
```

### 4. Configure GitHub Environments

Create three environments in your GitHub repository:
- `dev`
- `staging`
- `prod`

Add the AWS secrets to each environment.

## Project Structure

```
.
├── .github/
│   └── workflows/                 # GitHub Actions workflows
│       ├── ci.yml                # CI workflow (build & test)
│       ├── deploy-lambda.yml     # Lambda deployment
│       ├── deploy-ecs.yml        # ECS deployment
│       └── deploy-infrastructure.yml  # Infrastructure deployment
│
├── buildspecs/                   # AWS CodeBuild buildspec files
│   ├── lambda-buildspec.yml     # Lambda build configuration
│   ├── ecs-buildspec.yml        # ECS build configuration
│   └── infrastructure-buildspec.yml  # Infrastructure build config
│
├── lambda/                       # Lambda functions
│   └── hello-world/             # Sample Lambda function
│       ├── index.js             # Function handler
│       └── package.json         # Dependencies
│
├── ecs/                          # ECS services
│   ├── api/                     # API service
│   │   ├── Dockerfile           # Container definition
│   │   ├── server.js            # Application code
│   │   └── package.json         # Dependencies
│   ├── worker/                  # Worker service
│   │   ├── Dockerfile           # Container definition
│   │   ├── worker.js            # Worker code
│   │   └── package.json         # Dependencies
│   └── task-definitions/        # ECS task definitions
│       ├── api-task.json        # API task definition
│       └── worker-task.json     # Worker task definition
│
└── infrastructure/               # CloudFormation/SAM templates
    ├── api-gateway/             # API Gateway stack
    │   └── template.yaml        # SAM template
    └── s3/                      # S3 buckets stack
        └── template.yaml        # CloudFormation template
```

## Deployment

### Automatic Deployments

Deployments are automatically triggered on push to `main` branch:

- **Lambda Functions**: Triggered when changes are made to `lambda/**`
- **ECS Services**: Triggered when changes are made to `ecs/**`
- **Infrastructure**: Triggered when changes are made to `infrastructure/**`

### Manual Deployments

You can manually trigger deployments via GitHub Actions:

1. Go to the **Actions** tab in GitHub
2. Select the desired workflow:
   - Deploy Lambda Functions
   - Deploy ECS Services
   - Deploy Infrastructure
3. Click **Run workflow**
4. Select the environment (dev/staging/prod)
5. Click **Run workflow**

### Deployment Process

1. **GitHub Action triggers** when code is pushed or manually invoked
2. **AWS credentials are configured** from GitHub secrets
3. **CodeBuild project is started** with environment variables
4. **CodeBuild executes** the buildspec file
5. **Resources are deployed** to AWS
6. **GitHub Action monitors** the CodeBuild status
7. **Deployment results** are reported back to GitHub

## GitHub Actions Workflows

### CI Workflow (`ci.yml`)

- **Trigger**: Push or PR to `main` or `develop` branches
- **Actions**:
  - Checkout code
  - Set up Node.js
  - Install dependencies
  - Run linter
  - Run tests
  - Build application
  - Upload artifacts

### Lambda Deployment (`deploy-lambda.yml`)

- **Trigger**: Push to `main` (lambda path) or manual dispatch
- **Actions**:
  - Trigger CodeBuild lambda deployment
  - Monitor build progress
  - Report deployment status

### ECS Deployment (`deploy-ecs.yml`)

- **Trigger**: Push to `main` (ecs path) or manual dispatch
- **Actions**:
  - Login to Amazon ECR
  - Trigger CodeBuild ECS deployment
  - Build and push Docker images
  - Update ECS services

### Infrastructure Deployment (`deploy-infrastructure.yml`)

- **Trigger**: Push to `main` (infrastructure path) or manual dispatch
- **Actions**:
  - Trigger CodeBuild infrastructure deployment
  - Deploy CloudFormation/SAM templates
  - Output stack information

## AWS CodeBuild Projects

### Lambda BuildSpec (`lambda-buildspec.yml`)

1. **Pre-build**: Install dependencies
2. **Build**: Package Lambda functions as ZIP files
3. **Post-build**: Deploy to AWS Lambda
4. **Cache**: Node modules for faster builds

### ECS BuildSpec (`ecs-buildspec.yml`)

1. **Pre-build**: Login to ECR
2. **Build**: Build Docker images
3. **Post-build**: 
   - Push images to ECR
   - Update ECS task definitions
   - Update ECS services

### Infrastructure BuildSpec (`infrastructure-buildspec.yml`)

1. **Pre-build**: Install AWS SAM CLI
2. **Build**: Deploy SAM/CloudFormation templates
3. **Post-build**: Output stack information

## Environment Configuration

### Environment Variables

Each environment (dev/staging/prod) can have different configurations:

- **Lambda**: Set in `infrastructure/api-gateway/template.yaml`
- **ECS**: Set in `ecs/task-definitions/*.json`
- **CodeBuild**: Passed via GitHub Actions workflow

### AWS Regions

Default region is `us-east-1`. To change:

1. Update `AWS_REGION` in `.github/workflows/*.yml`
2. Update region in buildspec files
3. Update region in CloudFormation templates

## Contributing

1. Create a feature branch
2. Make your changes
3. Test locally
4. Submit a pull request
5. Automated CI will run tests
6. After merge to `main`, changes deploy automatically

## Troubleshooting

### CodeBuild Failures

Check CloudWatch Logs for the CodeBuild project:
```bash
aws logs tail /aws/codebuild/yeojeong-lambda-deploy --follow
```

### ECS Deployment Issues

Check ECS service events:
```bash
aws ecs describe-services \
  --cluster yeojeong-dev-cluster \
  --services yeojeong-dev-api-service
```

### Lambda Errors

Check Lambda logs:
```bash
aws logs tail /aws/lambda/yeojeong-dev-hello-world --follow
```

## License

This project is provided as a skeleton template for AWS deployment pipelines.