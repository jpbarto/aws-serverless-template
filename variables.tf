variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for URL mappings"
  type        = string
  default     = "url-shortener"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "url-shortener-api"
}

variable "api_gateway_name" {
  description = "Name of the API Gateway REST API"
  type        = string
  default     = "url-shortener-api"
}

variable "api_stage_name" {
  description = "API Gateway deployment stage name"
  type        = string
  default     = "prod"
}
