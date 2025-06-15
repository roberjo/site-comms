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

resource "aws_dynamodb_table" "connections" {
  name           = "${var.project_name}-connections"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "connectionId"
  attribute {
    name = "connectionId"
    type = "S"
  }
  attribute {
    name = "userId"
    type = "S"
  }
  global_secondary_index {
    name            = "UserIdIndex"
    hash_key        = "userId"
    projection_type = "ALL"
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

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip            = "$context.identity.sourceIp"
      requestTime   = "$context.requestTime"
      httpMethod    = "$context.httpMethod"
      routeKey      = "$context.routeKey"
      status        = "$context.status"
      protocol      = "$context.protocol"
      responseTime  = "$context.responseLatency"
      integrationError = "$context.integrationErrorMessage"
    })
  }
}

# WebSocket API
resource "aws_apigatewayv2_api" "websocket" {
  name          = "${var.project_name}-ws"
  protocol_type = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_stage" "websocket" {
  api_id = aws_apigatewayv2_api.websocket.id
  name   = "prod"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.websocket_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip            = "$context.identity.sourceIp"
      requestTime   = "$context.requestTime"
      routeKey      = "$context.routeKey"
      status        = "$context.status"
      connectionId  = "$context.connectionId"
      latency       = "$context.integrationLatency"
      integrationError = "$context.integrationErrorMessage"
    })
  }
}

# WebSocket Routes
resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.websocket_connection.id}"
}

resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.websocket_connection.id}"
}

# WebSocket Integration
resource "aws_apigatewayv2_integration" "websocket_connection" {
  api_id           = aws_apigatewayv2_api.websocket.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.websocket_connection.invoke_arn
}

# Lambda Functions
resource "aws_lambda_function" "create_user" {
  filename         = "../dist/functions/users/createUser.zip"
  function_name    = "${var.project_name}-create-user"
  role            = aws_iam_role.lambda_role.arn
  handler         = "createUser.handler"
  runtime         = "nodejs18.x"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment {
    variables = {
      USERS_TABLE_NAME = aws_dynamodb_table.users.name
    }
  }
}

resource "aws_lambda_function" "get_user" {
  filename         = "../dist/functions/users/getUser.zip"
  function_name    = "${var.project_name}-get-user"
  role            = aws_iam_role.lambda_role.arn
  handler         = "getUser.handler"
  runtime         = "nodejs18.x"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment {
    variables = {
      USERS_TABLE_NAME = aws_dynamodb_table.users.name
    }
  }
}

resource "aws_lambda_function" "update_user" {
  filename         = "../dist/functions/users/updateUser.zip"
  function_name    = "${var.project_name}-update-user"
  role            = aws_iam_role.lambda_role.arn
  handler         = "updateUser.handler"
  runtime         = "nodejs18.x"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment {
    variables = {
      USERS_TABLE_NAME = aws_dynamodb_table.users.name
    }
  }
}

resource "aws_lambda_function" "delete_user" {
  filename         = "../dist/functions/users/deleteUser.zip"
  function_name    = "${var.project_name}-delete-user"
  role            = aws_iam_role.lambda_role.arn
  handler         = "deleteUser.handler"
  runtime         = "nodejs18.x"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment {
    variables = {
      USERS_TABLE_NAME = aws_dynamodb_table.users.name
    }
  }
}

resource "aws_lambda_function" "send_message" {
  filename         = "../dist/functions/messages/sendMessage.zip"
  function_name    = "${var.project_name}-send-message"
  role            = aws_iam_role.lambda_role.arn
  handler         = "sendMessage.handler"
  runtime         = "nodejs18.x"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment {
    variables = {
      MESSAGES_TABLE_NAME = aws_dynamodb_table.messages.name
      NOTIFICATIONS_TABLE_NAME = aws_dynamodb_table.notifications.name
      NOTIFICATIONS_TOPIC_ARN = aws_sns_topic.notifications.arn
      WEBSOCKET_API_ENDPOINT = aws_apigatewayv2_api.websocket.api_endpoint
    }
  }
}

resource "aws_lambda_function" "websocket_connection" {
  filename         = "../dist/functions/websocket/connectionHandler.zip"
  function_name    = "${var.project_name}-websocket-connection"
  role            = aws_iam_role.lambda_role.arn
  handler         = "connectionHandler.handler"
  runtime         = "nodejs18.x"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment {
    variables = {
      CONNECTIONS_TABLE_NAME = aws_dynamodb_table.connections.name
    }
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${var.project_name}-api"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "websocket_logs" {
  name              = "/aws/apigateway/${var.project_name}-websocket"
  retention_in_days = 30
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = {
    create_user = aws_lambda_function.create_user.function_name
    get_user = aws_lambda_function.get_user.function_name
    update_user = aws_lambda_function.update_user.function_name
    delete_user = aws_lambda_function.delete_user.function_name
    send_message = aws_lambda_function.send_message.function_name
    websocket_connection = aws_lambda_function.websocket_connection.function_name
  }

  alarm_name          = "${var.project_name}-${each.key}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "This metric monitors lambda function errors"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = each.value
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  for_each = {
    create_user = aws_lambda_function.create_user.function_name
    get_user = aws_lambda_function.get_user.function_name
    update_user = aws_lambda_function.update_user.function_name
    delete_user = aws_lambda_function.delete_user.function_name
    send_message = aws_lambda_function.send_message.function_name
    websocket_connection = aws_lambda_function.websocket_connection.function_name
  }

  alarm_name          = "${var.project_name}-${each.key}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period             = "300"
  statistic          = "Average"
  threshold          = "25000" # 25 seconds
  alarm_description  = "This metric monitors lambda function duration"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = each.value
  }
}

# SNS Topics
resource "aws_sns_topic" "notifications" {
  name = "${var.project_name}-notifications"
}

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
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
          "logs:PutLogEvents",
          "execute-api:ManageConnections"
        ]
        Resource = "*"
      }
    ]
  })
} 