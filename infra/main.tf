terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    # These values will be set during initialization
    # bucket = "your-terraform-state-bucket"
    # key    = "site-comms/terraform.tfstate"
    # region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# DynamoDB Tables
resource "aws_dynamodb_table" "users" {
  name           = "${var.project_name}-users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "userId"
  attribute {
    name = "userId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "messages" {
  name           = "${var.project_name}-messages"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "messageId"
  range_key      = "userId"
  attribute {
    name = "messageId"
    type = "S"
  }
  attribute {
    name = "userId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "notifications" {
  name           = "${var.project_name}-notifications"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "notificationId"
  range_key      = "userId"
  attribute {
    name = "notificationId"
    type = "S"
  }
  attribute {
    name = "userId"
    type = "S"
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "main" {
  api_id = aws_apigatewayv2_api.main.id
  name   = "prod"
  auto_deploy = true
}

# WebSocket API for real-time notifications
resource "aws_apigatewayv2_api" "websocket" {
  name          = "${var.project_name}-ws"
  protocol_type = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_stage" "websocket" {
  api_id = aws_apigatewayv2_api.websocket.id
  name   = "prod"
  auto_deploy = true
}

# SNS Topic for notifications
resource "aws_sns_topic" "notifications" {
  name = "${var.project_name}-notifications"
}

# IAM Role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda functions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:*",
          "sns:Publish",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
} 