#!/bin/bash
# Code coverage reporting for ADE crypt using bashcov

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

# Simple coverage analysis fallback function (define before use)
simple_coverage() {
    echo -e "${CYAN}Simple Coverage Analysis${NC}"
    echo ""
    
    # Count total lines of bash code
    local total_lines=0
    local test_lines=0
    
    # Source files
    while IFS= read -r -d '' file; do
        local lines
        lines=$(wc -l < "$file")
        total_lines=$((total_lines + lines))
        echo "  $(basename "$file"): $lines lines"
    done < <(find src -name "*.sh" -print0)
    
    # Test files
    while IFS= read -r -d '' file; do
        local lines
        lines=$(wc -l < "$file")
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

# Auto-install dependencies if missing
install_dependencies() {
    local need_install=false
    
    # Check for Ruby
    if ! command -v ruby >/dev/null 2>&1; then
        echo -e "${YELLOW}Ruby not found, attempting to install...${NC}"
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y ruby-full ruby-dev build-essential
            need_install=true
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y ruby ruby-devel gcc make
            need_install=true
        elif command -v brew >/dev/null 2>&1; then
            brew install ruby
            need_install=true
        else
            echo -e "${RED}Cannot auto-install Ruby. Please install manually.${NC}"
            return 1
        fi
    fi
    
    # Check for gem
    if ! command -v gem >/dev/null 2>&1; then
        echo -e "${RED}RubyGems not available after Ruby installation${NC}"
        return 1
    fi
    
    # Install bashcov
    if ! command -v bashcov >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing bashcov...${NC}"
        gem install bashcov --user-install
        
        # Add gem bin to PATH if needed
        local gem_bin="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin"
        if [[ ":$PATH:" != *":$gem_bin:"* ]]; then
            export PATH="$gem_bin:$PATH"
            echo -e "${CYAN}Added $gem_bin to PATH${NC}"
        fi
    fi
    
    # Install bats if missing
    if ! command -v bats >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing bats...${NC}"
        if command -v npm >/dev/null 2>&1; then
            npm install -g bats
        else
            echo -e "${YELLOW}Installing bats from source...${NC}"
            git clone https://github.com/bats-core/bats-core.git /tmp/bats-core
            cd /tmp/bats-core
            sudo ./install.sh /usr/local
            cd "$PROJECT_ROOT"
            rm -rf /tmp/bats-core
        fi
    fi
    
    return 0
}

# Check if bashcov is available
if ! command -v bashcov >/dev/null 2>&1; then
    echo -e "${YELLOW}bashcov not found, checking dependencies...${NC}"
    
    if install_dependencies; then
        # Verify bashcov is now available
        if ! command -v bashcov >/dev/null 2>&1; then
            echo -e "${YELLOW}bashcov still not found, using simple coverage...${NC}"
            simple_coverage
            exit 0
        fi
    else
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
export BASHCOV_COMMAND_NAME="ADE crypt"
bashcov --root "$PROJECT_ROOT" -- ./scripts/test.sh

# Generate HTML report
if [ -f coverage/.resultset.json ]; then
    echo -e "${GREEN}✓ Coverage report generated in coverage/index.html${NC}"
    
    # Show coverage summary
    if command -v jq >/dev/null 2>&1; then
        echo ""
        echo -e "${CYAN}Coverage Summary:${NC}"
        jq -r '.ADE crypt.coverage | keys[] as $k | "\($k): \(.[$k] | map(select(. != null)) | length)/\(.[$k] | length) lines"' coverage/.resultset.json | head -20
    fi
    
    echo ""
    echo "Open coverage/index.html in a browser to view detailed report"
else
    echo -e "${YELLOW}No coverage data generated${NC}"
fi

# Check for additional analysis tools
if command -v shellcheck >/dev/null 2>&1; then
    echo -e "${GREEN}✓ ShellCheck available for static analysis${NC}"
fi

if command -v shfmt >/dev/null 2>&1; then
    echo -e "${GREEN}✓ shfmt available for formatting${NC}"
fi