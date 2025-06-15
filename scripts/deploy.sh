#!/bin/bash

# Default values
ENVIRONMENT=${1:-"dev"}
REGION=${2:-"us-east-1"}

# Exit on error
set -e

# Build TypeScript code
echo "Building TypeScript code..."
npm run build

# Create deployment package
echo "Creating deployment package..."
TIMESTAMP=$(date +%Y%m%d%H%M%S)
DEPLOYMENT_DIR="deployments/$TIMESTAMP"

# Create deployment directory
mkdir -p "$DEPLOYMENT_DIR"

# Copy built files
cp -r dist/* "$DEPLOYMENT_DIR/"

# Install production dependencies
cd "$DEPLOYMENT_DIR"
npm install --production
cd ../..

# Create ZIP file
ZIP_FILE="$DEPLOYMENT_DIR.zip"
zip -r "$ZIP_FILE" "$DEPLOYMENT_DIR"

# Deploy using Terraform
echo "Deploying infrastructure..."
cd infra
terraform init
terraform workspace select "$ENVIRONMENT"
terraform apply -var="environment=$ENVIRONMENT" -var="aws_region=$REGION" -auto-approve

# Clean up
echo "Cleaning up..."
rm -rf "$DEPLOYMENT_DIR"
rm -f "$ZIP_FILE"

echo "Deployment completed successfully!" 