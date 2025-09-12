#!/bin/bash
# ADE-Crypt Installation Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="ade-crypt"
REPO_URL="https://raw.githubusercontent.com/phdsystems/ade-crypt/main"

echo -e "${GREEN}Installing ADE-Crypt...${NC}"

# Check for required dependencies
echo "Checking dependencies..."
for cmd in openssl tar; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: $cmd is required but not installed.${NC}"
        echo "Please install $cmd and try again."
        exit 1
    fi
done

# Download the script
echo "Downloading ade-crypt..."
if command -v wget &> /dev/null; then
    wget -q -O /tmp/$SCRIPT_NAME "$REPO_URL/$SCRIPT_NAME"
elif command -v curl &> /dev/null; then
    curl -sSL -o /tmp/$SCRIPT_NAME "$REPO_URL/$SCRIPT_NAME"
else
    echo -e "${RED}Error: Neither wget nor curl is installed.${NC}"
    exit 1
fi

# Make it executable
chmod +x /tmp/$SCRIPT_NAME

# Install to system (may require sudo)
if [ -w "$INSTALL_DIR" ]; then
    mv /tmp/$SCRIPT_NAME "$INSTALL_DIR/"
else
    echo -e "${YELLOW}Installing to $INSTALL_DIR requires sudo access${NC}"
    sudo mv /tmp/$SCRIPT_NAME "$INSTALL_DIR/"
fi

# Create config directory
mkdir -p ~/.ade-crypt

# Verify installation
if command -v $SCRIPT_NAME &> /dev/null; then
    echo -e "${GREEN}✓ ADE-Crypt installed successfully!${NC}"
    echo ""
    echo "Run 'ade-crypt --help' to get started"
else
    echo -e "${RED}Installation failed. Please check the errors above.${NC}"
    exit 1
fi