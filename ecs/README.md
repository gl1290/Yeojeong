# ECS Services

This directory contains the containerized services that run on Amazon ECS.

## Services

### API Service (`api/`)

A sample Express.js API service that demonstrates:
- RESTful endpoints
- Health check endpoint
- CORS configuration
- Proper logging
- Docker containerization

**Endpoints:**
- `GET /health` - Health check
- `GET /api/hello` - Sample GET endpoint
- `POST /api/echo` - Sample POST endpoint

### Worker Service (`worker/`)

A sample background worker service that demonstrates:
- Long-running processes
- Graceful shutdown handling
- Periodic task execution
- Error handling and retry logic

## Task Definitions

The `task-definitions/` directory contains ECS Fargate task definitions for each service:

- `api-task.json` - API service task definition
- `worker-task.json` - Worker service task definition

**Note**: Replace the following placeholders before deploying:
- `{ACCOUNT_ID}` - Your AWS account ID
- `{ECR_REPOSITORY_URI}` - Your ECR repository URI

## Local Development

### API Service

```bash
cd api
npm install
npm start
# Server runs on http://localhost:3000
```

Test endpoints:
```bash
curl http://localhost:3000/health
curl http://localhost:3000/api/hello
curl -X POST http://localhost:3000/api/echo -H "Content-Type: application/json" -d '{"test":"data"}'
```

### Worker Service

```bash
cd worker
npm install
npm start
# Worker will run continuously, processing tasks every 15 seconds
```

## Docker Build and Run

### API Service

```bash
cd api
docker build -t yeojeong-api .
docker run -p 3000:3000 -e ENVIRONMENT=dev yeojeong-api
```

### Worker Service

```bash
cd worker
docker build -t yeojeong-worker .
docker run -e ENVIRONMENT=dev yeojeong-worker
```

## Deployment

Deployments are handled automatically via GitHub Actions and CodeBuild when changes are pushed to the `ecs/` directory. You can also manually trigger deployments:

1. Go to GitHub Actions
2. Select "Deploy ECS Services"
3. Click "Run workflow"
4. Choose environment and service
5. Click "Run workflow"

## Environment Variables

Both services support the following environment variables:

- `ENVIRONMENT` - Deployment environment (dev/staging/prod)
- `GIT_COMMIT` - Git commit hash (automatically set during deployment)
- `PORT` - Port to run on (API service only, default: 3000)

## Monitoring

Logs are sent to CloudWatch Logs:
- API: `/ecs/yeojeong-{environment}-api`
- Worker: `/ecs/yeojeong-{environment}-worker`

View logs:
```bash
aws logs tail /ecs/yeojeong-dev-api --follow
aws logs tail /ecs/yeojeong-dev-worker --follow
```
