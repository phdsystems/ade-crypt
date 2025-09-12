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
export BASE_DIR="${ADE_CRYPT_HOME:-${HOME}/.ade}"
export SECRETS_DIR="${BASE_DIR}/secrets"
export KEYS_DIR="${BASE_DIR}/keys"
export ENCRYPTED_DIR="${BASE_DIR}/encrypted"
export CONFIG_FILE="${BASE_DIR}/config"
export AUDIT_LOG="${BASE_DIR}/audit.log"
export HISTORY_FILE="${BASE_DIR}/history"
export METADATA_DIR="${BASE_DIR}/metadata"
export VERSIONS_DIR="${BASE_DIR}/versions"
export SIGNATURES_DIR="${BASE_DIR}/signatures"

# Configuration defaults
export DEFAULT_ALGORITHM="aes-256-cbc"
export DEFAULT_COMPRESSION="gzip"
export KEY_EXPIRY_DAYS=90
export SECRET_EXPIRY_DAYS=180

# Initialize directories
init_directories() {
    mkdir -p "${SECRETS_DIR}" "${KEYS_DIR}" "${ENCRYPTED_DIR}" "${METADATA_DIR}" "${VERSIONS_DIR}" "${SIGNATURES_DIR}"
    chmod 700 "${BASE_DIR}" "${SECRETS_DIR}" "${KEYS_DIR}" "${ENCRYPTED_DIR}" "${METADATA_DIR}" "${VERSIONS_DIR}" "${SIGNATURES_DIR}"
}

# Load configuration
load_config() {
    if [ -f "${CONFIG_FILE}" ]; then
        # shellcheck source=/dev/null
        source "${CONFIG_FILE}"
    else
        create_default_config
    fi
}

# Create default configuration
create_default_config() {
    cat > "${CONFIG_FILE}" << EOF
# ADE crypt Configuration
ALGORITHM="${DEFAULT_ALGORITHM}"
COMPRESSION="${DEFAULT_COMPRESSION}"
AUTO_BACKUP=1
AUDIT_ENABLED=1
KEY_EXPIRY_DAYS=${KEY_EXPIRY_DAYS}
SECRET_EXPIRY_DAYS=${SECRET_EXPIRY_DAYS}
VERBOSE=0
QUIET=0
PROGRESS=0
EOF
    chmod 600 "${CONFIG_FILE}"
}

# Audit logging
audit_log() {
    if [ "${AUDIT_ENABLED:-1}" -eq 1 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "${AUDIT_LOG}"
    fi
}

# Verbose output
verbose_output() {
    if [ "${VERBOSE:-0}" -eq 1 ] && [ "${QUIET:-0}" -eq 0 ]; then
        echo -e "${BLUE}[VERBOSE] ${1}${NC}"
    fi
}

# Error handling
error_exit() {
    echo -e "${RED}Error: ${1}${NC}" >&2
    exit 1
}

# Success message
success_msg() {
    echo -e "${GREEN}✓ ${1}${NC}"
}

# Warning message
warning_msg() {
    echo -e "${YELLOW}⚠ ${1}${NC}"
}

# Info message
info_msg() {
    echo -e "${CYAN}${1}${NC}"
}

# Progress indicator
show_progress() {
    if [ "${PROGRESS:-0}" -eq 1 ] && [ "${QUIET:-0}" -eq 0 ]; then
        local file="$1"
        local size
        size=$(stat -f%z "${file}" 2>/dev/null || stat -c%s "${file}" 2>/dev/null || echo "0")
        local size_mb=$((size / 1048576))
        echo -e "${CYAN}Processing: ${file} (${size_mb}MB)${NC}"
    fi
}

# Check dependencies
check_dependency() {
    local cmd="$1"
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        error_exit "${cmd} is required but not installed"
    fi
}

# Check all required dependencies
check_required_dependencies() {
    local missing=()
    
    # Core runtime dependencies
    command -v openssl >/dev/null 2>&1 || missing+=("openssl")
    command -v tar >/dev/null 2>&1 || missing+=("tar")
    command -v gzip >/dev/null 2>&1 || missing+=("gzip")
    command -v sha256sum >/dev/null 2>&1 || missing+=("sha256sum")
    
    # Optional dependencies with graceful fallback
    if ! command -v gpg >/dev/null 2>&1; then
        warning_msg "GPG not found - password-based encryption will be unavailable"
    fi
    
    if ! command -v bzip2 >/dev/null 2>&1; then
        warning_msg "bzip2 not found - bzip2 compression will be unavailable"
    fi
    
    if ! command -v xz >/dev/null 2>&1; then
        warning_msg "xz not found - xz compression will be unavailable"
    fi
    
    # Report missing required dependencies
    if [ ${#missing[@]} -gt 0 ]; then
        error_exit "Missing required dependencies: ${missing[*]}\nInstall with: sudo apt-get install ${missing[*]}"
    fi
    
    verbose_output "All required dependencies satisfied"
}

# Confirmation prompt
confirm_action() {
    local message="$1"
    echo -ne "${YELLOW}${message} (y/n): ${NC}"
    read -r response
    [[ "${response}" =~ ^[Yy]$ ]]
}

# Add to history
add_history() {
    echo "$(date -Iseconds) $1" >> "${HISTORY_FILE}"
}

# Common utility functions (consolidated from modules)

# Calculate file checksum
calculate_checksum() {
    local file="$1"
    [ -f "${file}" ] || error_exit "Cannot calculate checksum: file not found: ${file}"
    sha256sum "${file}" | cut -d' ' -f1
}

# Verify file checksum
verify_checksum() {
    local file="$1"
    local expected_checksum="$2"
    local actual_checksum
    actual_checksum=$(calculate_checksum "${file}")
    [ "${expected_checksum}" = "${actual_checksum}" ]
}

# Get metadata field from JSON file
get_metadata_field() {
    local meta_file="$1"
    local field="$2"
    [ -f "${meta_file}" ] || return 1
    grep "\"${field}\"" "${meta_file}" | cut -d'"' -f4
}

# File validation helpers
require_file() {
    local file="$1"
    local message="${2:-File not found: ${file}}"
    [ -f "${file}" ] || error_exit "${message}"
}

require_key_file() {
    local key_file="$1"
    [ -f "${key_file}" ] || error_exit "Key not found: ${key_file}. Generate with: ade-crypt keys generate"
}

require_secret() {
    local secret_name="$1"
    local secret_file="${SECRETS_DIR}/${secret_name}"
    [ -f "${secret_file}" ] || error_exit "Secret not found: ${secret_name}. Store with: ade-crypt secrets store ${secret_name}"
}

# Date helpers
get_current_iso_date() {
    date -Iseconds
}

get_expiry_date() {
    local days="${1:-90}"
    date -Iseconds -d "+${days} days" 2>/dev/null || date -Iseconds
}

# OpenSSL wrapper functions
encrypt_with_key() {
    local input="$1"
    local output="$2"
    local key_file="$3"
    require_file "${input}"
    require_key_file "${key_file}"
    openssl enc -aes-256-cbc -salt -in "${input}" -out "${output}" -pass file:"${key_file}"
}

decrypt_with_key() {
    local input="$1"
    local output="$2"
    local key_file="$3"
    require_file "${input}"
    require_key_file "${key_file}"
    openssl enc -aes-256-cbc -d -in "${input}" -out "${output}" -pass file:"${key_file}"
}

# Secure file deletion
secure_delete() {
    local file="$1"
    if [ -f "${file}" ]; then
        if command -v shred >/dev/null 2>&1; then
            shred -vzu "${file}" 2>/dev/null || rm -f "${file}"
        else
            # Overwrite with random data if shred not available
            dd if=/dev/urandom of="${file}" bs=1024 count=$(du -k "${file}" | cut -f1) 2>/dev/null
            rm -f "${file}"
        fi
        verbose_output "Securely deleted: ${file}"
    fi
}

# Create secret metadata
create_secret_metadata() {
    local name="$1"
    local category="${2:-general}"
    local tags="$3"
    local expiry_days="${4:-${SECRET_EXPIRY_DAYS}}"
    local checksum="$5"
    local file="$6"
    
    cat > "${file}" << EOF
{
    "name": "${name}",
    "created": "$(get_current_iso_date)",
    "modified": "$(get_current_iso_date)",
    "expires": "$(get_expiry_date "${expiry_days}")",
    "category": "${category}",
    "tags": "${tags}",
    "checksum": "${checksum}"
}
EOF
}

# Create key metadata
create_key_metadata() {
    local name="$1"
    local key_type="${2:-default}"
    local expiry_days="${3:-${KEY_EXPIRY_DAYS}}"
    local file="$4"
    
    cat > "${file}" << EOF
{
    "name": "${name}",
    "type": "${key_type}", 
    "created": "$(get_current_iso_date)",
    "expires": "$(get_expiry_date "${expiry_days}")",
    "algorithm": "${DEFAULT_ALGORITHM}"
}
EOF
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
export -f check_required_dependencies
export -f confirm_action
export -f add_history

# Export consolidated utility functions
export -f calculate_checksum
export -f verify_checksum
export -f get_metadata_field
export -f require_file
export -f require_key_file
export -f require_secret
export -f get_current_iso_date
export -f get_expiry_date
export -f encrypt_with_key
export -f decrypt_with_key
export -f secure_delete
export -f create_secret_metadata
export -f create_key_metadata