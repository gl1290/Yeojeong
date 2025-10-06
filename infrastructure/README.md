# Infrastructure as Code

This directory contains CloudFormation and SAM templates for deploying AWS infrastructure.

## Stacks

### API Gateway Stack (`api-gateway/`)

Deploys:
- API Gateway REST API
- Lambda function integration
- CloudWatch Log Groups
- CORS configuration
- Sample Hello World Lambda function

**Template**: `template.yaml` (AWS SAM)

**Resources Created**:
- API Gateway REST API with configured stage
- Lambda function with API integration
- CloudWatch log groups with 30-day retention
- IAM roles and permissions (automatically managed by SAM)

**Outputs**:
- API URL endpoint
- API Gateway ID
- Lambda function ARN

### S3 Stack (`s3/`)

Deploys:
- Application data bucket (private, encrypted, versioned)
- Static assets bucket (public, web hosting enabled)
- Logs bucket (with lifecycle policies)

**Template**: `template.yaml` (CloudFormation)

**Resources Created**:
- Three S3 buckets with appropriate policies
- Encryption enabled on all buckets
- Lifecycle rules for cost optimization
- CORS configuration for static assets

**Outputs**:
- Bucket names and ARNs
- Static assets website URL

## Parameters

Both stacks accept the following parameters:

- `Environment` - Deployment environment (dev/staging/prod)
- `ProjectName` - Project name (default: yeojeong)

## Deployment

### Manual Deployment

Using AWS SAM CLI:

```bash
# Deploy API Gateway stack
sam deploy \
  --template-file infrastructure/api-gateway/template.yaml \
  --stack-name yeojeong-dev-api-gateway \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --parameter-overrides Environment=dev ProjectName=yeojeong \
  --region us-east-1

# Deploy S3 stack
sam deploy \
  --template-file infrastructure/s3/template.yaml \
  --stack-name yeojeong-dev-s3 \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides Environment=dev ProjectName=yeojeong \
  --region us-east-1
```

### Automated Deployment

Infrastructure is automatically deployed via GitHub Actions and CodeBuild when changes are pushed to the `infrastructure/` directory.

You can also manually trigger deployment:

1. Go to GitHub Actions
2. Select "Deploy Infrastructure"
3. Click "Run workflow"
4. Choose environment and stack
5. Click "Run workflow"

## Validation

Validate templates before deployment:

```bash
# Validate API Gateway template
sam validate --template infrastructure/api-gateway/template.yaml

# Validate S3 template
aws cloudformation validate-template \
  --template-body file://infrastructure/s3/template.yaml
```

## Stack Outputs

View deployed stack outputs:

```bash
# API Gateway outputs
aws cloudformation describe-stacks \
  --stack-name yeojeong-dev-api-gateway \
  --query 'Stacks[0].Outputs'

# S3 outputs
aws cloudformation describe-stacks \
  --stack-name yeojeong-dev-s3 \
  --query 'Stacks[0].Outputs'
```

## Updating Stacks

To update a stack, modify the template and deploy again. SAM/CloudFormation will create a changeset and apply only the changes.

## Deleting Stacks

To delete a stack:

```bash
# Delete API Gateway stack
aws cloudformation delete-stack --stack-name yeojeong-dev-api-gateway

# Delete S3 stack (must empty buckets first)
aws s3 rm s3://yeojeong-dev-app-data-{ACCOUNT_ID} --recursive
aws s3 rm s3://yeojeong-dev-static-{ACCOUNT_ID} --recursive
aws s3 rm s3://yeojeong-dev-logs-{ACCOUNT_ID} --recursive
aws cloudformation delete-stack --stack-name yeojeong-dev-s3
```

## Best Practices

1. **Always use parameters** for environment-specific values
2. **Export important outputs** for cross-stack references
3. **Tag all resources** with Environment and Project tags
4. **Enable encryption** on all data stores
5. **Set retention policies** on log groups
6. **Use lifecycle policies** for cost optimization
7. **Validate templates** before deployment
8. **Review changesets** before applying changes

## Adding New Infrastructure

To add new infrastructure:

1. Create a new directory under `infrastructure/`
2. Add a `template.yaml` file
3. Update `buildspecs/infrastructure-buildspec.yml` to include the new stack
4. Update `.github/workflows/deploy-infrastructure.yml` to include the new stack option
5. Document the new stack in this README
