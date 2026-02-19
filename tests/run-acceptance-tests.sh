#!/bin/bash

# Exit on error
set -e

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if URL is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: API URL required${NC}"
    echo "Usage: $0 <api-url>"
    exit 1
fi

API_URL="$1"
TEST_SLUG="test-$(date +%s)"
TEST_URL="https://example.com/test"
UPDATED_URL="https://example.com/updated"
FAILED_TESTS=0
PASSED_TESTS=0

echo -e "${YELLOW}URL Shortener Acceptance Tests${NC}"
echo "================================="
echo "Testing API at: $API_URL"
echo ""

# Helper function to test HTTP response
test_response() {
    local test_name="$1"
    local expected_status="$2"
    local response="$3"
    
    local actual_status=$(echo "$response" | head -n 1 | awk '{print $2}')
    
    if [ "$actual_status" = "$expected_status" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name (Expected: $expected_status, Got: $actual_status)"
        echo "$response"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Test 1: Create a new shortened URL
echo -e "${BLUE}Test 1: Create new shortened URL${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$API_URL/urls" \
    -H "Content-Type: application/json" \
    -d "{\"slug\":\"$TEST_SLUG\",\"fullUrl\":\"$TEST_URL\"}")
test_response "POST /urls with valid data" "201" "$RESPONSE"

# Test 2: Create URL with missing slug
echo -e "${BLUE}Test 2: Create URL with missing slug${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$API_URL/urls" \
    -H "Content-Type: application/json" \
    -d "{\"fullUrl\":\"$TEST_URL\"}")
test_response "POST /urls missing slug" "400" "$RESPONSE"

# Test 3: Create URL with missing fullUrl
echo -e "${BLUE}Test 3: Create URL with missing fullUrl${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$API_URL/urls" \
    -H "Content-Type: application/json" \
    -d "{\"slug\":\"another-slug\"}")
test_response "POST /urls missing fullUrl" "400" "$RESPONSE"

# Test 4: Create URL with invalid URL format
echo -e "${BLUE}Test 4: Create URL with invalid format${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$API_URL/urls" \
    -H "Content-Type: application/json" \
    -d "{\"slug\":\"invalid-url\",\"fullUrl\":\"not-a-valid-url\"}")
test_response "POST /urls with invalid URL" "400" "$RESPONSE"

# Test 5: Create duplicate slug
echo -e "${BLUE}Test 5: Create duplicate slug${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$API_URL/urls" \
    -H "Content-Type: application/json" \
    -d "{\"slug\":\"$TEST_SLUG\",\"fullUrl\":\"$TEST_URL\"}")
test_response "POST /urls with duplicate slug" "409" "$RESPONSE"

# Test 6: List all URLs
echo -e "${BLUE}Test 6: List all URLs${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET "$API_URL/urls")
test_response "GET /urls" "200" "$RESPONSE"

# Test 7: Get specific URL and redirect
echo -e "${BLUE}Test 7: Get URL and redirect${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -L -X GET "$API_URL/urls/$TEST_SLUG")
test_response "GET /urls/{slug} redirect" "302" "$RESPONSE"

# Test 8: Get non-existent URL
echo -e "${BLUE}Test 8: Get non-existent URL${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET "$API_URL/urls/nonexistent-slug-12345")
test_response "GET /urls/{slug} not found" "404" "$RESPONSE"

# Test 9: Update existing URL
echo -e "${BLUE}Test 9: Update existing URL${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X PUT "$API_URL/urls/$TEST_SLUG" \
    -H "Content-Type: application/json" \
    -d "{\"fullUrl\":\"$UPDATED_URL\"}")
test_response "PUT /urls/{slug} with valid data" "200" "$RESPONSE"

# Test 10: Update with missing fullUrl
echo -e "${BLUE}Test 10: Update with missing fullUrl${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X PUT "$API_URL/urls/$TEST_SLUG" \
    -H "Content-Type: application/json" \
    -d "{}")
test_response "PUT /urls/{slug} missing fullUrl" "400" "$RESPONSE"

# Test 11: Update with invalid URL format
echo -e "${BLUE}Test 11: Update with invalid URL${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X PUT "$API_URL/urls/$TEST_SLUG" \
    -H "Content-Type: application/json" \
    -d "{\"fullUrl\":\"invalid-url\"}")
test_response "PUT /urls/{slug} with invalid URL" "400" "$RESPONSE"

# Test 12: Update non-existent URL
echo -e "${BLUE}Test 12: Update non-existent URL${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X PUT "$API_URL/urls/nonexistent-slug-12345" \
    -H "Content-Type: application/json" \
    -d "{\"fullUrl\":\"$TEST_URL\"}")
test_response "PUT /urls/{slug} not found" "404" "$RESPONSE"

# Test 13: Delete existing URL
echo -e "${BLUE}Test 13: Delete existing URL${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X DELETE "$API_URL/urls/$TEST_SLUG")
test_response "DELETE /urls/{slug}" "200" "$RESPONSE"

# Test 14: Delete non-existent URL
echo -e "${BLUE}Test 14: Delete non-existent URL${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X DELETE "$API_URL/urls/nonexistent-slug-12345")
test_response "DELETE /urls/{slug} not found" "404" "$RESPONSE"

# Test 15: OPTIONS request (CORS preflight)
echo -e "${BLUE}Test 15: OPTIONS request${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X OPTIONS "$API_URL/urls")
test_response "OPTIONS /urls" "200" "$RESPONSE"

# Test 16: Invalid route
echo -e "${BLUE}Test 16: Invalid route${NC}"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET "$API_URL/invalid-route")
test_response "GET /invalid-route" "404" "$RESPONSE"

# Summary
echo ""
echo "================================="
echo -e "${YELLOW}Test Summary${NC}"
echo "================================="
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ All acceptance tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some acceptance tests failed${NC}"
    exit 1
fi
