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

echo -e "${YELLOW}URL Shortener Performance Tests${NC}"
echo "================================="
echo "Testing API at: $API_URL"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
    echo -e "${RED}Error: k6 is not installed${NC}"
    echo "Please install k6 from https://k6.io/docs/getting-started/installation/"
    echo ""
    echo "Quick install options:"
    echo "  macOS: brew install k6"
    echo "  Linux: sudo apt-get install k6"
    echo "  Windows: choco install k6"
    exit 1
fi

# Run k6 performance tests
echo -e "${BLUE}Running performance tests with k6...${NC}"
echo ""

if k6 run --env API_URL="$API_URL" "$SCRIPT_DIR/performance-test.js"; then
    echo ""
    echo -e "${GREEN}✓ Performance tests passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}✗ Performance tests failed${NC}"
    exit 1
fi
