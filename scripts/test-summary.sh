#!/bin/bash
# Quick test summary for ADE crypt

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${CYAN}ADE crypt Test Coverage Summary${NC}"
echo "================================"

# Count test files
test_count=$(find tests -name "*.bats" -type f 2>/dev/null | wc -l)
echo -e "Total test files: $test_count"

# Count script files
script_count=$(find scripts -name "*.sh" -type f 2>/dev/null | wc -l)
echo -e "Total script files: $script_count"

# Count source modules
module_count=$(find src -name "*.sh" -type f 2>/dev/null | wc -l)
echo -e "Total source modules: $module_count"

echo ""
echo -e "${CYAN}Test Files Created:${NC}"
find tests -name "*.bats" -type f 2>/dev/null | while read -r file; do
    test_count=$(grep -c "^@test" "$file" 2>/dev/null || echo 0)
    echo -e "  $(basename "$file"): $test_count tests"
done

echo ""
echo -e "${CYAN}Coverage Status:${NC}"

# Check which scripts have tests
for script in scripts/*.sh; do
    script_name=$(basename "$script" .sh)
    test_file="tests/scripts/${script_name}.bats"
    
    if [ -f "$test_file" ]; then
        echo -e "  ${GREEN}✓${NC} $script_name"
    else
        echo -e "  ${RED}✗${NC} $script_name (no tests)"
    fi
done

echo ""
echo -e "${CYAN}Module Coverage:${NC}"

# Check which modules have tests
for module in src/modules/*.sh; do
    module_name=$(basename "$module" .sh)
    test_file="tests/modules/${module_name}.bats"
    
    if [ -f "$test_file" ]; then
        echo -e "  ${GREEN}✓${NC} $module_name"
    else
        echo -e "  ${RED}✗${NC} $module_name (no tests)"
    fi
done

echo ""
echo -e "${GREEN}✓ Test coverage infrastructure complete!${NC}"
echo -e "Run 'make test' to execute all tests"
echo -e "Run 'make coverage' for detailed coverage report"
