# HTTP API Routes
resource "aws_apigatewayv2_route" "create_user" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /users"
  target    = "integrations/${aws_apigatewayv2_integration.create_user.id}"
}

resource "aws_apigatewayv2_route" "get_user" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /users/{userId}"
  target    = "integrations/${aws_apigatewayv2_integration.get_user.id}"
}

resource "aws_apigatewayv2_route" "update_user" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "PUT /users/{userId}"
  target    = "integrations/${aws_apigatewayv2_integration.update_user.id}"
}

resource "aws_apigatewayv2_route" "delete_user" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "DELETE /users/{userId}"
  target    = "integrations/${aws_apigatewayv2_integration.delete_user.id}"
}

resource "aws_apigatewayv2_route" "send_message" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /messages"
  target    = "integrations/${aws_apigatewayv2_integration.send_message.id}"
}

# HTTP API Integrations
resource "aws_apigatewayv2_integration" "create_user" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.create_user.invoke_arn
}

resource "aws_apigatewayv2_integration" "get_user" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_user.invoke_arn
}

resource "aws_apigatewayv2_integration" "update_user" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.update_user.invoke_arn
}

resource "aws_apigatewayv2_integration" "delete_user" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.delete_user.invoke_arn
}

resource "aws_apigatewayv2_integration" "send_message" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.send_message.invoke_arn
}

# Lambda Permissions
resource "aws_lambda_permission" "create_user" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_user" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "update_user" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "delete_user" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "send_message" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send_message.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "websocket_connection" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.websocket_connection.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
} 