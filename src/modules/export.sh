#!/bin/bash
# ADE crypt Export/Import Module
# Handles various export and import formats

# Source common library
source "$(dirname "$0")/../lib/common.sh"

# Export secrets in various formats
export_secrets() {
    local format="${1:-json}"
    
    info_msg "Exporting secrets as: ${format}"
    
    case "${format}" in
        json)
            echo "{"
            local first=true
            for file in "${SECRETS_DIR}"/*.enc; do
                [ -f "${file}" ] || continue
                local name
                name=$(basename "${file}" .enc)
                local value
                value=$("${MODULES_DIR}/secrets.sh" get "${name}" 2>/dev/null)
                
                [ "${first}" = true ] && first=false || echo ","
                echo -n "  \"${name}\": \"${value}\""
            done
            echo ""
            echo "}"
            ;;
            
        yaml)
            echo "secrets:"
            for file in "${SECRETS_DIR}"/*.enc; do
                [ -f "${file}" ] || continue
                local name
                name=$(basename "${file}" .enc)
                local value
                value=$("${MODULES_DIR}/secrets.sh" get "${name}" 2>/dev/null)
                echo "  ${name}: \"${value}\""
            done
            ;;
            
        env)
            for file in "${SECRETS_DIR}"/*.enc; do
                [ -f "${file}" ] || continue
                local name
                name=$(basename "${file}" .enc | tr '[:lower:]' '[:upper:]' | tr '-' '_')
                local value
                value=$("${MODULES_DIR}/secrets.sh" get "$(basename "${file}" .enc)" 2>/dev/null)
                echo "export ${name}=\"${value}\""
            done
            ;;
            
        docker)
            echo "#!/bin/bash"
            echo "# Docker secrets creation script"
            for file in "${SECRETS_DIR}"/*.enc; do
                [ -f "${file}" ] || continue
                local name
                name=$(basename "${file}" .enc)
                local value
                value=$("${MODULES_DIR}/secrets.sh" get "${name}" 2>/dev/null)
                echo "echo '${value}' | docker secret create ${name} -"
            done
            ;;
            
        k8s|kubernetes)
            echo "apiVersion: v1"
            echo "kind: Secret"
            echo "metadata:"
            echo "  name: ade-secrets"
            echo "  namespace: default"
            echo "type: Opaque"
            echo "data:"
            for file in "${SECRETS_DIR}"/*.enc; do
                [ -f "${file}" ] || continue
                local name
                name=$(basename "${file}" .enc)
                local value
                value=$("${MODULES_DIR}/secrets.sh" get "${name}" 2>/dev/null | base64 -w0)
                echo "  ${name}: ${value}"
            done
            ;;
            
        csv)
            echo "name,value,category,tags"
            for file in "${SECRETS_DIR}"/*.enc; do
                [ -f "${file}" ] || continue
                local name
                name=$(basename "${file}" .enc)
                local value
                value=$("${MODULES_DIR}/secrets.sh" get "${name}" 2>/dev/null)
                local meta_file="${METADATA_DIR}/secret_${name}.meta"
                
                if [ -f "${meta_file}" ]; then
                    local category
                    category=$(grep '"category"' "${meta_file}" | cut -d'"' -f4)
                    local tags
                    tags=$(grep '"tags"' "${meta_file}" | cut -d'"' -f4)
                    echo "\"${name}\",\"${value}\",\"${category}\",\"${tags}\""
                else
                    echo "\"${name}\",\"${value}\",\"\",\"\""
                fi
            done
            ;;
            
        *)
            error_exit "Unknown format: ${format} (supported: json, yaml, env, docker, k8s, csv)"
            ;;
    esac
    
    audit_log "EXPORT: format=${format}"
}

# Import secrets from file
import_secrets() {
    local file="$1"
    local format="${2:-auto}"
    
    [ -f "${file}" ] || error_exit "File not found: ${file}"
    
    info_msg "Importing secrets from: ${file}"
    
    # Auto-detect format
    if [ "${format}" = "auto" ]; then
        if grep -q "^{" "${file}"; then
            format="json"
        elif grep -q "^secrets:" "${file}"; then
            format="yaml"
        elif grep -q "^export " "${file}"; then
            format="env"
        elif grep -q "^name,value" "${file}"; then
            format="csv"
        else
            error_exit "Cannot detect format. Please specify: json, yaml, env, or csv"
        fi
    fi
    
    verbose_output "Detected format: ${format}"
    
    case "${format}" in
        json)
            while IFS= read -r line; do
                if [[ "${line}" =~ \"([^\"]+)\":\ *\"([^\"]+)\" ]]; then
                    local name="${BASH_REMATCH[1]}"
                    local value="${BASH_REMATCH[2]}"
                    echo "${value}" | "${MODULES_DIR}/secrets.sh" store "${name}"
                fi
            done < "${file}"
            ;;
            
        yaml)
            while IFS= read -r line; do
                if [[ "${line}" =~ ^[[:space:]]+([^:]+):\ *\"?([^\"]*)\"? ]]; then
                    local name="${BASH_REMATCH[1]}"
                    local value="${BASH_REMATCH[2]}"
                    echo "${value}" | "${MODULES_DIR}/secrets.sh" store "${name}"
                fi
            done < "${file}"
            ;;
            
        env)
            while IFS= read -r line; do
                if [[ "${line}" =~ ^export\ +([A-Z_]+)=\"(.*)\" ]]; then
                    local name
                    name=$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
                    local value="${BASH_REMATCH[2]}"
                    echo "${value}" | "${MODULES_DIR}/secrets.sh" store "${name}"
                fi
            done < "${file}"
            ;;
            
        csv)
            local header=true
            while IFS=, read -r name value category tags; do
                if [ "${header}" = true ]; then
                    header=false
                    continue
                fi
                # Remove quotes
                name="${name%\"}"
                name="${name#\"}"
                value="${value%\"}"
                value="${value#\"}"
                category="${category%\"}"
                category="${category#\"}"
                tags="${tags%\"}"
                tags="${tags#\"}"
                
                echo "${value}" | "${MODULES_DIR}/secrets.sh" store "${name}" "${category}" "${tags}"
            done < "${file}"
            ;;
            
        *)
            error_exit "Unknown format: ${format}"
            ;;
    esac
    
    audit_log "IMPORT: ${file} (format: ${format})"
    success_msg "Secrets imported"
}

# Generate QR code
share_qr() {
    local name="$1"
    
    [ -z "${name}" ] && error_exit "Please specify secret name"
    
    local value
    value=$("${MODULES_DIR}/secrets.sh" get "${name}")
    
    if command -v qrencode >/dev/null 2>&1; then
        info_msg "QR code for: ${name}"
        echo "${value}" | qrencode -t UTF8
        audit_log "SHARE_QR: ${name}"
    else
        warning_msg "qrencode not installed. Install with: apt-get install qrencode"
        info_msg "Secret value:"
        echo "${value}"
    fi
}

# Main execution
case "${1:-}" in
    export)
        shift
        export_secrets "$@"
        ;;
    import)
        shift
        import_secrets "$@"
        ;;
    share)
        shift
        share_qr "$@"
        ;;
    *)
        echo "Usage: $(basename "$0") {export|import|share} [options]"
        echo ""
        echo "Export formats: json, yaml, env, docker, k8s, csv"
        echo "Import formats: json, yaml, env, csv (or auto)"
        exit 1
        ;;
esac