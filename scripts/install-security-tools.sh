#!/bin/bash
# Install security and analysis tools for ADE crypt
# Includes secret scanners, performance tools, and code metrics

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}${BOLD}Installing Security & Analysis Tools${NC}"
echo -e "${CYAN}====================================${NC}"
echo ""

# Detect OS
OS="unknown"
if [ -f /etc/debian_version ]; then
    OS="debian"
elif [ -f /etc/redhat-release ]; then
    OS="redhat"
elif [ "$(uname)" = "Darwin" ]; then
    OS="macos"
fi

# Function to install tools based on OS
install_tool() {
    local tool=$1
    local brew_pkg=$2
    local apt_pkg=$3
    local pip_pkg=$4
    local go_pkg=$5
    
    echo -e "${CYAN}Installing ${tool}...${NC}"
    
    if command -v "${tool}" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ ${tool} already installed${NC}"
        return 0
    fi
    
    case "${OS}" in
        macos)
            if [ -n "${brew_pkg}" ] && command -v brew >/dev/null 2>&1; then
                brew install "${brew_pkg}"
            elif [ -n "${pip_pkg}" ] && command -v pip3 >/dev/null 2>&1; then
                pip3 install "${pip_pkg}"
            elif [ -n "${go_pkg}" ] && command -v go >/dev/null 2>&1; then
                go install "${go_pkg}"
            fi
            ;;
        debian)
            if [ -n "${apt_pkg}" ] && command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y "${apt_pkg}"
            elif [ -n "${pip_pkg}" ] && command -v pip3 >/dev/null 2>&1; then
                pip3 install "${pip_pkg}"
            elif [ -n "${go_pkg}" ] && command -v go >/dev/null 2>&1; then
                go install "${go_pkg}"
            fi
            ;;
        *)
            if [ -n "${pip_pkg}" ] && command -v pip3 >/dev/null 2>&1; then
                pip3 install "${pip_pkg}"
            elif [ -n "${go_pkg}" ] && command -v go >/dev/null 2>&1; then
                go install "${go_pkg}"
            else
                echo -e "${YELLOW}⚠ Cannot auto-install ${tool} on ${OS}${NC}"
            fi
            ;;
    esac
}

# Install Python if needed (for pip packages)
if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${CYAN}Installing Python 3...${NC}"
    case "${OS}" in
        macos)
            brew install python3
            ;;
        debian)
            sudo apt-get update && sudo apt-get install -y python3 python3-pip
            ;;
    esac
fi

# Install Go if needed (for Go packages)
install_go() {
    if ! command -v go >/dev/null 2>&1; then
        echo -e "${CYAN}Installing Go...${NC}"
        case "${OS}" in
            macos)
                brew install go
                ;;
            debian)
                # Install Go from official source
                GO_VERSION="1.21.5"
                wget "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
                sudo tar -C /usr/local -xzf /tmp/go.tar.gz
                echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
                export PATH=$PATH:/usr/local/go/bin
                rm /tmp/go.tar.gz
                ;;
        esac
    fi
}

echo -e "${CYAN}${BOLD}1. Secret Scanning Tools (IMPORTANT)${NC}"
echo -e "${CYAN}====================================${NC}"

# Install Gitleaks
echo -e "${CYAN}Installing Gitleaks...${NC}"
if command -v gitleaks >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Gitleaks already installed${NC}"
else
    case "${OS}" in
        macos)
            brew install gitleaks
            ;;
        debian)
            # Download latest release for Linux
            GITLEAKS_VERSION=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
            wget "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" -O /tmp/gitleaks.tar.gz
            tar -xzf /tmp/gitleaks.tar.gz -C /tmp
            sudo mv /tmp/gitleaks /usr/local/bin/
            rm /tmp/gitleaks.tar.gz
            ;;
        *)
            echo -e "${YELLOW}⚠ Please install Gitleaks manually from https://github.com/gitleaks/gitleaks${NC}"
            ;;
    esac
fi

# Install TruffleHog
install_tool "trufflehog" "" "" "truffleHog3" ""

# Create Gitleaks config
echo -e "${CYAN}Creating Gitleaks configuration...${NC}"
cat > .gitleaks.toml << 'EOF'
title = "ADE crypt Gitleaks Config"

[extend]
useDefault = true

[[rules]]
id = "encryption-key"
description = "Hardcoded encryption key"
regex = '''(?i)(encryption_key|encrypt_key|cipher_key)\s*=\s*["'][^"']{16,}["']'''
tags = ["key", "encryption"]

[[rules]]
id = "temp-file-pattern"
description = "Predictable temp file using PID"
regex = '''/tmp/[a-zA-Z_]+\$\$'''
tags = ["security", "temp"]

[[rules]]
id = "hardcoded-password"
description = "Hardcoded password"
regex = '''(?i)(password|passwd|pwd)\s*=\s*["'][^"']+["']'''
tags = ["password"]

[allowlist]
paths = [
    "tests/",
    "*.bats",
    ".gitleaks.toml"
]
EOF

echo ""
echo -e "${CYAN}${BOLD}2. Performance Analysis Tools (NICE-TO-HAVE)${NC}"
echo -e "${CYAN}==========================================${NC}"

# Install hyperfine
echo -e "${CYAN}Installing hyperfine...${NC}"
if command -v hyperfine >/dev/null 2>&1; then
    echo -e "${GREEN}✓ hyperfine already installed${NC}"
else
    case "${OS}" in
        macos)
            brew install hyperfine
            ;;
        debian)
            # Download latest release
            HYPERFINE_VERSION=$(curl -s https://api.github.com/repos/sharkdp/hyperfine/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
            wget "https://github.com/sharkdp/hyperfine/releases/download/v${HYPERFINE_VERSION}/hyperfine_${HYPERFINE_VERSION}_amd64.deb" -O /tmp/hyperfine.deb
            sudo dpkg -i /tmp/hyperfine.deb
            rm /tmp/hyperfine.deb
            ;;
        *)
            echo -e "${YELLOW}⚠ Please install hyperfine manually${NC}"
            ;;
    esac
fi

echo ""
echo -e "${CYAN}${BOLD}3. Code Metrics Tools (NICE-TO-HAVE)${NC}"
echo -e "${CYAN}===================================${NC}"

# Install scc (Sloc, Cloc and Code)
echo -e "${CYAN}Installing scc...${NC}"
if command -v scc >/dev/null 2>&1; then
    echo -e "${GREEN}✓ scc already installed${NC}"
else
    # Ensure Go is installed
    install_go
    
    if command -v go >/dev/null 2>&1; then
        go install github.com/boyter/scc/v3@latest
        # Add Go bin to PATH if not already there
        if [[ ":$PATH:" != *":$(go env GOPATH)/bin:"* ]]; then
            echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
            export PATH=$PATH:$(go env GOPATH)/bin
        fi
    else
        echo -e "${YELLOW}⚠ Go required for scc. Install Go first.${NC}"
    fi
fi

# Install shellcheck if not present
install_tool "shellcheck" "shellcheck" "shellcheck" "" ""

echo ""
echo -e "${CYAN}${BOLD}4. Additional Security Tools${NC}"
echo -e "${CYAN}===========================${NC}"

# Install semgrep
echo -e "${CYAN}Installing semgrep...${NC}"
if command -v semgrep >/dev/null 2>&1; then
    echo -e "${GREEN}✓ semgrep already installed${NC}"
else
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install semgrep
    else
        echo -e "${YELLOW}⚠ Python pip required for semgrep${NC}"
    fi
fi

echo ""
echo -e "${GREEN}${BOLD}Installation Summary${NC}"
echo -e "${GREEN}===================${NC}"

# Check what's installed
echo -e "\n${CYAN}Installed Tools:${NC}"
for tool in gitleaks trufflehog hyperfine scc shellcheck semgrep; do
    if command -v "${tool}" >/dev/null 2>&1; then
        version=$("${tool}" --version 2>&1 | head -1 || echo "installed")
        echo -e "  ${GREEN}✓${NC} ${tool}: ${version}"
    else
        echo -e "  ${RED}✗${NC} ${tool}: not installed"
    fi
done

echo ""
echo -e "${CYAN}${BOLD}Next Steps:${NC}"
echo "1. Run security audit: ./scripts/security-audit.sh"
echo "2. Run performance tests: ./scripts/performance-test.sh"
echo "3. Check code metrics: scc src/"
echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"