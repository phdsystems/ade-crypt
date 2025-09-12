#!/bin/bash
# ADE crypt Encryption Module
# Handles file and directory encryption operations

# Source common library
source "$(dirname "$0")/../lib/common.sh"

# Compression wrapper
compress_data() {
    local compression_type="${1:-gzip}"
    
    case "$compression_type" in
        gzip)  gzip -c ;;
        bzip2) bzip2 -c ;;
        xz)    xz -c ;;
        none)  cat ;;
        *)     error_exit "Unknown compression: $compression_type" ;;
    esac
}

# Basic file encryption
encrypt_file() {
    local input_file="$1"
    local output_file="${2:-${input_file}.enc}"
    local key_file="${3:-$KEYS_DIR/default.key}"
    local compression="${4:-none}"
    
    [ -f "$input_file" ] || error_exit "File not found: $input_file"
    
    # Generate key if missing
    if [ ! -f "$key_file" ]; then
        warning_msg "No key found, generating default key..."
        "$MODULES_DIR/keys.sh" generate
    fi
    
    show_progress "$input_file"
    info_msg "Encrypting: $input_file"
    
    # Calculate checksum
    local checksum=$(sha256sum "$input_file" | cut -d' ' -f1)
    echo "$checksum" > "${output_file}.sha256"
    
    # Encrypt with compression
    compress_data "$compression" < "$input_file" | \
        openssl enc -aes-256-cbc -salt -out "$output_file" -pass file:"$key_file"
    
    if [ $? -eq 0 ]; then
        audit_log "ENCRYPT: $input_file -> $output_file"
        add_history "ENCRYPT $input_file"
        success_msg "Encrypted: $output_file"
        return 0
    else
        error_exit "Encryption failed"
    fi
}

# Password-based encryption
encrypt_password() {
    local input_file="$1"
    local output_file="${2:-${input_file}.enc}"
    local compression="${3:-gzip}"
    
    [ -f "$input_file" ] || error_exit "File not found: $input_file"
    
    info_msg "Password-based encryption: $input_file"
    
    compress_data "$compression" < "$input_file" | \
        gpg --symmetric --cipher-algo AES256 --output "$output_file"
    
    if [ $? -eq 0 ]; then
        audit_log "ENCRYPT_PASSWORD: $input_file -> $output_file"
        success_msg "Encrypted with password: $output_file"
        return 0
    else
        error_exit "Password encryption failed"
    fi
}

# Two-factor encryption
encrypt_two_factor() {
    local input_file="$1"
    local output_file="${2:-${input_file}.2fa.enc}"
    local key_file="${3:-$KEYS_DIR/default.key}"
    
    [ -f "$input_file" ] || error_exit "File not found: $input_file"
    
    info_msg "Two-factor encryption: $input_file"
    
    # First pass: key-based
    local temp_file="/tmp/2fa_temp_$$.enc"
    openssl enc -aes-256-cbc -salt -in "$input_file" -out "$temp_file" -pass file:"$key_file"
    
    # Second pass: password-based
    warning_msg "Enter password for second factor:"
    gpg --symmetric --cipher-algo AES256 --output "$output_file" "$temp_file"
    
    # Cleanup
    shred -vzu "$temp_file" 2>/dev/null || rm -f "$temp_file"
    
    if [ $? -eq 0 ]; then
        audit_log "2FA_ENCRYPT: $input_file -> $output_file"
        success_msg "Two-factor encryption complete"
        return 0
    else
        error_exit "Two-factor encryption failed"
    fi
}

# Stream encryption
encrypt_stream() {
    local key_file="${1:-$KEYS_DIR/default.key}"
    local use_password="${2:-false}"
    
    if [ ! -f "$key_file" ] && [ "$use_password" != "true" ]; then
        warning_msg "No key found, generating default key..."
        "$MODULES_DIR/keys.sh" generate
        key_file="$KEYS_DIR/default.key"
    fi
    
    verbose_output "Stream encrypting from stdin"
    audit_log "STREAM_ENCRYPT: stdin"
    
    if [ "$use_password" = "true" ]; then
        gpg --symmetric --cipher-algo AES256 --armor
    else
        openssl enc -aes-256-cbc -salt -pass file:"$key_file"
    fi
}

# Multi-recipient encryption
encrypt_multi() {
    local input_file="$1"
    local recipients="$2"
    local output_file="${3:-${input_file}.multi.enc}"
    
    [ -f "$input_file" ] || error_exit "File not found: $input_file"
    [ -z "$recipients" ] && error_exit "No recipients specified"
    
    info_msg "Multi-recipient encryption: $input_file"
    verbose_output "Recipients: $recipients"
    
    # Create session key
    local session_key=$(openssl rand -hex 32)
    local session_key_file="/tmp/session_$$.key"
    echo "$session_key" > "$session_key_file"
    
    # Encrypt file with session key
    openssl enc -aes-256-cbc -salt -in "$input_file" -out "${output_file}.data" \
        -pass file:"$session_key_file"
    
    # Encrypt session key for each recipient
    IFS=',' read -ra KEYS <<< "$recipients"
    for key in "${KEYS[@]}"; do
        key=$(echo "$key" | xargs)  # Trim whitespace
        if [ -f "$KEYS_DIR/$key" ]; then
            openssl rsautl -encrypt -inkey "$KEYS_DIR/$key" -pubin \
                -in "$session_key_file" -out "${output_file}.key.${key}"
            success_msg "Encrypted for: $key"
        else
            warning_msg "Key not found: $key"
        fi
    done
    
    # Cleanup
    shred -vzu "$session_key_file" 2>/dev/null || rm -f "$session_key_file"
    
    audit_log "MULTI_ENCRYPT: $input_file for ${#KEYS[@]} recipients"
    success_msg "Multi-recipient encryption complete"
}

# Directory encryption
encrypt_directory() {
    local dir="$1"
    local output="${2:-${dir}.tar.enc}"
    local key_file="${3:-$KEYS_DIR/default.key}"
    
    [ -d "$dir" ] || error_exit "Directory not found: $dir"
    
    info_msg "Encrypting directory: $dir"
    
    # Create tar archive and encrypt
    tar czf - "$dir" | openssl enc -aes-256-cbc -salt -out "$output" -pass file:"$key_file"
    
    if [ $? -eq 0 ]; then
        audit_log "ENCRYPT_DIR: $dir -> $output"
        success_msg "Directory encrypted: $output"
        return 0
    else
        error_exit "Directory encryption failed"
    fi
}

# Main execution
case "${1:-}" in
    file)
        shift
        encrypt_file "$@"
        ;;
    password)
        shift
        encrypt_password "$@"
        ;;
    two-factor|2fa)
        shift
        encrypt_two_factor "$@"
        ;;
    stream)
        shift
        encrypt_stream "$@"
        ;;
    multi)
        shift
        encrypt_multi "$@"
        ;;
    directory|dir)
        shift
        encrypt_directory "$@"
        ;;
    *)
        echo "Usage: $(basename "$0") {file|password|two-factor|stream|multi|directory} [options]"
        exit 1
        ;;
esac