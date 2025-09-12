#!/bin/bash
# ADE crypt Dependency Checker
# Verify all required and optional dependencies are available

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info_msg() {
    echo -e "${CYAN}INFO: $1${NC}"
}

success_msg() {
    echo -e "${GREEN}✓ $1${NC}"
}

warning_msg() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

error_msg() {
    echo -e "${RED}✗ $1${NC}"
}

# Check runtime dependencies
check_runtime_deps() {
    local missing=()
    local optional_missing=()
    
    info_msg "Checking runtime dependencies..."
    
    # Required dependencies
    local required_deps=("openssl" "tar" "gzip" "sha256sum")
    for dep in "${required_deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            local version
            case "$dep" in
                openssl) version=$(openssl version | cut -d' ' -f2) ;;
                tar) version=$(tar --version | head -1 | grep -o '[0-9]\+\.[0-9]\+') ;;
                gzip) version=$(gzip --version | head -1 | grep -o '[0-9]\+\.[0-9]\+') ;;
                sha256sum) version=$(sha256sum --version | head -1 | grep -o '[0-9]\+\.[0-9]\+') ;;
                *) version="installed" ;;
            esac
            success_msg "$dep ($version)"
        else
            missing+=("$dep")
            error_msg "$dep - MISSING"
        fi
    done
    
    # Optional dependencies
    local optional_deps=("gpg" "bzip2" "xz" "aws" "gsutil" "az")
    for dep in "${optional_deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            success_msg "$dep (optional)"
        else
            optional_missing+=("$dep")
            warning_msg "$dep - optional, not installed"
        fi
    done
    
    return ${#missing[@]}
}

# Check development dependencies
check_dev_deps() {
    local missing=()
    
    info_msg "Checking development dependencies..."
    
    local dev_deps=("shellcheck" "bats" "git" "make")
    for dep in "${dev_deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            local version
            case "$dep" in
                shellcheck) version=$(shellcheck --version | grep "version:" | cut -d' ' -f2) ;;
                bats) version=$(bats --version 2>/dev/null | cut -d' ' -f3 || echo "installed") ;;
                git) version=$(git --version | cut -d' ' -f3) ;;
                make) version=$(make --version | head -1 | grep -o '[0-9]\+\.[0-9]\+') ;;
                *) version="installed" ;;
            esac
            success_msg "$dep ($version)"
        else
            missing+=("$dep")
            error_msg "$dep - MISSING"
        fi
    done
    
    return ${#missing[@]}
}

# Check system compatibility
check_system() {
    info_msg "Checking system compatibility..."
    
    # Check OS
    if [ -f /etc/os-release ]; then
        local os_name=$(grep "^NAME=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
        success_msg "OS: $os_name"
    elif [ "$(uname)" = "Darwin" ]; then
        success_msg "OS: macOS $(sw_vers -productVersion 2>/dev/null || echo "unknown")"
    else
        success_msg "OS: $(uname -s)"
    fi
    
    # Check bash version
    if [ -n "$BASH_VERSION" ]; then
        success_msg "Bash: $BASH_VERSION"
    else
        warning_msg "Not running in bash"
    fi
    
    # Check disk space in home directory
    local available_space
    if command -v df >/dev/null 2>&1; then
        available_space=$(df -h "$HOME" | tail -1 | awk '{print $4}')
        success_msg "Available space in $HOME: $available_space"
    fi
}

# Provide installation instructions
show_install_instructions() {
    local missing_runtime=("$@")
    
    if [ ${#missing_runtime[@]} -gt 0 ]; then
        echo
        info_msg "Installation instructions for missing dependencies:"
        echo
        
        echo "Ubuntu/Debian:"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install -y ${missing_runtime[*]}"
        echo
        
        echo "RHEL/CentOS/Fedora:"
        echo "  sudo yum install -y ${missing_runtime[*]}"
        echo "  # or: sudo dnf install -y ${missing_runtime[*]}"
        echo
        
        echo "macOS (Homebrew):"
        echo "  brew install ${missing_runtime[*]}"
        echo
        
        echo "Arch Linux:"
        echo "  sudo pacman -S ${missing_runtime[*]}"
    fi
}

# Main execution
main() {
    echo "ADE crypt Dependency Checker"
    echo "============================"
    echo
    
    # Check system
    check_system
    echo
    
    # Check runtime dependencies
    local runtime_missing=0
    if ! check_runtime_deps; then
        runtime_missing=$?
    fi
    echo
    
    # Check development dependencies (only if --dev flag is passed)
    local dev_missing=0
    if [ "$1" = "--dev" ] || [ "$1" = "-d" ]; then
        if ! check_dev_deps; then
            dev_missing=$?
        fi
        echo
    fi
    
    # Summary
    if [ $runtime_missing -eq 0 ]; then
        success_msg "All runtime dependencies satisfied!"
    else
        error_msg "$runtime_missing runtime dependencies missing"
        show_install_instructions
    fi
    
    if [ "$1" = "--dev" ] || [ "$1" = "-d" ]; then
        if [ $dev_missing -eq 0 ]; then
            success_msg "All development dependencies satisfied!"
        else
            error_msg "$dev_missing development dependencies missing"
            echo
            info_msg "Install development dependencies with:"
            echo "  ./scripts/install-dev-deps.sh"
        fi
    fi
    
    # Exit with error if any required dependencies are missing
    if [ $runtime_missing -gt 0 ]; then
        exit 1
    fi
    
    if [ "$1" = "--dev" ] || [ "$1" = "-d" ]; then
        if [ $dev_missing -gt 0 ]; then
            exit 1
        fi
    fi
}

# Show usage
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [--dev|-d] [--help|-h]"
    echo
    echo "Options:"
    echo "  --dev, -d    Also check development dependencies"
    echo "  --help, -h   Show this help message"
    exit 0
fi

main "$@"