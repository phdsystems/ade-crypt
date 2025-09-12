#!/bin/bash
# Test runner script for ADE-Crypt
# Runs BATS tests with proper setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${CYAN}ADE-Crypt Test Suite${NC}"
echo ""

# Check dependencies
echo "Checking test dependencies..."

if ! command -v bats >/dev/null 2>&1; then
    echo -e "${RED}Error: BATS is not installed${NC}"
    echo "Install with:"
    echo "  Ubuntu/Debian: sudo apt-get install bats"
    echo "  macOS:         brew install bats-core"
    echo "  Manual:        git clone https://github.com/bats-core/bats-core.git && cd bats-core && sudo ./install.sh /usr/local"
    exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: OpenSSL not found, some tests may be skipped${NC}"
fi

if ! command -v gpg >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: GPG not found, password encryption tests will be skipped${NC}"
fi

echo -e "${GREEN}✓ Dependencies checked${NC}"
echo ""

# Create temporary test directory
export TEST_TMPDIR="/tmp/ade-crypt-test-$$"
mkdir -p "$TEST_TMPDIR"

cleanup() {
    echo "Cleaning up test environment..."
    rm -rf "$TEST_TMPDIR"
}
trap cleanup EXIT

# Run tests
echo -e "${CYAN}Running tests...${NC}"
echo ""

# Test options
BATS_OPTIONS=(
    --print-output-on-failure
    --show-output-of-passing-tests
)

# Add tap output for CI
if [ "${CI:-false}" = "true" ]; then
    BATS_OPTIONS+=(--tap)
fi

# Add verbose output if requested
if [ "${VERBOSE:-false}" = "true" ]; then
    BATS_OPTIONS+=(--verbose-run)
fi

# Run specific test file or all tests
if [ $# -gt 0 ]; then
    # Run specific test files
    for test_file in "$@"; do
        if [ -f "tests/$test_file" ]; then
            echo -e "${CYAN}Running $test_file...${NC}"
            bats "${BATS_OPTIONS[@]}" "tests/$test_file"
        elif [ -f "$test_file" ]; then
            echo -e "${CYAN}Running $test_file...${NC}"
            bats "${BATS_OPTIONS[@]}" "$test_file"
        else
            echo -e "${RED}Test file not found: $test_file${NC}"
            exit 1
        fi
    done
else
    # Run all tests
    echo -e "${CYAN}Running all tests...${NC}"
    bats "${BATS_OPTIONS[@]}" tests/
fi

echo ""
echo -e "${GREEN}✓ All tests completed${NC}"