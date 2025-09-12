#!/bin/bash
# ADE crypt Common Library
# Shared functions and variables for all modules

# Version
export VERSION="2.1.0"
export PRODUCT_NAME="ADE crypt"
export PRODUCT_DESCRIPTION="Agentic Development Environment encryption utility"

# Colors
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export CYAN='\033[0;36m'
export RED='\033[0;31m'
export MAGENTA='\033[0;35m'
export BLUE='\033[0;34m'
export NC='\033[0m'
export BOLD='\033[1m'

# Default paths
export BASE_DIR="${ADE_CRYPT_HOME:-$HOME/.ade}"
export SECRETS_DIR="$BASE_DIR/secrets"
export KEYS_DIR="$BASE_DIR/keys"
export ENCRYPTED_DIR="$BASE_DIR/encrypted"
export CONFIG_FILE="$BASE_DIR/config"
export AUDIT_LOG="$BASE_DIR/audit.log"
export HISTORY_FILE="$BASE_DIR/history"
export METADATA_DIR="$BASE_DIR/metadata"
export VERSIONS_DIR="$BASE_DIR/versions"
export SIGNATURES_DIR="$BASE_DIR/signatures"

# Configuration defaults
export DEFAULT_ALGORITHM="aes-256-cbc"
export DEFAULT_COMPRESSION="gzip"
export KEY_EXPIRY_DAYS=90
export SECRET_EXPIRY_DAYS=180

# Initialize directories
init_directories() {
    mkdir -p "$SECRETS_DIR" "$KEYS_DIR" "$ENCRYPTED_DIR" "$METADATA_DIR" "$VERSIONS_DIR" "$SIGNATURES_DIR"
    chmod 700 "$BASE_DIR" "$SECRETS_DIR" "$KEYS_DIR" "$ENCRYPTED_DIR" "$METADATA_DIR" "$VERSIONS_DIR" "$SIGNATURES_DIR"
}

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        create_default_config
    fi
}

# Create default configuration
create_default_config() {
    cat > "$CONFIG_FILE" << EOF
# ADE-Crypt Configuration
ALGORITHM="$DEFAULT_ALGORITHM"
COMPRESSION="$DEFAULT_COMPRESSION"
AUTO_BACKUP=1
AUDIT_ENABLED=1
KEY_EXPIRY_DAYS=$KEY_EXPIRY_DAYS
SECRET_EXPIRY_DAYS=$SECRET_EXPIRY_DAYS
VERBOSE=0
QUIET=0
PROGRESS=0
EOF
    chmod 600 "$CONFIG_FILE"
}

# Audit logging
audit_log() {
    if [ "${AUDIT_ENABLED:-1}" -eq 1 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$AUDIT_LOG"
    fi
}

# Verbose output
verbose_output() {
    if [ "${VERBOSE:-0}" -eq 1 ] && [ "${QUIET:-0}" -eq 0 ]; then
        echo -e "${BLUE}[VERBOSE] $1${NC}"
    fi
}

# Error handling
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Success message
success_msg() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Warning message
warning_msg() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Info message
info_msg() {
    echo -e "${CYAN}$1${NC}"
}

# Progress indicator
show_progress() {
    if [ "${PROGRESS:-0}" -eq 1 ] && [ "${QUIET:-0}" -eq 0 ]; then
        local file="$1"
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        local size_mb=$((size / 1048576))
        echo -e "${CYAN}Processing: $file (${size_mb}MB)${NC}"
    fi
}

# Check dependencies
check_dependency() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        error_exit "$cmd is required but not installed"
    fi
}

# Confirmation prompt
confirm_action() {
    local message="$1"
    echo -ne "${YELLOW}$message (y/n): ${NC}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

# Add to history
add_history() {
    echo "$(date -Iseconds) $1" >> "$HISTORY_FILE"
}

# Export functions
export -f init_directories
export -f load_config
export -f audit_log
export -f verbose_output
export -f error_exit
export -f success_msg
export -f warning_msg
export -f info_msg
export -f show_progress
export -f check_dependency
export -f confirm_action
export -f add_history