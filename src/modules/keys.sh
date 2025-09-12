#!/bin/bash
# ADE crypt Key Management Module
# Handles key generation, rotation, and lifecycle

# Source common library
source "$(dirname "$0")/../lib/common.sh"

# Generate key
generate_key() {
    local key_name="${1:-default}"
    local key_type="${2:-symmetric}"  # symmetric or asymmetric
    local key_file="${KEYS_DIR}/${key_name}.key"
    local metadata_file="${METADATA_DIR}/${key_name}.meta"
    
    info_msg "Generating ${key_type} key: ${key_name}"
    
    if [ "${key_type}" = "asymmetric" ]; then
        # Generate RSA key pair
        openssl genrsa -out "${KEYS_DIR}/${key_name}.pem" 2048
        openssl rsa -in "${KEYS_DIR}/${key_name}.pem" -pubout -out "${KEYS_DIR}/${key_name}.pub"
        chmod 600 "${KEYS_DIR}/${key_name}.pem"
        chmod 644 "${KEYS_DIR}/${key_name}.pub"
        
        success_msg "Generated RSA key pair: ${key_name}.pem (private), ${key_name}.pub (public)"
    else
        # Generate symmetric key
        openssl rand -base64 32 > "${key_file}"
        chmod 600 "${key_file}"
        
        success_msg "Generated symmetric key: ${key_file}"
    fi
    
    # Store metadata
    cat > "${metadata_file}" << EOF
{
    "name": "${key_name}",
    "type": "${key_type}",
    "created": "$(date -Iseconds)",
    "expires": "$(date -Iseconds -d "+${KEY_EXPIRY_DAYS} days" 2>/dev/null || date -Iseconds)",
    "algorithm": "${DEFAULT_ALGORITHM}",
    "length": $([ "${key_type}" = "asymmetric" ] && echo "2048" || echo "256"),
    "status": "active"
}
EOF
    
    audit_log "KEY_GENERATED: ${key_name} (${key_type})"
    warning_msg "Key expires in ${KEY_EXPIRY_DAYS} days"
}

# List keys
list_keys() {
    info_msg "Encryption Keys:"
    echo ""
    
    for key in "${KEYS_DIR}"/*.key "${KEYS_DIR}"/*.pem; do
        [ -f "${key}" ] || continue
        local name
        name=$(basename "${key}" | sed 's/\.\(key\|pem\)$//')
        local meta_file="${METADATA_DIR}/${name}.meta"
        
        echo -e "  ${BOLD}${name}${NC}"
        
        if [ -f "${meta_file}" ]; then
            local type
            type=$(grep '"type"' "${meta_file}" | cut -d'"' -f4)
            local created
            created=$(grep '"created"' "${meta_file}" | cut -d'"' -f4)
            local expires
            expires=$(grep '"expires"' "${meta_file}" | cut -d'"' -f4)
            local status
            status=$(grep '"status"' "${meta_file}" | cut -d'"' -f4)
            
            echo "    Type:    ${type}"
            echo "    Created: ${created}"
            echo "    Expires: ${expires}"
            echo "    Status:  ${status}"
            
            # Check expiration
            local now
            now=$(date +%s)
            local exp_time
            exp_time=$(date -d "${expires}" +%s 2>/dev/null || echo "$((now + 86400))")
            
            if [ "${exp_time}" -lt "${now}" ]; then
                warning_msg "    ⚠ KEY EXPIRED"
            elif [ "${exp_time}" -lt "$((now + 604800))" ]; then  # 7 days
                warning_msg "    ⚠ Expires soon"
            fi
        else
            echo "    (no metadata)"
        fi
        echo ""
    done
}

# Rotate keys
rotate_keys() {
    info_msg "Rotating encryption keys..."
    
    # Generate new key
    local new_key="${KEYS_DIR}/default.key.new"
    openssl rand -base64 32 > "${new_key}"
    chmod 600 "${new_key}"
    
    # Re-encrypt all secrets
    local rotated=0
    for file in "${SECRETS_DIR}"/*.enc; do
        [ -f "${file}" ] || continue
        
        local temp_file="${file}.tmp"
        local name
        name=$(basename "${file}" .enc)
        
        echo "  Re-encrypting: ${name}"
        
        # Decrypt with old key, encrypt with new key
        if openssl enc -aes-256-cbc -d -in "${file}" -pass file:"${KEYS_DIR}/default.key" | \
           openssl enc -aes-256-cbc -salt -out "${temp_file}" -pass file:"${new_key}"; then
            mv "${temp_file}" "${file}"
            ((rotated++))
        else
            warning_msg "Failed to rotate: ${name}"
            rm -f "${temp_file}"
            rm -f "${new_key}"
            error_exit "Key rotation failed"
        fi
    done
    
    # Backup old key and activate new one
    local backup_name
    backup_name="default.key.$(date +%Y%m%d-%H%M%S)"
    mv "${KEYS_DIR}/default.key" "${KEYS_DIR}/${backup_name}"
    mv "${new_key}" "${KEYS_DIR}/default.key"
    
    # Update metadata
    generate_key "default" "symmetric" > /dev/null 2>&1
    
    audit_log "ROTATE_KEYS: Rotated ${rotated} secrets"
    success_msg "Keys rotated successfully (${rotated} secrets)"
    warning_msg "Old key backed up to: ${KEYS_DIR}/${backup_name}"
}

# Delete key
delete_key() {
    local key_name="$1"
    
    [ -z "${key_name}" ] && error_exit "Please specify key name"
    [ "${key_name}" = "default" ] && error_exit "Cannot delete default key"
    
    local key_file="${KEYS_DIR}/${key_name}.key"
    local pem_file="${KEYS_DIR}/${key_name}.pem"
    local pub_file="${KEYS_DIR}/${key_name}.pub"
    local meta_file="${METADATA_DIR}/${key_name}.meta"
    
    if [ ! -f "${key_file}" ] && [ ! -f "${pem_file}" ]; then
        error_exit "Key not found: ${key_name}"
    fi
    
    if confirm_action "Delete key '${key_name}'?"; then
        # Securely delete key files
        [ -f "${key_file}" ] && shred -vzu "${key_file}" 2>/dev/null
        [ -f "${pem_file}" ] && shred -vzu "${pem_file}" 2>/dev/null
        [ -f "${pub_file}" ] && rm -f "${pub_file}"
        [ -f "${meta_file}" ] && rm -f "${meta_file}"
        
        audit_log "DELETE_KEY: ${key_name}"
        success_msg "Key deleted: ${key_name}"
    else
        echo "Cancelled"
    fi
}

# Export key
export_key() {
    local key_name="$1"
    local output="${2:-${key_name}.export}"
    
    [ -z "${key_name}" ] && error_exit "Please specify key name"
    
    local key_file="${KEYS_DIR}/${key_name}.key"
    local pub_file="${KEYS_DIR}/${key_name}.pub"
    
    if [ -f "${pub_file}" ]; then
        # Export public key
        cp "${pub_file}" "${output}"
        success_msg "Exported public key: ${output}"
    elif [ -f "${key_file}" ]; then
        if confirm_action "Export private key '${key_name}'? This is sensitive!"; then
            cp "${key_file}" "${output}"
            chmod 600 "${output}"
            warning_msg "Exported private key: ${output} (KEEP SECURE!)"
        fi
    else
        error_exit "Key not found: ${key_name}"
    fi
    
    audit_log "EXPORT_KEY: ${key_name} -> ${output}"
}

# Import key
import_key() {
    local input="$1"
    local key_name="${2:-imported}"
    
    [ -f "${input}" ] || error_exit "File not found: ${input}"
    
    local dest_file="${KEYS_DIR}/${key_name}.key"
    
    if [ -f "${dest_file}" ]; then
        confirm_action "Key '${key_name}' exists. Overwrite?" || return
    fi
    
    cp "${input}" "${dest_file}"
    chmod 600 "${dest_file}"
    
    # Create metadata
    generate_key "${key_name}" "symmetric" > /dev/null 2>&1
    
    audit_log "IMPORT_KEY: ${input} -> ${key_name}"
    success_msg "Key imported: ${key_name}"
}

# Check key health
check_health() {
    info_msg "Key Health Check:"
    echo ""
    
    local total=0
    local expired=0
    local expiring_soon=0
    local now
    now=$(date +%s)
    
    for meta_file in "${METADATA_DIR}"/*.meta; do
        [ -f "${meta_file}" ] || continue
        
        local name
        name=$(grep '"name"' "${meta_file}" | cut -d'"' -f4)
        local expires
        expires=$(grep '"expires"' "${meta_file}" | cut -d'"' -f4)
        local exp_time
        exp_time=$(date -d "${expires}" +%s 2>/dev/null || echo "$((now + 86400))")
        
        ((total++))
        
        if [ "${exp_time}" -lt "${now}" ]; then
            ((expired++))
            echo "  ✗ ${name}: EXPIRED"
        elif [ "${exp_time}" -lt "$((now + 604800))" ]; then  # 7 days
            ((expiring_soon++))
            echo "  ⚠ ${name}: Expires soon"
        else
            echo "  ✓ ${name}: Healthy"
        fi
    done
    
    echo ""
    echo "Summary:"
    echo "  Total keys: ${total}"
    [ "${expired}" -gt 0 ] && warning_msg "  Expired: ${expired}"
    [ "${expiring_soon}" -gt 0 ] && warning_msg "  Expiring soon: ${expiring_soon}"
    
    if [ "${expired}" -gt 0 ] || [ "${expiring_soon}" -gt 0 ]; then
        echo ""
        warning_msg "Consider rotating keys with: $(basename "$0") rotate"
    fi
}

# Main execution
case "${1:-}" in
    generate)
        shift
        generate_key "$@"
        ;;
    list)
        list_keys
        ;;
    rotate)
        rotate_keys
        ;;
    delete)
        shift
        delete_key "$@"
        ;;
    export)
        shift
        export_key "$@"
        ;;
    import)
        shift
        import_key "$@"
        ;;
    health)
        check_health
        ;;
    *)
        echo "Usage: $(basename "$0") {generate|list|rotate|delete|export|import|health} [options]"
        exit 1
        ;;
esac