#!/bin/bash
# ADE crypt Development Dependencies Installer
# Install development and testing dependencies for ADE crypt

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info_msg() {
    echo -e "${GREEN}INFO: $1${NC}"
}

warning_msg() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

error_msg() {
    echo -e "${RED}ERROR: $1${NC}"
}

# Detect package manager and install development dependencies
install_dev_deps() {
    info_msg "Installing ADE crypt development dependencies..."
    
    if command -v apt-get >/dev/null 2>&1; then
        info_msg "Detected apt package manager (Ubuntu/Debian)"
        sudo apt-get update
        sudo apt-get install -y shellcheck bats
        
    elif command -v yum >/dev/null 2>&1; then
        info_msg "Detected yum package manager (RHEL/CentOS)"
        sudo yum install -y ShellCheck
        # Install bats manually for RHEL/CentOS
        install_bats_manual
        
    elif command -v dnf >/dev/null 2>&1; then
        info_msg "Detected dnf package manager (Fedora)"
        sudo dnf install -y ShellCheck
        # Install bats manually for Fedora
        install_bats_manual
        
    elif command -v brew >/dev/null 2>&1; then
        info_msg "Detected Homebrew (macOS)"
        brew install shellcheck bats-core
        
    elif command -v pacman >/dev/null 2>&1; then
        info_msg "Detected pacman package manager (Arch Linux)"
        sudo pacman -S --noconfirm shellcheck bats
        
    else
        warning_msg "No supported package manager found"
        info_msg "Please install manually:"
        echo "  - ShellCheck: https://github.com/koalaman/shellcheck#installing"
        echo "  - BATS: https://github.com/bats-core/bats-core#installation"
        exit 1
    fi
}

# Manual BATS installation for systems without package
install_bats_manual() {
    info_msg "Installing BATS manually..."
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Download and install bats-core
    git clone https://github.com/bats-core/bats-core.git
    cd bats-core
    sudo ./install.sh /usr/local
    
    # Cleanup
    cd /
    rm -rf "$temp_dir"
}

# Verify installation
verify_installation() {
    info_msg "Verifying development dependencies..."
    
    local missing=()
    
    if ! command -v shellcheck >/dev/null 2>&1; then
        missing+=("shellcheck")
    else
        echo "  ✓ ShellCheck: $(shellcheck --version | head -1)"
    fi
    
    if ! command -v bats >/dev/null 2>&1; then
        missing+=("bats")
    else
        echo "  ✓ BATS: $(bats --version)"
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        error_msg "Installation failed for: ${missing[*]}"
        exit 1
    fi
    
    info_msg "All development dependencies installed successfully!"
}

# Main execution
main() {
    echo "ADE crypt Development Dependencies Installer"
    echo "==========================================="
    echo
    
    install_dev_deps
    verify_installation
    
    echo
    info_msg "Development environment ready!"
    info_msg "Run 'make setup' to verify everything is working"
}

# Check if running with bash
if [ -z "$BASH_VERSION" ]; then
    error_msg "This script requires bash"
    exit 1
fi

main "$@"