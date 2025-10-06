# Hello World Lambda Function

This is a sample Lambda function that demonstrates the basic structure for Lambda functions in this project.

## Function Details

- **Runtime**: Node.js 18.x
- **Handler**: index.handler
- **Memory**: 128 MB (configurable)
- **Timeout**: 30 seconds (configurable)

## Environment Variables

- `ENVIRONMENT`: The deployment environment (dev, staging, prod)
- `GIT_COMMIT`: The git commit hash of the deployed code

## Local Testing

To test locally:

```bash
npm install
npm test
```

## Deployment

This function is automatically deployed via GitHub Actions and AWS CodeBuild when changes are pushed to the `lambda/` directory.

## API Response

```json
{
  "message": "Hello from Yeojeong Lambda!",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "requestId": "abc-123",
  "environment": "dev"
}
```
