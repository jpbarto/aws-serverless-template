# /urls resource
resource "aws_api_gateway_resource" "urls" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "urls"
}

# /urls/{slug} resource
resource "aws_api_gateway_resource" "urls_slug" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.urls.id
  path_part   = "{slug}"
}

# POST /urls - Create URL
resource "aws_api_gateway_method" "create_url" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.urls.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create_url" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.urls.id
  http_method             = aws_api_gateway_method.create_url.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.url_shortener.invoke_arn
}

# GET /urls - List URLs
resource "aws_api_gateway_method" "list_urls" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.urls.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "list_urls" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.urls.id
  http_method             = aws_api_gateway_method.list_urls.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.url_shortener.invoke_arn
}

# GET /urls/{slug} - Redirect
resource "aws_api_gateway_method" "get_url" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.urls_slug.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.slug" = true
  }
}

resource "aws_api_gateway_integration" "get_url" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.urls_slug.id
  http_method             = aws_api_gateway_method.get_url.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.url_shortener.invoke_arn
}

# PUT /urls/{slug} - Update URL
resource "aws_api_gateway_method" "update_url" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.urls_slug.id
  http_method   = "PUT"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.slug" = true
  }
}

resource "aws_api_gateway_integration" "update_url" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.urls_slug.id
  http_method             = aws_api_gateway_method.update_url.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.url_shortener.invoke_arn
}

# DELETE /urls/{slug} - Delete URL
resource "aws_api_gateway_method" "delete_url" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.urls_slug.id
  http_method   = "DELETE"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.slug" = true
  }
}

resource "aws_api_gateway_integration" "delete_url" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.urls_slug.id
  http_method             = aws_api_gateway_method.delete_url.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.url_shortener.invoke_arn
}

# OPTIONS methods for CORS
resource "aws_api_gateway_method" "options_urls" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.urls.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_urls" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.urls.id
  http_method             = aws_api_gateway_method.options_urls.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.url_shortener.invoke_arn
}

resource "aws_api_gateway_method" "options_urls_slug" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.urls_slug.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_urls_slug" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.urls_slug.id
  http_method             = aws_api_gateway_method.options_urls_slug.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.url_shortener.invoke_arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.urls.id,
      aws_api_gateway_resource.urls_slug.id,
      aws_api_gateway_method.create_url.id,
      aws_api_gateway_method.list_urls.id,
      aws_api_gateway_method.get_url.id,
      aws_api_gateway_method.update_url.id,
      aws_api_gateway_method.delete_url.id,
      aws_api_gateway_integration.create_url.id,
      aws_api_gateway_integration.list_urls.id,
      aws_api_gateway_integration.get_url.id,
      aws_api_gateway_integration.update_url.id,
      aws_api_gateway_integration.delete_url.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.create_url,
    aws_api_gateway_integration.list_urls,
    aws_api_gateway_integration.get_url,
    aws_api_gateway_integration.update_url,
    aws_api_gateway_integration.delete_url,
    aws_api_gateway_integration.options_urls,
    aws_api_gateway_integration.options_urls_slug
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.api_stage_name

  tags = {
    Name = "${var.api_gateway_name}-${var.api_stage_name}"
  }
}
