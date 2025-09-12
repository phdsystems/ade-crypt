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
    echo -e "${YELLOW}ShellCheck is not installed${NC}"
    echo -n "Would you like to install it now? (y/n): "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Installing ShellCheck...${NC}"
        
        # Detect OS and install accordingly
        if [ -f /etc/debian_version ]; then
            # Debian/Ubuntu
            if command -v sudo >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y shellcheck
            else
                echo -e "${RED}Error: sudo is required to install ShellCheck${NC}"
                exit 1
            fi
        elif [ -f /etc/redhat-release ]; then
            # RHEL/CentOS/Fedora
            if command -v sudo >/dev/null 2>&1; then
                sudo yum install -y ShellCheck || sudo dnf install -y ShellCheck
            else
                echo -e "${RED}Error: sudo is required to install ShellCheck${NC}"
                exit 1
            fi
        elif [ "$(uname)" = "Darwin" ]; then
            # macOS
            if command -v brew >/dev/null 2>&1; then
                brew install shellcheck
            else
                echo -e "${RED}Error: Homebrew is required to install ShellCheck on macOS${NC}"
                echo "Install Homebrew from: https://brew.sh"
                exit 1
            fi
        else
            echo -e "${RED}Error: Unsupported operating system${NC}"
            echo "Please install ShellCheck manually from: https://github.com/koalaman/shellcheck"
            exit 1
        fi
        
        # Verify installation
        if command -v shellcheck >/dev/null 2>&1; then
            echo -e "${GREEN}✓ ShellCheck installed successfully${NC}"
            echo ""
        else
            echo -e "${RED}Error: ShellCheck installation failed${NC}"
            exit 1
        fi
    else
        echo -e "${RED}ShellCheck is required to run lint checks${NC}"
        echo "Install manually with:"
        echo "  Ubuntu/Debian: sudo apt-get install shellcheck"
        echo "  macOS:         brew install shellcheck"
        echo "  Or download from: https://github.com/koalaman/shellcheck"
        exit 1
    fi
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