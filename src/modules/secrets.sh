#!/bin/bash
# ADE crypt Secrets Management Module
# Handles secret storage, retrieval, and management

# Source common library
source "$(dirname "$0")/../lib/common.sh"

# Cleanup function for trap
cleanup_secrets() {
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
trap cleanup_secrets EXIT INT TERM

# Track temp files for cleanup
TEMP_FILES=""

# Store secret
store_secret() {
    local name="$1"
    local category="${2:-general}"
    local tags="${3:-}"
    local expiry_days="${4:-${SECRET_EXPIRY_DAYS}}"
    
    [ -z "${name}" ] && error_exit "Please provide a secret name"
    
    local secret_file="${SECRETS_DIR}/${name}.enc"
    local metadata_file="${METADATA_DIR}/secret_${name}.meta"
    local version_file
    version_file="${VERSIONS_DIR}/${name}_$(date +%s).enc"
    local key_file="${KEYS_DIR}/default.key"
    
    # Check for key
    [ -f "${key_file}" ] || error_exit "No default key found. Run: keys.sh generate"
    
    info_msg "Enter secret value for '${name}' (press Ctrl+D when done):"
    
    # Read secret
    local secret
    secret=$(cat)
    
    # Version control - backup existing
    if [ -f "${secret_file}" ]; then
        cp "${secret_file}" "${version_file}"
        verbose_output "Backed up previous version"
    fi
    
    # Encrypt and store
    echo -n "${secret}" | openssl enc -aes-256-cbc -salt -out "${secret_file}" -pass file:"${key_file}"
    chmod 600 "${secret_file}"
    
    # Store metadata
    cat > "${metadata_file}" << EOF
{
    "name": "${name}",
    "created": "$(date -Iseconds)",
    "modified": "$(date -Iseconds)",
    "expires": "$(date -Iseconds -d "+${expiry_days} days" 2>/dev/null || date -Iseconds)",
    "category": "${category}",
    "tags": "${tags}",
    "version": "$(find "${VERSIONS_DIR}" -name "${name}_*" -type f 2>/dev/null | wc -l)",
    "checksum": "$(echo -n "${secret}" | sha256sum | cut -d' ' -f1)"
}
EOF
    
    audit_log "STORE: ${name} (category: ${category}, tags: ${tags:-none})"
    success_msg "Secret stored: ${name}"
    warning_msg "Secret expires in ${expiry_days} days"
}

# Get secret
get_secret() {
    local name="$1"
    local version="${2:-latest}"
    local secret_file="${SECRETS_DIR}/${name}.enc"
    local key_file="${KEYS_DIR}/default.key"
    
    # Handle version selection
    if [ "${version}" != "latest" ]; then
        local version_files
        mapfile -t version_files < <(find "${VERSIONS_DIR}" -name "${name}_*.enc" -type f 2>/dev/null | sort)
        if [ "${#version_files[@]}" -ge "${version}" ]; then
            secret_file="${version_files[$((version-1))]}"
        else
            error_exit "Version ${version} not found"
        fi
    fi
    
    [ -f "${secret_file}" ] || error_exit "Secret not found: ${name}"
    [ -f "${key_file}" ] || error_exit "No default key found"
    
    # Check expiration
    local metadata_file="${METADATA_DIR}/secret_${name}.meta"
    if [ -f "${metadata_file}" ]; then
        local expires
        expires=$(grep '"expires"' "${metadata_file}" | cut -d'"' -f4)
        local now
        now=$(date +%s)
        local exp_time
        exp_time=$(date -d "${expires}" +%s 2>/dev/null || echo "${now}")
        
        if [ "${exp_time}" -lt "${now}" ]; then
            error_exit "Secret has expired!"
        fi
    fi
    
    # Decrypt and output
    openssl enc -aes-256-cbc -d -in "${secret_file}" -pass file:"${key_file}"
    
    audit_log "GET: ${name} (version: ${version})"
}

# List secrets
list_secrets() {
    local detailed="${1:-false}"
    
    info_msg "Stored secrets:"
    echo ""
    
    if [ -z "$(ls -A "${SECRETS_DIR}" 2>/dev/null)" ]; then
        echo "  (none)"
        return
    fi
    
    for file in "${SECRETS_DIR}"/*.enc; do
        [ -f "${file}" ] || continue
        local name
        name=$(basename "${file}" .enc)
        
        if [ "${detailed}" = "true" ]; then
            echo -e "  ${BOLD}${name}${NC}"
            
            local meta_file="${METADATA_DIR}/secret_${name}.meta"
            if [ -f "${meta_file}" ]; then
                local created
                created=$(grep '"created"' "${meta_file}" | cut -d'"' -f4)
                local expires
                expires=$(grep '"expires"' "${meta_file}" | cut -d'"' -f4)
                local category
                category=$(grep '"category"' "${meta_file}" | cut -d'"' -f4)
                local tags
                tags=$(grep '"tags"' "${meta_file}" | cut -d'"' -f4)
                local version
                version=$(grep '"version"' "${meta_file}" | cut -d'"' -f4)
                
                echo "    Created:  ${created}"
                echo "    Expires:  ${expires}"
                echo "    Category: ${category}"
                echo "    Tags:     ${tags:-none}"
                echo "    Versions: ${version}"
            fi
            echo ""
        else
            echo "  • ${name}"
        fi
    done
}

# Search secrets
search_secrets() {
    local term="$1"
    local category="${2:-}"
    
    info_msg "Searching secrets: '${term}'"
    [ -n "${category}" ] && info_msg "Category filter: ${category}"
    echo ""
    
    local found=0
    for meta_file in "${METADATA_DIR}"/secret_*.meta; do
        [ -f "${meta_file}" ] || continue
        
        local name
        name=$(grep '"name"' "${meta_file}" | cut -d'"' -f4)
        local cat
        cat=$(grep '"category"' "${meta_file}" | cut -d'"' -f4)
        local tags
        tags=$(grep '"tags"' "${meta_file}" | cut -d'"' -f4)
        
        # Apply filters
        if [ -n "${term}" ]; then
            echo "${name} ${tags}" | grep -q "${term}" || continue
        fi
        
        if [ -n "${category}" ]; then
            [ "${cat}" = "${category}" ] || continue
        fi
        
        echo -e "  ${BOLD}${name}${NC}"
        echo "    Category: ${cat}"
        echo "    Tags: ${tags:-none}"
        echo ""
        ((found++))
    done
    
    [ "${found}" -eq 0 ] && echo "  No secrets found matching criteria"
}

# Delete secret
delete_secret() {
    local name="$1"
    local secret_file="${SECRETS_DIR}/${name}.enc"
    local metadata_file="${METADATA_DIR}/secret_${name}.meta"
    
    [ -f "${secret_file}" ] || error_exit "Secret not found: ${name}"
    
    if confirm_action "Delete secret '${name}'?"; then
        # Delete all versions
        # Use shred for version files containing encrypted secrets
        for version_file in "${VERSIONS_DIR}/${name}_"*.enc; do
            [ -f "${version_file}" ] && shred -vzu "${version_file}" 2>/dev/null
        done
        shred -vzu "${metadata_file}" 2>/dev/null || rm -f "${metadata_file}"
        
        # Securely delete secret
        shred -vzu "${secret_file}" 2>/dev/null || rm -f "${secret_file}"
        
        audit_log "DELETE: ${name}"
        success_msg "Secret deleted: ${name}"
    else
        echo "Cancelled"
    fi
}

# Set expiration
set_expiration() {
    local name="$1"
    local days="$2"
    local metadata_file="${METADATA_DIR}/secret_${name}.meta"
    
    [ -f "${SECRETS_DIR}/${name}.enc" ] || error_exit "Secret not found: ${name}"
    [ -f "${metadata_file}" ] || error_exit "No metadata found for: ${name}"
    
    # Update expiration
    local new_expires
    new_expires=$(date -Iseconds -d "+${days} days" 2>/dev/null || date -Iseconds)
    sed -i "s/\"expires\": \"[^\"]*\"/\"expires\": \"${new_expires}\"/" "${metadata_file}"
    
    audit_log "EXPIRE_SET: ${name} expires in ${days} days"
    success_msg "Expiration set: ${name} expires in ${days} days"
}

# Add tags
add_tags() {
    local name="$1"
    local tags="$2"
    local metadata_file="${METADATA_DIR}/secret_${name}.meta"
    
    [ -f "${SECRETS_DIR}/${name}.enc" ] || error_exit "Secret not found: ${name}"
    [ -f "${metadata_file}" ] || error_exit "No metadata found for: ${name}"
    
    # Update tags
    sed -i "s/\"tags\": \"[^\"]*\"/\"tags\": \"${tags}\"/" "${metadata_file}"
    
    audit_log "TAG: ${name} with '${tags}'"
    success_msg "Tags added: ${name}"
}

# Set category
set_category() {
    local name="$1"
    local category="$2"
    local metadata_file="${METADATA_DIR}/secret_${name}.meta"
    
    [ -f "${SECRETS_DIR}/${name}.enc" ] || error_exit "Secret not found: ${name}"
    [ -f "${metadata_file}" ] || error_exit "No metadata found for: ${name}"
    
    # Update category
    sed -i "s/\"category\": \"[^\"]*\"/\"category\": \"${category}\"/" "${metadata_file}"
    
    audit_log "CATEGORY: ${name} set to '${category}'"
    success_msg "Category set: ${name} -> ${category}"
}

# Clean expired
clean_expired() {
    info_msg "Cleaning expired secrets..."
    
    local cleaned=0
    local now
    now=$(date +%s)
    
    for meta_file in "${METADATA_DIR}"/secret_*.meta; do
        [ -f "${meta_file}" ] || continue
        
        local name
        name=$(grep '"name"' "${meta_file}" | cut -d'"' -f4)
        local expires
        expires=$(grep '"expires"' "${meta_file}" | cut -d'"' -f4)
        local exp_time
        exp_time=$(date -d "${expires}" +%s 2>/dev/null || echo "$((now + 86400))")
        
        if [ "${exp_time}" -lt "${now}" ]; then
            echo "  Removing expired: ${name}"
            delete_secret "${name}" <<< "y"
            ((cleaned++))
        fi
    done
    
    audit_log "CLEAN: Removed ${cleaned} expired secrets"
    success_msg "Cleaned ${cleaned} expired secrets"
}

# Main execution
case "${1:-}" in
    store)
        shift
        store_secret "$@"
        ;;
    get)
        shift
        get_secret "$@"
        ;;
    list)
        shift
        list_secrets "$@"
        ;;
    search)
        shift
        search_secrets "$@"
        ;;
    delete)
        shift
        delete_secret "$@"
        ;;
    expire)
        shift
        set_expiration "$@"
        ;;
    tag)
        shift
        add_tags "$@"
        ;;
    category)
        shift
        set_category "$@"
        ;;
    clean)
        clean_expired
        ;;
    *)
        echo "Usage: $(basename "$0") {store|get|list|search|delete|expire|tag|category|clean} [options]"
        exit 1
        ;;
esac