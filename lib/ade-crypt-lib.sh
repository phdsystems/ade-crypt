#!/bin/bash
# ADE crypt Library - Standalone Version
# Single-file library for external projects
# Version: 2.1.0

# Prevent multiple sourcing
if [[ -n "$ADE_CRYPT_LIB_LOADED" ]]; then
    return 0
fi
export ADE_CRYPT_LIB_LOADED=1

# Library metadata
export ADE_CRYPT_LIB_VERSION="2.1.0"
export ADE_CRYPT_LIB_NAME="ADE crypt Library"

# Colors for output
export ADE_GREEN='\033[0;32m'
export ADE_YELLOW='\033[1;33m' 
export ADE_CYAN='\033[0;36m'
export ADE_RED='\033[0;31m'
export ADE_NC='\033[0m'
export ADE_BOLD='\033[1m'

# Configuration
export ADE_LIB_HOME="${ADE_CRYPT_HOME:-$HOME/.ade}"
export ADE_LIB_QUIET="${ADE_LIB_QUIET:-0}"
export ADE_LIB_DEBUG="${ADE_LIB_DEBUG:-0}"

# === CORE FUNCTIONS ===

# Initialize library
ade_init() {
    local base_dir="$ADE_LIB_HOME"
    mkdir -p "$base_dir"/{secrets,keys,encrypted,metadata}
    chmod 700 "$base_dir"/{secrets,keys,encrypted,metadata}
    
    if [[ "$ADE_LIB_DEBUG" == "1" ]]; then
        echo -e "${ADE_CYAN}[ADE-LIB] Initialized: $base_dir${ADE_NC}" >&2
    fi
}

# Message functions
ade_success() {
    [[ "$ADE_LIB_QUIET" == "1" ]] || echo -e "${ADE_GREEN}✓ $1${ADE_NC}"
}

ade_error() {
    echo -e "${ADE_RED}✗ $1${ADE_NC}" >&2
    return 1
}

ade_warn() {
    [[ "$ADE_LIB_QUIET" == "1" ]] || echo -e "${ADE_YELLOW}⚠ $1${ADE_NC}" >&2
}

ade_debug() {
    [[ "$ADE_LIB_DEBUG" == "1" ]] && echo -e "${ADE_CYAN}[DEBUG] $1${ADE_NC}" >&2
}

# Dependency check
ade_check_deps() {
    local missing=()
    
    command -v openssl >/dev/null 2>&1 || missing+=("openssl")
    command -v sha256sum >/dev/null 2>&1 || missing+=("sha256sum")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        ade_error "Missing dependencies: ${missing[*]}"
        return 1
    fi
    
    ade_debug "Dependencies satisfied"
    return 0
}

# === ENCRYPTION FUNCTIONS ===

# Generate encryption key
ade_generate_key() {
    local key_name="${1:-default}"
    local key_file="$ADE_LIB_HOME/keys/${key_name}.key"
    
    ade_check_deps || return 1
    ade_init
    
    # Generate 256-bit key
    openssl rand -base64 32 > "$key_file"
    chmod 600 "$key_file"
    
    ade_success "Generated key: $key_name"
    ade_debug "Key file: $key_file"
    echo "$key_file"
}

# Encrypt file with key
ade_encrypt_file() {
    local input_file="$1"
    local output_file="${2:-$1.enc}"
    local key_name="${3:-default}"
    local key_file="$ADE_LIB_HOME/keys/${key_name}.key"
    
    # Validation
    [[ -f "$input_file" ]] || { ade_error "Input file not found: $input_file"; return 1; }
    ade_check_deps || return 1
    ade_init
    
    # Auto-generate key if missing
    if [[ ! -f "$key_file" ]]; then
        ade_warn "Key not found, generating: $key_name"
        ade_generate_key "$key_name" >/dev/null
    fi
    
    # Encrypt
    if openssl enc -aes-256-cbc -salt -in "$input_file" -out "$output_file" -pass file:"$key_file" 2>/dev/null; then
        ade_success "Encrypted: $input_file → $output_file"
        ade_debug "Used key: $key_name"
        echo "$output_file"
    else
        ade_error "Encryption failed"
        return 1
    fi
}

# Decrypt file with key
ade_decrypt_file() {
    local input_file="$1"
    local output_file="$2"
    local key_name="${3:-default}"
    local key_file="$ADE_LIB_HOME/keys/${key_name}.key"
    
    # Auto-detect output filename
    if [[ -z "$output_file" ]]; then
        if [[ "$input_file" == *.enc ]]; then
            output_file="${input_file%.enc}"
        else
            output_file="$input_file.decrypted"
        fi
    fi
    
    # Validation
    [[ -f "$input_file" ]] || { ade_error "Input file not found: $input_file"; return 1; }
    [[ -f "$key_file" ]] || { ade_error "Key not found: $key_name ($key_file)"; return 1; }
    ade_check_deps || return 1
    
    # Decrypt
    if openssl enc -aes-256-cbc -d -in "$input_file" -out "$output_file" -pass file:"$key_file" 2>/dev/null; then
        ade_success "Decrypted: $input_file → $output_file"
        ade_debug "Used key: $key_name"
        echo "$output_file"
    else
        ade_error "Decryption failed"
        return 1
    fi
}

# === SECRET MANAGEMENT ===

# Store secret
ade_store_secret() {
    local name="$1"
    local value="$2"
    local key_name="${3:-default}"
    
    [[ -n "$name" ]] || { ade_error "Secret name required"; return 1; }
    [[ -n "$value" ]] || { ade_error "Secret value required"; return 1; }
    
    ade_init
    local secret_file="$ADE_LIB_HOME/secrets/${name}.enc"
    
    # Store secret
    if echo "$value" | ade_encrypt_file /dev/stdin "$secret_file" "$key_name" >/dev/null; then
        ade_success "Stored secret: $name"
        return 0
    else
        ade_error "Failed to store secret: $name"
        return 1
    fi
}

# Get secret
ade_get_secret() {
    local name="$1"
    local key_name="${2:-default}"
    
    [[ -n "$name" ]] || { ade_error "Secret name required"; return 1; }
    
    local secret_file="$ADE_LIB_HOME/secrets/${name}.enc"
    [[ -f "$secret_file" ]] || { ade_error "Secret not found: $name"; return 1; }
    
    # Decrypt and output
    if ade_decrypt_file "$secret_file" /dev/stdout "$key_name" 2>/dev/null; then
        ade_debug "Retrieved secret: $name"
        return 0
    else
        ade_error "Failed to retrieve secret: $name"
        return 1
    fi
}

# List secrets
ade_list_secrets() {
    local secrets_dir="$ADE_LIB_HOME/secrets"
    
    if [[ ! -d "$secrets_dir" ]]; then
        ade_warn "No secrets directory found"
        return 0
    fi
    
    local count=0
    for file in "$secrets_dir"/*.enc; do
        if [[ -f "$file" ]]; then
            local name=$(basename "$file" .enc)
            echo "$name"
            ((count++))
        fi
    done 2>/dev/null
    
    ade_debug "Found $count secrets"
}

# === UTILITY FUNCTIONS ===

# Calculate file checksum
ade_checksum() {
    local file="$1"
    [[ -f "$file" ]] || { ade_error "File not found: $file"; return 1; }
    sha256sum "$file" | cut -d' ' -f1
}

# Verify file checksum
ade_verify_checksum() {
    local file="$1"
    local expected="$2"
    local actual=$(ade_checksum "$file")
    
    if [[ "$actual" == "$expected" ]]; then
        ade_success "Checksum verified: $file"
        return 0
    else
        ade_error "Checksum mismatch: $file"
        ade_debug "Expected: $expected"
        ade_debug "Actual:   $actual"
        return 1
    fi
}

# List keys
ade_list_keys() {
    local keys_dir="$ADE_LIB_HOME/keys"
    
    if [[ ! -d "$keys_dir" ]]; then
        ade_warn "No keys directory found"
        return 0
    fi
    
    local count=0
    for file in "$keys_dir"/*.key; do
        if [[ -f "$file" ]]; then
            local name=$(basename "$file" .key)
            echo "$name"
            ((count++))
        fi
    done 2>/dev/null
    
    ade_debug "Found $count keys"
}

# Library info
ade_lib_info() {
    echo "Library: $ADE_CRYPT_LIB_NAME"
    echo "Version: $ADE_CRYPT_LIB_VERSION"
    echo "Home:    $ADE_LIB_HOME"
    echo "Loaded:  $(date)"
}

# === INITIALIZATION ===

# Auto-initialize on load
ade_init

# Export main functions for external use
export -f ade_init
export -f ade_generate_key
export -f ade_encrypt_file
export -f ade_decrypt_file
export -f ade_store_secret
export -f ade_get_secret
export -f ade_list_secrets
export -f ade_list_keys
export -f ade_checksum
export -f ade_verify_checksum
export -f ade_success
export -f ade_error
export -f ade_warn
export -f ade_debug
export -f ade_lib_info

# Success message
ade_debug "ADE crypt Library v$ADE_CRYPT_LIB_VERSION loaded"