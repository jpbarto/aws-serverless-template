# Serverless URL Shortener

A serverless URL shortener REST API built with AWS Lambda, API Gateway, and DynamoDB, deployed using Terraform.

## Architecture

- **AWS Lambda**: Node.js function handling all CRUD operations
- **API Gateway REST API**: RESTful endpoints for URL management
- **DynamoDB**: NoSQL database storing URL mappings (slug → full URL)
- **Terraform**: Infrastructure as Code for provisioning all AWS resources

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [Node.js](https://nodejs.org/) >= 18.x (for local Lambda development)
- AWS Account with permissions to create Lambda, API Gateway, DynamoDB, and IAM resources

## Project Structure

```
.
├── src/
│   └── lambda/
│       ├── index.js        # Lambda function code
│       └── package.json    # Node.js dependencies
├── terraform/
│   ├── provider.tf          # Terraform provider configuration
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   ├── dynamodb.tf          # DynamoDB table definition
│   ├── iam.tf              # IAM roles and policies
│   ├── lambda.tf           # Lambda function configuration
│   ├── api-gateway.tf      # API Gateway REST API
│   └── api-resources.tf    # API Gateway resources and methods
└── README.md           # This file
```

## Deployment

### 1. Install Lambda Dependencies

```bash
cd src/lambda
npm install
cd ../..
```

### 2. Initialize Terraform

```bash
cd terraform
terraform init
```

### 3. Review Infrastructure Plan

```bash
terraform plan
```

### 4. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

### 5. Get API Endpoint

After deployment, Terraform will output the API endpoint URL:

```bash
terraform output api_endpoint
```

## API Endpoints

Base URL: `https://{api-id}.execute-api.{region}.amazonaws.com/prod`

### Create Shortened URL

**POST** `/urls`

Create a new shortened URL with a custom slug.

**Request Body:**
```json
{
  "slug": "example",
  "fullUrl": "https://www.example.com"
}
```

**Response (201):**
```json
{
  "slug": "example",
  "fullUrl": "https://www.example.com",
  "createdAt": "2026-02-18T13:00:00.000Z",
  "updatedAt": "2026-02-18T13:00:00.000Z"
}
```

**Example:**
```bash
curl -X POST https://your-api-endpoint/prod/urls \
  -H "Content-Type: application/json" \
  -d '{"slug": "example", "fullUrl": "https://www.example.com"}'
```

### List All URLs

**GET** `/urls`

Retrieve all shortened URLs.

**Response (200):**
```json
{
  "items": [
    {
      "slug": "example",
      "fullUrl": "https://www.example.com",
      "createdAt": "2026-02-18T13:00:00.000Z",
      "updatedAt": "2026-02-18T13:00:00.000Z"
    }
  ],
  "count": 1
}
```

**Example:**
```bash
curl https://your-api-endpoint/prod/urls
```

### Redirect to Full URL

**GET** `/urls/{slug}`

Redirects to the full URL associated with the slug (HTTP 302).

**Response (302):**
- Header: `Location: https://www.example.com`

**Example:**
```bash
curl -L https://your-api-endpoint/prod/urls/example
```

Or visit in browser: `https://your-api-endpoint/prod/urls/example`

### Update URL

**PUT** `/urls/{slug}`

Update the full URL for an existing slug.

**Request Body:**
```json
{
  "fullUrl": "https://www.updated-example.com"
}
```

**Response (200):**
```json
{
  "slug": "example",
  "fullUrl": "https://www.updated-example.com",
  "createdAt": "2026-02-18T13:00:00.000Z",
  "updatedAt": "2026-02-18T14:00:00.000Z"
}
```

**Example:**
```bash
curl -X PUT https://your-api-endpoint/prod/urls/example \
  -H "Content-Type: application/json" \
  -d '{"fullUrl": "https://www.updated-example.com"}'
```

### Delete URL

**DELETE** `/urls/{slug}`

Delete a shortened URL.

**Response (200):**
```json
{
  "message": "URL deleted successfully"
}
```

**Example:**
```bash
curl -X DELETE https://your-api-endpoint/prod/urls/example
```

## Configuration

### Variables

You can customize the deployment by creating a `terraform.tfvars` file:

```hcl
aws_region          = "us-east-1"
environment         = "dev"
dynamodb_table_name = "url-shortener"
lambda_function_name = "url-shortener-api"
api_gateway_name    = "url-shortener-api"
api_stage_name      = "prod"
```

## Error Responses

The API returns standard HTTP status codes:

- `200`: Success
- `201`: Created
- `302`: Redirect
- `400`: Bad Request (invalid input)
- `404`: Not Found (slug doesn't exist)
- `409`: Conflict (slug already exists)
- `500`: Internal Server Error

**Example Error Response:**
```json
{
  "error": "Slug already exists"
}
```

## Testing the API

### Complete Workflow Example

```bash
# Set your API endpoint (run from terraform directory)
cd terraform
API_ENDPOINT=$(terraform output -raw api_endpoint)

# Create a shortened URL
curl -X POST $API_ENDPOINT/urls \
  -H "Content-Type: application/json" \
  -d '{"slug": "github", "fullUrl": "https://github.com"}'

# List all URLs
curl $API_ENDPOINT/urls

# Test redirect (follow redirects with -L)
curl -L $API_ENDPOINT/urls/github

# Update URL
curl -X PUT $API_ENDPOINT/urls/github \
  -H "Content-Type: application/json" \
  -d '{"fullUrl": "https://github.com/features"}'

# Delete URL
curl -X DELETE $API_ENDPOINT/urls/github
```

## Cleanup

To destroy all resources created by Terraform:

```bash
cd terraform
terraform destroy
```

Type `yes` when prompted to confirm.

## Cost Considerations

This serverless architecture uses pay-per-use pricing:

- **Lambda**: Free tier includes 1M requests/month and 400,000 GB-seconds of compute
- **API Gateway**: Free tier includes 1M API calls/month for 12 months
- **DynamoDB**: Free tier includes 25 GB storage and 25 WCU/RCU

Beyond free tier, costs are minimal for low-to-moderate traffic.

## Security Considerations

- The API is currently public (no authentication)
- For production use, consider adding:
  - API Gateway API keys or AWS IAM authentication
  - Rate limiting and throttling
  - Input validation and sanitization
  - WAF (Web Application Firewall) rules

## Troubleshooting

### Lambda Logs

View Lambda function logs:
```bash
aws logs tail /aws/lambda/url-shortener-api --follow
```

### Test Lambda Directly

```bash
aws lambda invoke \
  --function-name url-shortener-api \
  --payload '{"httpMethod":"GET","resource":"/urls","pathParameters":{}}' \
  response.json
cat response.json
```

## License

MIT
