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
    echo -e "${RED}Error: Base URL is required${NC}"
    echo "Usage: $0 <base-url>"
    echo "Example: $0 https://api-id.execute-api.us-east-1.amazonaws.com/prod"
    exit 1
fi

BASE_URL="$1"
TEST_SLUG="test-$(date +%s)"
TEST_URL="https://example.com"
UPDATED_URL="https://updated-example.com"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}API Validation Tests${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "Base URL: ${YELLOW}${BASE_URL}${NC}"
echo ""

# Track test results
PASSED=0
FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local expected_status="$2"
    shift 2
    local curl_args=("$@")
    
    echo -e "${YELLOW}Testing: ${test_name}${NC}"
    
    # Run curl and capture status code and body
    response=$(curl -s -w "\n%{http_code}" "${curl_args[@]}")
    body=$(echo "$response" | sed '$d')
    status=$(echo "$response" | tail -n 1)
    
    if [ "$status" = "$expected_status" ]; then
        echo -e "${GREEN}✓ PASSED${NC} (Status: $status)"
        PASSED=$((PASSED + 1))
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
    else
        echo -e "${RED}✗ FAILED${NC} (Expected: $expected_status, Got: $status)"
        FAILED=$((FAILED + 1))
        echo "$body"
    fi
    echo ""
}

# Test 1: OPTIONS request (CORS preflight)
run_test "OPTIONS /urls - CORS preflight" "200" \
    -X OPTIONS \
    "${BASE_URL}/urls"

# Test 2: GET /urls - List URLs (should be empty or have existing URLs)
run_test "GET /urls - List all URLs" "200" \
    -X GET \
    "${BASE_URL}/urls"

# Test 3: POST /urls - Create new shortened URL
run_test "POST /urls - Create shortened URL" "201" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"slug\":\"${TEST_SLUG}\",\"fullUrl\":\"${TEST_URL}\"}" \
    "${BASE_URL}/urls"

# Test 4: POST /urls - Try to create duplicate slug (should fail with 409)
run_test "POST /urls - Create duplicate slug (should fail)" "409" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"slug\":\"${TEST_SLUG}\",\"fullUrl\":\"${TEST_URL}\"}" \
    "${BASE_URL}/urls"

# Test 5: POST /urls - Invalid URL format (should fail with 400)
run_test "POST /urls - Invalid URL format (should fail)" "400" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"slug\":\"invalid-test\",\"fullUrl\":\"not-a-url\"}" \
    "${BASE_URL}/urls"

# Test 6: POST /urls - Missing slug (should fail with 400)
run_test "POST /urls - Missing slug (should fail)" "400" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"fullUrl\":\"${TEST_URL}\"}" \
    "${BASE_URL}/urls"

# Test 7: POST /urls - Missing fullUrl (should fail with 400)
run_test "POST /urls - Missing fullUrl (should fail)" "400" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"slug\":\"missing-url-test\"}" \
    "${BASE_URL}/urls"

# Test 8: GET /urls/{slug} - Redirect to full URL
echo -e "${YELLOW}Testing: GET /urls/{slug} - Redirect to full URL${NC}"
redirect_response=$(curl -s -o /dev/null -w "%{http_code}|%{redirect_url}" "${BASE_URL}/urls/${TEST_SLUG}")
redirect_status=$(echo "$redirect_response" | cut -d'|' -f1)
redirect_url=$(echo "$redirect_response" | cut -d'|' -f2)

# Normalize URLs by removing trailing slashes for comparison
normalized_redirect=$(echo "$redirect_url" | sed 's:/*$::')
normalized_expected=$(echo "$TEST_URL" | sed 's:/*$::')

if [ "$redirect_status" = "302" ] && [ "$normalized_redirect" = "$normalized_expected" ]; then
    echo -e "${GREEN}✓ PASSED${NC} (Status: 302, Location: $redirect_url)"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAILED${NC} (Expected: 302 with Location: $TEST_URL, Got: $redirect_status with Location: $redirect_url)"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 9: GET /urls/{slug} - Non-existent slug (should fail with 404)
run_test "GET /urls/{slug} - Non-existent slug (should fail)" "404" \
    -X GET \
    "${BASE_URL}/urls/nonexistent-slug-12345"

# Test 10: PUT /urls/{slug} - Update existing URL
run_test "PUT /urls/{slug} - Update existing URL" "200" \
    -X PUT \
    -H "Content-Type: application/json" \
    -d "{\"fullUrl\":\"${UPDATED_URL}\"}" \
    "${BASE_URL}/urls/${TEST_SLUG}"

# Test 11: PUT /urls/{slug} - Update non-existent slug (should fail with 404)
run_test "PUT /urls/{slug} - Update non-existent slug (should fail)" "404" \
    -X PUT \
    -H "Content-Type: application/json" \
    -d "{\"fullUrl\":\"${TEST_URL}\"}" \
    "${BASE_URL}/urls/nonexistent-slug-12345"

# Test 12: PUT /urls/{slug} - Invalid URL format (should fail with 400)
run_test "PUT /urls/{slug} - Invalid URL format (should fail)" "400" \
    -X PUT \
    -H "Content-Type: application/json" \
    -d "{\"fullUrl\":\"not-a-url\"}" \
    "${BASE_URL}/urls/${TEST_SLUG}"

# Test 13: PUT /urls/{slug} - Missing fullUrl (should fail with 400)
run_test "PUT /urls/{slug} - Missing fullUrl (should fail)" "400" \
    -X PUT \
    -H "Content-Type: application/json" \
    -d "{}" \
    "${BASE_URL}/urls/${TEST_SLUG}"

# Test 14: GET /urls - Verify updated URL is in list
run_test "GET /urls - Verify updated URL in list" "200" \
    -X GET \
    "${BASE_URL}/urls"

# Test 15: DELETE /urls/{slug} - Delete the test URL
run_test "DELETE /urls/{slug} - Delete test URL" "200" \
    -X DELETE \
    "${BASE_URL}/urls/${TEST_SLUG}"

# Test 16: DELETE /urls/{slug} - Try to delete again (should fail with 404)
run_test "DELETE /urls/{slug} - Delete non-existent slug (should fail)" "404" \
    -X DELETE \
    "${BASE_URL}/urls/${TEST_SLUG}"

# Test 17: GET /urls/{slug} - Verify deleted URL returns 404
run_test "GET /urls/{slug} - Verify deleted URL (should fail)" "404" \
    -X GET \
    "${BASE_URL}/urls/${TEST_SLUG}"

# Summary
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}Passed: ${PASSED}${NC}"
echo -e "${RED}Failed: ${FAILED}${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
