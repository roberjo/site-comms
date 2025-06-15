# Site Communications Backend

A serverless backend system for user admin dashboard built with AWS services.

## Architecture

- AWS Lambda functions (TypeScript)
- API Gateway (REST + WebSocket)
- DynamoDB for data storage
- SNS for push notifications
- Terraform for infrastructure as code

## Features

- User management (CRUD operations)
- Real-time notifications
- User messaging system
- User settings management
- Push notifications for new events

## Prerequisites

- Node.js 18+
- Terraform 1.0+
- AWS CLI configured
- TypeScript 4.9+
- Bash shell

## Project Structure

```
.
├── infra/               # Terraform infrastructure code
├── src/                 # Lambda function source code
│   ├── functions/      # Individual Lambda functions
│   ├── shared/         # Shared code and utilities
│   └── tests/          # Test files
├── scripts/            # Build and deployment scripts
└── docs/              # Documentation
```

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Configure AWS credentials:
   ```bash
   aws configure
   ```

3. Initialize Terraform:
   ```bash
   cd infra
   terraform init
   ```

4. Deploy infrastructure:
   ```bash
   ./scripts/deploy.sh
   ```

## Development

- Run tests:
  ```bash
  npm test
  ```

- Build functions:
  ```bash
  npm run build
  ```

- Deploy functions:
  ```bash
  ./scripts/deploy.sh [environment] [region]
  ```

## Testing

The project uses Jest for unit testing and integration testing. Run tests with:

```bash
npm test
```

## License

MIT
