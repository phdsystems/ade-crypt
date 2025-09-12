#!/bin/bash
# ADE-Crypt Installation Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

INSTALL_DIR="/usr/local"
SCRIPT_NAME="ade-crypt"
REPO_URL="https://github.com/phdsystems/ade-crypt"

echo -e "${GREEN}Installing ADE crypt...${NC}"

# Check for required dependencies
echo "Checking dependencies..."
for cmd in openssl tar gpg; do
    if ! command -v "${cmd}" &> /dev/null; then
        echo -e "${YELLOW}Warning: ${cmd} is recommended but not installed.${NC}"
    fi
done

# Installation method
if [ -d ".git" ] && [ -f "bin/ade-crypt" ]; then
    # Local installation from repository
    echo -e "${CYAN}Installing from local repository...${NC}"
    
    # Create installation directories
    sudo mkdir -p "${INSTALL_DIR}/lib/ade-crypt" "${INSTALL_DIR}/bin"
    
    # Copy files
    sudo cp -r src "${INSTALL_DIR}/lib/ade-crypt/"
    sudo cp bin/ade-crypt "${INSTALL_DIR}/lib/ade-crypt/"
    
    # Create executable link
    sudo ln -sf "${INSTALL_DIR}/lib/ade-crypt/ade-crypt" "${INSTALL_DIR}/bin/ade-crypt"
    
    # Fix paths in the installed script
    sudo sed -i "s|BASE_DIR=.*|BASE_DIR=\"${INSTALL_DIR}/lib/ade-crypt\"|" \
        "${INSTALL_DIR}/lib/ade-crypt/ade-crypt"
    
else
    # Download from GitHub
    echo -e "${CYAN}Downloading from GitHub...${NC}"
    
    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    cd "${TEMP_DIR}"
    
    # Download and extract
    if command -v wget &> /dev/null; then
        wget -q -O ade-crypt.tar.gz "${REPO_URL}/archive/main.tar.gz"
    elif command -v curl &> /dev/null; then
        curl -sSL -o ade-crypt.tar.gz "${REPO_URL}/archive/main.tar.gz"
    else
        echo -e "${RED}Error: Neither wget nor curl is installed.${NC}"
        exit 1
    fi
    
    tar xzf ade-crypt.tar.gz
    cd ade-crypt-main
    
    # Install files
    sudo mkdir -p "${INSTALL_DIR}/lib/ade-crypt" "${INSTALL_DIR}/bin"
    sudo cp -r src "${INSTALL_DIR}/lib/ade-crypt/"
    sudo cp bin/ade-crypt "${INSTALL_DIR}/lib/ade-crypt/"
    
    # Create executable link
    sudo ln -sf "${INSTALL_DIR}/lib/ade-crypt/ade-crypt" "${INSTALL_DIR}/bin/ade-crypt"
    
    # Fix paths
    sudo sed -i "s|BASE_DIR=.*|BASE_DIR=\"${INSTALL_DIR}/lib/ade-crypt\"|" \
        "${INSTALL_DIR}/lib/ade-crypt/ade-crypt"
    
    # Cleanup
    cd /
    rm -rf "${TEMP_DIR}"
fi

# Make everything executable
sudo chmod +x "${INSTALL_DIR}/lib/ade-crypt/ade-crypt"
sudo chmod +x "${INSTALL_DIR}/lib/ade-crypt/src/modules/"*.sh
sudo chmod +x "${INSTALL_DIR}/lib/ade-crypt/src/core/"*.sh

# Create config directory
mkdir -p ~/.ade

# Verify installation
if command -v "${SCRIPT_NAME}" &> /dev/null; then
    echo -e "${GREEN}✓ ADE crypt installed successfully!${NC}"
    echo ""
    echo -e "${CYAN}Installation location:${NC}"
    echo "  Binary:  ${INSTALL_DIR}/bin/ade-crypt"
    echo "  Library: ${INSTALL_DIR}/lib/ade-crypt/"
    echo "  Config:  ~/.ade/"
    echo ""
    echo "Run 'ade-crypt help' to get started"
else
    echo -e "${RED}Installation failed. Please check the errors above.${NC}"
    exit 1
fi