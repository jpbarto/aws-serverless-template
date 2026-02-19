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
    echo ""
    echo "Example:"
    echo "  $0 https://api.example.com"
    exit 1
fi

API_URL="$1"

echo -e "${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}  URL Shortener Integration Test Suite    ${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════${NC}"
echo ""
echo "Target API: $API_URL"
echo "Started at: $(date)"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Track overall test status
OVERALL_STATUS=0

# Run acceptance tests
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Phase 1: Running Acceptance Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if bash "$SCRIPT_DIR/run-acceptance-tests.sh" "$API_URL"; then
    echo ""
    echo -e "${GREEN}✓ Acceptance tests completed successfully${NC}"
else
    echo ""
    echo -e "${RED}✗ Acceptance tests failed${NC}"
    OVERALL_STATUS=1
fi

echo ""
echo ""

# Run performance tests
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Phase 2: Running Performance Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if bash "$SCRIPT_DIR/run-performance-tests.sh" "$API_URL"; then
    echo ""
    echo -e "${GREEN}✓ Performance tests completed successfully${NC}"
else
    echo ""
    echo -e "${RED}✗ Performance tests failed${NC}"
    OVERALL_STATUS=1
fi

echo ""
echo ""

# Final summary
echo -e "${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Integration Test Suite Summary          ${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════${NC}"
echo ""
echo "Completed at: $(date)"
echo ""

if [ $OVERALL_STATUS -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                           ║${NC}"
    echo -e "${GREEN}║  ✓ ALL INTEGRATION TESTS PASSED!         ║${NC}"
    echo -e "${GREEN}║                                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                           ║${NC}"
    echo -e "${RED}║  ✗ SOME INTEGRATION TESTS FAILED          ║${NC}"
    echo -e "${RED}║                                           ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi
