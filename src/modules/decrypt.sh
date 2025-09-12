#!/bin/bash
# ADE crypt Decryption Module
# Handles file and directory decryption operations

# Source common library
source "$(dirname "$0")/../lib/common.sh"

# Cleanup function for trap
cleanup_decrypt() {
    local exit_code=$?
    if [ -n "${TEMP_FILES:-}" ]; then
        for temp_file in ${TEMP_FILES}; do
            if [ -f "${temp_file}" ]; then
                shred -vzu "${temp_file}" 2>/dev/null || rm -f "${temp_file}"
            fi
        done
    fi
    exit ${exit_code}
}

# Set trap for cleanup
trap cleanup_decrypt EXIT INT TERM

# Track temp files for cleanup
TEMP_FILES=""

# Decompression wrapper
decompress_data() {
    local compression_type="${1:-gzip}"
    
    case "${compression_type}" in
        gzip)  gzip -dc ;;
        bzip2) bzip2 -dc ;;
        xz)    xz -dc ;;
        none)  cat ;;
        *)     error_exit "Unknown compression: ${compression_type}" ;;
    esac
}

# Basic file decryption
decrypt_file() {
    local input_file="$1"
    local output_file="${2:-${input_file%.enc}}"
    local key_file="${3:-${KEYS_DIR}/default.key}"
    local compression="${4:-none}"
    
    [ -f "${input_file}" ] || error_exit "File not found: ${input_file}"
    [ -f "${key_file}" ] || error_exit "Key not found: ${key_file}"
    
    show_progress "${input_file}"
    info_msg "Decrypting: ${input_file}"
    
    # Decrypt and decompress
    if openssl enc -aes-256-cbc -d -in "${input_file}" -pass file:"${key_file}" | \
        decompress_data "${compression}" > "${output_file}"; then
        # Verify checksum if exists
        if [ -f "${input_file}.sha256" ]; then
            local expected
            expected=$(cat "${input_file}.sha256")
            local actual
            actual=$(sha256sum "${output_file}" | cut -d' ' -f1)
            
            if [ "${expected}" = "${actual}" ]; then
                success_msg "Checksum verified"
            else
                shred -vzu "${output_file}" 2>/dev/null || rm -f "${output_file}"
                error_exit "Checksum mismatch!"
            fi
        fi
        
        audit_log "DECRYPT: ${input_file} -> ${output_file}"
        add_history "DECRYPT ${input_file}"
        success_msg "Decrypted: ${output_file}"
        return 0
    else
        error_exit "Decryption failed"
    fi
}

# Password-based decryption
decrypt_password() {
    local input_file="$1"
    local output_file="${2:-${input_file%.enc}}"
    local compression="${3:-gzip}"
    
    [ -f "${input_file}" ] || error_exit "File not found: ${input_file}"
    
    info_msg "Password-based decryption: ${input_file}"
    
    if gpg --decrypt "${input_file}" | decompress_data "${compression}" > "${output_file}"; then
        audit_log "DECRYPT_PASSWORD: ${input_file} -> ${output_file}"
        success_msg "Decrypted with password: ${output_file}"
        return 0
    else
        error_exit "Password decryption failed"
    fi
}

# Two-factor decryption
decrypt_two_factor() {
    local input_file="$1"
    local output_file="${2:-${input_file%.2fa.enc}}"
    local key_file="${3:-${KEYS_DIR}/default.key}"
    
    [ -f "${input_file}" ] || error_exit "File not found: ${input_file}"
    [ -f "${key_file}" ] || error_exit "Key not found: ${key_file}"
    
    info_msg "Two-factor decryption: ${input_file}"
    
    # First pass: password-based
    local temp_file
    temp_file=$(mktemp /tmp/2fa_temp_XXXXXX.enc) || error_exit "Failed to create temp file"
    TEMP_FILES="${TEMP_FILES} ${temp_file}"
    warning_msg "Enter password for first factor:"
    gpg --decrypt --output "${temp_file}" "${input_file}"
    
    # Second pass: key-based
    if openssl enc -aes-256-cbc -d -in "${temp_file}" -out "${output_file}" -pass file:"${key_file}"; then
        # Cleanup
        shred -vzu "${temp_file}" 2>/dev/null || rm -f "${temp_file}"
        audit_log "2FA_DECRYPT: ${input_file} -> ${output_file}"
        success_msg "Two-factor decryption complete"
        return 0
    else
        error_exit "Two-factor decryption failed"
    fi
}

# Stream decryption
decrypt_stream() {
    local key_file="${1:-${KEYS_DIR}/default.key}"
    local use_password="${2:-false}"
    
    verbose_output "Stream decrypting from stdin"
    audit_log "STREAM_DECRYPT: stdin"
    
    if [ "${use_password}" = "true" ]; then
        gpg --decrypt
    else
        [ -f "${key_file}" ] || error_exit "Key not found: ${key_file}"
        openssl enc -aes-256-cbc -d -pass file:"${key_file}"
    fi
}

# Multi-recipient decryption
decrypt_multi() {
    local input_file="$1"
    local key_name="$2"
    local output_file="${3:-${input_file%.multi.enc}}"
    
    [ -f "${input_file}.data" ] || error_exit "Encrypted data not found: ${input_file}.data"
    [ -f "${input_file}.key.${key_name}" ] || error_exit "Encrypted key not found for: ${key_name}"
    
    info_msg "Multi-recipient decryption: ${input_file}"
    
    # Decrypt session key
    local session_key_file
    session_key_file=$(mktemp /tmp/session_XXXXXX.key) || error_exit "Failed to create temp file"
    TEMP_FILES="${TEMP_FILES} ${session_key_file}"
    local private_key="${KEYS_DIR}/${key_name}.pem"
    
    [ -f "${private_key}" ] || error_exit "Private key not found: ${private_key}"
    
    openssl rsautl -decrypt -inkey "${private_key}" \
        -in "${input_file}.key.${key_name}" -out "${session_key_file}"
    
    # Decrypt file with session key
    if openssl enc -aes-256-cbc -d -in "${input_file}.data" -out "${output_file}" \
        -pass file:"${session_key_file}"; then
        # Cleanup
        shred -vzu "${session_key_file}" 2>/dev/null || rm -f "${session_key_file}"
        audit_log "MULTI_DECRYPT: ${input_file} -> ${output_file}"
        success_msg "Multi-recipient decryption complete"
        return 0
    else
        error_exit "Multi-recipient decryption failed"
    fi
}

# Directory decryption
decrypt_directory() {
    local input="$1"
    local output_dir="${2:-.}"
    local key_file="${3:-${KEYS_DIR}/default.key}"
    
    [ -f "${input}" ] || error_exit "File not found: ${input}"
    [ -f "${key_file}" ] || error_exit "Key not found: ${key_file}"
    
    info_msg "Decrypting directory archive: ${input}"
    
    # Decrypt and extract
    if openssl enc -aes-256-cbc -d -in "${input}" -pass file:"${key_file}" | \
        tar xzf - -C "${output_dir}"; then
        audit_log "DECRYPT_DIR: ${input} -> ${output_dir}"
        success_msg "Directory decrypted to: ${output_dir}"
        return 0
    else
        error_exit "Directory decryption failed"
    fi
}

# Verify signature
verify_signature() {
    local file="$1"
    local sig_file="${file}.sig"
    
    [ -f "${file}" ] || error_exit "File not found: ${file}"
    [ -f "${sig_file}" ] || error_exit "Signature not found: ${sig_file}"
    
    info_msg "Verifying signature: ${file}"
    
    if gpg --verify "${sig_file}" "${file}"; then
        audit_log "VERIFY: ${file} - VALID"
        success_msg "Signature valid"
        return 0
    else
        audit_log "VERIFY: ${file} - INVALID"
        error_exit "Signature invalid"
    fi
}

# Main execution
case "${1:-}" in
    file)
        shift
        decrypt_file "$@"
        ;;
    password)
        shift
        decrypt_password "$@"
        ;;
    two-factor|2fa)
        shift
        decrypt_two_factor "$@"
        ;;
    stream)
        shift
        decrypt_stream "$@"
        ;;
    multi)
        shift
        decrypt_multi "$@"
        ;;
    directory|dir)
        shift
        decrypt_directory "$@"
        ;;
    verify)
        shift
        verify_signature "$@"
        ;;
    *)
        echo "Usage: $(basename "$0") {file|password|two-factor|stream|multi|directory|verify} [options]"
        exit 1
        ;;
esac