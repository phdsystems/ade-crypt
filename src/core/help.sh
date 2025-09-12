#!/bin/bash
# ADE crypt Help System
# Provides help and documentation

# Get base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${BASE_DIR}/src/lib/common.sh"

# Show version
show_version() {
    echo "${PRODUCT_NAME} v${VERSION}"
    echo "${PRODUCT_DESCRIPTION}"
}

# Show main help
show_help() {
    echo -e "${BOLD}${CYAN}${PRODUCT_NAME} v${VERSION}${NC}"
    echo ""
    echo "Usage: ade-crypt <module> <command> [options]"
    echo ""
    echo -e "${BOLD}Modules:${NC}"
    echo "  encrypt     File and directory encryption"
    echo "  decrypt     File and directory decryption"
    echo "  secrets     Secret management"
    echo "  keys        Key management"
    echo "  export      Export/import operations"
    echo "  backup      Backup and cloud sync"
    echo ""
    echo -e "${BOLD}Quick Commands:${NC}"
    echo "  ade-crypt encrypt file <filename>"
    echo "  ade-crypt decrypt file <filename>"
    echo "  ade-crypt secrets store <name>"
    echo "  ade-crypt secrets get <name>"
    echo "  ade-crypt keys generate"
    echo "  ade-crypt backup create"
    echo ""
    echo -e "${BOLD}Module Help:${NC}"
    echo "  ade-crypt <module> help"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  # Encrypt a file with compression"
    echo "  ade-crypt encrypt file -c gzip document.pdf"
    echo ""
    echo "  # Store a secret with metadata"
    echo "  ade-crypt secrets store api-key --category prod --tags critical"
    echo ""
    echo "  # Export secrets as environment variables"
    echo "  ade-crypt export export env > .env"
    echo ""
    echo "  # Create backup and push to cloud"
    echo "  ade-crypt backup create && ade-crypt backup push"
    echo ""
    echo -e "${BOLD}Configuration:${NC}"
    echo "  Config file: ~/.ade/config"
    echo "  Audit log:   ~/.ade/audit.log"
    echo ""
    echo -e "${BOLD}For more information:${NC}"
    echo "  Documentation: https://github.com/phdsystems/ade-crypt"
    echo "  Issues:        https://github.com/phdsystems/ade-crypt/issues"
}

# Show module-specific help
show_module_help() {
    local module="$1"
    
    case "${module}" in
        encrypt)
            echo -e "${BOLD}Encryption Module${NC}"
            echo ""
            echo "Commands:"
            echo "  file       Encrypt a file"
            echo "  password   Password-based encryption"
            echo "  two-factor Two-factor encryption (key + password)"
            echo "  stream     Stream encryption (stdin/stdout)"
            echo "  multi      Multi-recipient encryption"
            echo "  directory  Encrypt a directory"
            echo ""
            echo "Options:"
            echo "  -c <type>  Compression (gzip/bzip2/xz/none)"
            echo "  -k <file>  Use specific key file"
            echo "  -o <file>  Output file"
            ;;
            
        decrypt)
            echo -e "${BOLD}Decryption Module${NC}"
            echo ""
            echo "Commands:"
            echo "  file       Decrypt a file"
            echo "  password   Password-based decryption"
            echo "  two-factor Two-factor decryption"
            echo "  stream     Stream decryption (stdin/stdout)"
            echo "  multi      Multi-recipient decryption"
            echo "  directory  Decrypt a directory"
            echo "  verify     Verify signature"
            ;;
            
        secrets)
            echo -e "${BOLD}Secrets Module${NC}"
            echo ""
            echo "Commands:"
            echo "  store      Store a secret"
            echo "  get        Retrieve a secret"
            echo "  list       List all secrets"
            echo "  search     Search secrets"
            echo "  delete     Delete a secret"
            echo "  expire     Set expiration"
            echo "  tag        Add tags"
            echo "  category   Set category"
            echo "  clean      Remove expired secrets"
            ;;
            
        keys)
            echo -e "${BOLD}Keys Module${NC}"
            echo ""
            echo "Commands:"
            echo "  generate   Generate new key"
            echo "  list       List all keys"
            echo "  rotate     Rotate keys"
            echo "  delete     Delete a key"
            echo "  export     Export a key"
            echo "  import     Import a key"
            echo "  health     Check key health"
            ;;
            
        export)
            echo -e "${BOLD}Export/Import Module${NC}"
            echo ""
            echo "Commands:"
            echo "  export     Export secrets (json/yaml/env/docker/k8s/csv)"
            echo "  import     Import secrets from file"
            echo "  share      Generate QR code for secret"
            ;;
            
        backup)
            echo -e "${BOLD}Backup Module${NC}"
            echo ""
            echo "Commands:"
            echo "  create     Create backup"
            echo "  restore    Restore from backup"
            echo "  list       List available backups"
            echo "  push       Push to cloud"
            echo "  pull       Pull from cloud"
            echo "  config     Configure cloud settings"
            ;;
            
        *)
            echo "Unknown module: ${module}"
            echo "Available modules: encrypt, decrypt, secrets, keys, export, backup"
            ;;
    esac
}

# Export functions
export -f show_version
export -f show_help
export -f show_module_help