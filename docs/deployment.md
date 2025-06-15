# Deployment Guide

## Prerequisites

1. **AWS Account Setup**
   - AWS Account with appropriate permissions
   - AWS CLI configured
   - AWS credentials set up
   - Required IAM roles and policies

2. **Development Environment**
   - Node.js 18.x or later
   - PowerShell 7.5 or later
   - Terraform 1.0.0 or later
   - Git

3. **Required Tools**
   ```powershell
   # Install AWS CLI
   winget install Amazon.AWSCLI

   # Install Terraform
   winget install HashiCorp.Terraform

   # Install Node.js
   winget install OpenJS.NodeJS.LTS
   ```

## Infrastructure Setup

### 1. Initialize Terraform

```powershell
# Navigate to infrastructure directory
Set-Location -Path "infra"

# Initialize Terraform
terraform init

# Validate configuration
terraform validate
```

### 2. Configure Variables

Create `terraform.tfvars`:

```hcl
aws_region = "us-east-1"
environment = "production"
project_name = "site-comms"

# DynamoDB Configuration
dynamodb_read_capacity = 5
dynamodb_write_capacity = 5

# Lambda Configuration
lambda_memory_size = 256
lambda_timeout = 30

# API Gateway Configuration
api_stage_name = "v1"
```

### 3. Deploy Infrastructure

```powershell
# Plan deployment
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

## Application Deployment

### 1. Build Lambda Functions

```powershell
# Install dependencies
npm install

# Build TypeScript
npm run build
```

### 2. Package and Deploy Functions

```powershell
# Create deployment package
Compress-Archive -Path "dist/*" -DestinationPath "deployment.zip"

# Deploy to AWS
aws lambda update-function-code `
    --function-name site-comms-sendMessage `
    --zip-file fileb://deployment.zip
```

### 3. Update API Gateway

```powershell
# Deploy API Gateway
aws apigateway create-deployment `
    --rest-api-id $apiId `
    --stage-name v1
```

## Environment Configuration

### 1. Set Environment Variables

```powershell
# Set Lambda environment variables
aws lambda update-function-configuration `
    --function-name site-comms-sendMessage `
    --environment "Variables={TABLE_NAME=Messages,TOPIC_ARN=arn:aws:sns:region:account:notifications}"
```

### 2. Configure CloudWatch

```powershell
# Create log groups
aws logs create-log-group `
    --log-group-name "/aws/lambda/site-comms-sendMessage"

# Set retention
aws logs put-retention-policy `
    --log-group-name "/aws/lambda/site-comms-sendMessage" `
    --retention-in-days 30
```

## Monitoring Setup

### 1. Create CloudWatch Dashboard

```powershell
# Create dashboard
aws cloudwatch put-dashboard `
    --dashboard-name "SiteCommsDashboard" `
    --dashboard-body file://dashboard.json
```

### 2. Set Up Alarms

```powershell
# Create SNS topic
aws sns create-topic `
    --name "site-comms-alerts"

# Create CloudWatch alarm
aws cloudwatch put-metric-alarm `
    --alarm-name "LambdaErrors" `
    --metric-name "Errors" `
    --namespace "AWS/Lambda" `
    --statistic "Sum" `
    --period 300 `
    --evaluation-periods 1 `
    --threshold 0 `
    --comparison-operator "GreaterThanThreshold" `
    --alarm-actions "arn:aws:sns:region:account:site-comms-alerts"
```

## Security Configuration

### 1. Set Up IAM Roles

```powershell
# Create Lambda execution role
aws iam create-role `
    --role-name "site-comms-lambda-role" `
    --assume-role-policy-document file://lambda-trust-policy.json

# Attach policies
aws iam attach-role-policy `
    --role-name "site-comms-lambda-role" `
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
```

### 2. Configure API Gateway Authorizer

```powershell
# Create authorizer
aws apigateway create-authorizer `
    --rest-api-id $apiId `
    --name "site-comms-authorizer" `
    --type TOKEN `
    --authorizer-uri "arn:aws:apigateway:region:lambda:path/2015-03-31/functions/arn:aws:lambda:region:account:function:site-comms-authorizer/invocations"
```

## Testing Deployment

### 1. API Testing

```powershell
# Test user creation
$body = @{
    "email" = "test@example.com"
    "name" = "Test User"
} | ConvertTo-Json

Invoke-RestMethod `
    -Uri "https://api.example.com/v1/users" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"
```

### 2. WebSocket Testing

```powershell
# Test WebSocket connection
$ws = New-Object System.Net.WebSockets.ClientWebSocket
$ws.ConnectAsync("wss://ws.example.com", $null).Wait()
```

## Rollback Procedures

### 1. Infrastructure Rollback

```powershell
# Revert Terraform changes
terraform apply -auto-approve -var-file=previous.tfvars
```

### 2. Application Rollback

```powershell
# Revert Lambda function
aws lambda update-function-code `
    --function-name site-comms-sendMessage `
    --zip-file fileb://previous-deployment.zip
```

## Maintenance

### 1. Regular Updates

```powershell
# Update dependencies
npm update

# Rebuild and deploy
npm run build
Compress-Archive -Path "dist/*" -DestinationPath "deployment.zip"
aws lambda update-function-code `
    --function-name site-comms-sendMessage `
    --zip-file fileb://deployment.zip
```

### 2. Backup Procedures

```powershell
# Backup DynamoDB tables
aws dynamodb create-backup `
    --table-name Messages `
    --backup-name "Messages-$(Get-Date -Format 'yyyyMMdd')"
```

## Troubleshooting

### Common Issues

1. **Lambda Deployment Failures**
   - Check IAM permissions
   - Verify package size
   - Review CloudWatch logs

2. **API Gateway Issues**
   - Check CORS configuration
   - Verify authorizer setup
   - Review API Gateway logs

3. **WebSocket Connection Problems**
   - Check connection permissions
   - Verify route configuration
   - Review WebSocket logs

### Debug Commands

```powershell
# View Lambda logs
aws logs get-log-events `
    --log-group-name "/aws/lambda/site-comms-sendMessage" `
    --log-stream-name "latest"

# Check API Gateway configuration
aws apigateway get-rest-api `
    --rest-api-id $apiId

# Monitor WebSocket connections
aws apigateway get-connections `
    --api-id $wsApiId
``` 