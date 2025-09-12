#!/bin/bash
# Linting script for ADE-Crypt
# Runs ShellCheck on all bash scripts

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

echo -e "${CYAN}Running ShellCheck linting...${NC}"
echo ""

# Check if shellcheck is installed
if ! command -v shellcheck >/dev/null 2>&1; then
    echo -e "${RED}Error: ShellCheck is not installed${NC}"
    echo "Install with:"
    echo "  Ubuntu/Debian: sudo apt-get install shellcheck"
    echo "  macOS:         brew install shellcheck"
    echo "  Or download from: https://github.com/koalaman/shellcheck"
    exit 1
fi

# Find all shell scripts
SCRIPTS=()

# Main executables
SCRIPTS+=("ade-crypt")
SCRIPTS+=("bin/ade-crypt")
SCRIPTS+=("install.sh")

# Source files
while IFS= read -r -d '' file; do
    SCRIPTS+=("$file")
done < <(find src -name "*.sh" -print0)

# Lint scripts
TOTAL=0
PASSED=0
FAILED=0

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo -n "Checking $script... "
        ((TOTAL++))
        
        if shellcheck "$script"; then
            echo -e "${GREEN}✓ PASSED${NC}"
            ((PASSED++))
        else
            echo -e "${RED}✗ FAILED${NC}"
            ((FAILED++))
        fi
    fi
done

echo ""
echo "Results:"
echo -e "  Total:  $TOTAL"
echo -e "  ${GREEN}Passed: $PASSED${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ $FAILED checks failed${NC}"
    exit 1
fi