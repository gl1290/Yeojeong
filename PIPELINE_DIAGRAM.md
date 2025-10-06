# CI/CD Pipeline Flow Diagram

## Complete Deployment Pipeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            DEVELOPER WORKFLOW                                │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
                    ┌─────────────────────────────────┐
                    │   Git Push to Repository        │
                    │   (main or develop branch)      │
                    └─────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           GITHUB ACTIONS                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐  ┌─────────────┐  ┌─────────────┐  ┌──────────────────┐ │
│  │   CI Build   │  │   Lambda    │  │     ECS     │  │  Infrastructure  │ │
│  │   & Test     │  │   Deploy    │  │   Deploy    │  │     Deploy       │ │
│  └──────────────┘  └─────────────┘  └─────────────┘  └──────────────────┘ │
│         │                 │                 │                   │           │
│         ▼                 ▼                 ▼                   ▼           │
│  - Checkout         - Configure       - ECR Login        - Configure       │
│  - Setup Node       - AWS Creds       - Trigger Build    - AWS Creds       │
│  - Install          - Trigger         - Monitor          - Trigger         │
│  - Lint             - CodeBuild       - Update ECS       - CodeBuild       │
│  - Test             - Monitor         - Services         - Monitor         │
│  - Build            - Report          - Report           - Report          │
│  - Upload                                                                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AWS CODEBUILD                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────┐  ┌──────────────────────────┐                │
│  │  Lambda BuildSpec        │  │  ECS BuildSpec           │                │
│  ├──────────────────────────┤  ├──────────────────────────┤                │
│  │ Pre-build:              │  │ Pre-build:              │                │
│  │ • npm install           │  │ • ECR login             │                │
│  │                         │  │ • Get repo URI          │                │
│  │ Build:                  │  │                         │                │
│  │ • Package functions     │  │ Build:                  │                │
│  │ • Create ZIP files      │  │ • Build Docker images   │                │
│  │                         │  │ • Tag images            │                │
│  │ Post-build:             │  │                         │                │
│  │ • Deploy to Lambda      │  │ Post-build:             │                │
│  │ • Update config         │  │ • Push to ECR           │                │
│  └──────────────────────────┘  │ • Update task defs      │                │
│                                 │ • Update ECS services   │                │
│  ┌──────────────────────────┐  │ • Wait for stable       │                │
│  │  Infrastructure BuildSpec│  └──────────────────────────┘                │
│  ├──────────────────────────┤                                              │
│  │ Pre-build:              │                                              │
│  │ • Install SAM CLI       │                                              │
│  │                         │                                              │
│  │ Build:                  │                                              │
│  │ • Deploy SAM templates  │                                              │
│  │ • Deploy CFN stacks     │                                              │
│  │                         │                                              │
│  │ Post-build:             │                                              │
│  │ • Output stack info     │                                              │
│  └──────────────────────────┘                                              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AWS SERVICES                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │   Lambda    │  │     ECS     │  │     ECR     │  │   API Gateway   │  │
│  │  Functions  │  │   Services  │  │  Repository │  │                 │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────┘  │
│        │                 │                 │                 │             │
│        │                 │                 │                 │             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │     S3      │  │ CloudWatch  │  │     IAM     │  │  CloudFormation │  │
│  │   Buckets   │  │    Logs     │  │    Roles    │  │     Stacks      │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Deployment Triggers

### Automatic Triggers

| Path Changed              | Workflow Triggered           | CodeBuild Project           |
|---------------------------|-----------------------------|-----------------------------|
| `lambda/**`               | deploy-lambda.yml           | yeojeong-lambda-deploy      |
| `ecs/**`                  | deploy-ecs.yml              | yeojeong-ecs-deploy         |
| `infrastructure/**`       | deploy-infrastructure.yml   | yeojeong-infrastructure-deploy |
| Any file (main/develop)   | ci.yml                      | N/A (runs in GitHub)        |

### Manual Triggers

All deployment workflows can be manually triggered via GitHub Actions UI with:
- **Environment selection**: dev, staging, prod
- **Service/Stack selection**: specific or all

## Pipeline Features

### Security
- ✅ AWS credentials stored as GitHub Secrets
- ✅ Environment-based access control
- ✅ Encrypted S3 buckets
- ✅ IAM roles with least privilege
- ✅ ECR image scanning

### Reliability
- ✅ Build status monitoring
- ✅ Automatic rollback on failure (CloudFormation)
- ✅ Health checks (Lambda, ECS)
- ✅ Service stability waiting (ECS)
- ✅ Dependency caching (faster builds)

### Observability
- ✅ CloudWatch Logs integration
- ✅ Build artifact upload
- ✅ Stack output reporting
- ✅ Deployment status in GitHub
- ✅ CodeBuild logs accessible

### Scalability
- ✅ Multi-environment support
- ✅ Multi-service deployments
- ✅ Parallel build capability
- ✅ Fargate auto-scaling ready
- ✅ Lambda auto-scaling built-in

## Workflow Execution Time

| Workflow                | Typical Duration  | Notes                          |
|-------------------------|-------------------|--------------------------------|
| CI Build & Test         | 2-5 minutes       | Depends on test suite size     |
| Lambda Deployment       | 3-7 minutes       | Per function, includes package |
| ECS Deployment          | 10-15 minutes     | Includes image build & push    |
| Infrastructure Deploy   | 5-10 minutes      | Per stack, CloudFormation      |

## Cost Optimization

- Node modules caching (Lambda buildspec)
- Docker layer caching (ECS builds)
- S3 lifecycle policies (logs, old versions)
- CloudWatch log retention (30 days)
- Fargate Spot instances (configurable)

## Environment Isolation

```
Development (dev)
├── yeojeong-dev-api-gateway stack
├── yeojeong-dev-s3 stack
├── yeojeong-dev-hello-world function
├── yeojeong-dev-cluster (ECS)
└── yeojeong-dev-*-{account-id} buckets

Staging (staging)
├── yeojeong-staging-* resources
└── ... (same structure as dev)

Production (prod)
├── yeojeong-prod-* resources
└── ... (same structure as dev)
```

Each environment is completely isolated with separate:
- AWS resources
- GitHub environment configurations
- Deployment approvals (configurable)
- Secret values
