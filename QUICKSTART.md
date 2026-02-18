# Quick Start Guide

## Deploy in 3 Steps

### 1. Install Lambda Dependencies
```bash
cd src/lambda
npm install
cd ../..
```

### 2. Deploy with Terraform
```bash
cd terraform
terraform init
terraform apply
```

### 3. Test Your API
```bash
# Get the API endpoint (from terraform directory)
API_ENDPOINT=$(terraform output -raw api_endpoint)

# Create a short URL
curl -X POST $API_ENDPOINT/urls \
  -H "Content-Type: application/json" \
  -d '{"slug": "test", "fullUrl": "https://example.com"}'

# Test the redirect
curl -L $API_ENDPOINT/urls/test
```

That's it! Your serverless URL shortener is now live.

## What's Included

✅ Full CRUD API for URL management  
✅ 302 redirects for shortened URLs  
✅ DynamoDB for persistent storage  
✅ Serverless architecture (pay per use)  
✅ Complete Terraform IaC  
✅ CORS enabled  
✅ Input validation  
✅ Error handling  

## Need Help?

See the full [README.md](README.md) for:
- Complete API documentation
- Configuration options
- Troubleshooting tips
- Testing examples
