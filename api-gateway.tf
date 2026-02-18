resource "aws_api_gateway_rest_api" "main" {
  name        = var.api_gateway_name
  description = "REST API for URL Shortener service"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.url_shortener.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}
