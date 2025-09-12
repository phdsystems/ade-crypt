#!/bin/bash
# Run all tests and generate coverage report

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Running All ADE crypt Tests${NC}"
echo "================================"

# Track totals
total_tests=0
passed_tests=0
failed_tests=0

# Find all test files
test_files=$(find tests -name "*.bats" -type f | sort)

for test_file in $test_files; do
    echo -e "\n${CYAN}Testing: ${test_file}${NC}"
    
    # Run test and capture result
    if output=$(bats "$test_file" 2>&1); then
        test_count=$(echo "$output" | grep -c "^ok" || true)
        passed_tests=$((passed_tests + test_count))
        total_tests=$((total_tests + test_count))
        echo -e "${GREEN}✓ All $test_count tests passed${NC}"
    else
        # Parse test results
        ok_count=$(echo "$output" | grep -c "^ok" || true)
        not_ok_count=$(echo "$output" | grep -c "^not ok" || true)
        
        passed_tests=$((passed_tests + ok_count))
        failed_tests=$((failed_tests + not_ok_count))
        total_tests=$((total_tests + ok_count + not_ok_count))
        
        echo -e "${YELLOW}⚠ $ok_count passed, $not_ok_count failed${NC}"
        
        # Show failed test names
        echo "$output" | grep "^not ok" | while read -r line; do
            echo -e "  ${RED}✗ ${line#not ok }${NC}"
        done
    fi
done

echo -e "\n================================"
echo -e "${CYAN}Test Summary${NC}"
echo -e "Total Tests: $total_tests"
echo -e "${GREEN}Passed: $passed_tests${NC}"
echo -e "${RED}Failed: $failed_tests${NC}"

if [ $failed_tests -eq 0 ]; then
    echo -e "\n${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}✗ Some tests failed${NC}"
    exit 1
fi
