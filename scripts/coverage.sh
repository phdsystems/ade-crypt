#!/bin/bash
# Code coverage reporting for ADE-Crypt using bashcov

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

echo -e "${CYAN}Generating code coverage report...${NC}"
echo ""

# Check if bashcov is available
if ! command -v bashcov >/dev/null 2>&1; then
    echo -e "${YELLOW}bashcov not found, installing...${NC}"
    
    # Try to install bashcov
    if command -v gem >/dev/null 2>&1; then
        gem install bashcov
    else
        echo -e "${RED}Error: Ruby gems not available for bashcov installation${NC}"
        echo "Install bashcov manually:"
        echo "  1. Install Ruby: sudo apt-get install ruby-dev"
        echo "  2. Install bashcov: gem install bashcov"
        echo ""
        echo -e "${YELLOW}Falling back to simple coverage analysis...${NC}"
        simple_coverage
        exit 0
    fi
fi

# Clean previous coverage data
rm -rf coverage/
mkdir -p coverage/

# Run tests with coverage
echo "Running tests with coverage tracking..."
export BASHCOV_COMMAND_NAME="ADE-Crypt"
bashcov --root "$PROJECT_ROOT" -- ./scripts/test.sh

# Generate HTML report
if [ -f coverage/.resultset.json ]; then
    echo -e "${GREEN}✓ Coverage report generated in coverage/index.html${NC}"
    
    # Show coverage summary
    if command -v jq >/dev/null 2>&1; then
        echo ""
        echo -e "${CYAN}Coverage Summary:${NC}"
        jq -r '.ADE-Crypt.coverage | keys[] as $k | "\($k): \(.[$k] | map(select(. != null)) | length)/\(.[$k] | length) lines"' coverage/.resultset.json | head -20
    fi
    
    echo ""
    echo "Open coverage/index.html in a browser to view detailed report"
else
    echo -e "${YELLOW}No coverage data generated${NC}"
fi

# Simple coverage analysis fallback
simple_coverage() {
    echo -e "${CYAN}Simple Coverage Analysis${NC}"
    echo ""
    
    # Count total lines of bash code
    local total_lines=0
    local test_lines=0
    
    # Source files
    while IFS= read -r -d '' file; do
        local lines=$(wc -l < "$file")
        total_lines=$((total_lines + lines))
        echo "  $(basename "$file"): $lines lines"
    done < <(find src -name "*.sh" -print0)
    
    # Test files
    while IFS= read -r -d '' file; do
        local lines=$(wc -l < "$file")
        test_lines=$((test_lines + lines))
    done < <(find tests -name "*.bats" -print0 2>/dev/null || true)
    
    echo ""
    echo "Summary:"
    echo "  Source code: $total_lines lines"
    echo "  Test code:   $test_lines lines"
    
    if [ $test_lines -gt 0 ]; then
        local ratio=$((test_lines * 100 / total_lines))
        echo "  Test ratio:  ${ratio}%"
        
        if [ $ratio -gt 30 ]; then
            echo -e "  ${GREEN}✓ Good test coverage ratio${NC}"
        else
            echo -e "  ${YELLOW}⚠ Consider adding more tests${NC}"
        fi
    fi
}