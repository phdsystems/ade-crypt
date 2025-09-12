#!/bin/bash
# ADE crypt Library Installer
# Installs the standalone library for system-wide use

set -euo pipefail

# Configuration
LIB_VERSION="2.1.0"
LIB_NAME="ade-crypt-lib"
INSTALL_DIR="${ADE_LIB_INSTALL_DIR:-/usr/local/lib}"
BIN_DIR="${ADE_LIB_BIN_DIR:-/usr/local/bin}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Functions
success() { echo -e "${GREEN}✓ $1${NC}"; }
error() { echo -e "${RED}✗ $1${NC}" >&2; exit 1; }
warn() { echo -e "${YELLOW}⚠ $1${NC}" >&2; }
info() { echo -e "$1"; }

# Check permissions
check_permissions() {
    if [[ ! -w "$INSTALL_DIR" ]] || [[ ! -w "$BIN_DIR" ]]; then
        error "Insufficient permissions. Run with sudo or set custom paths:
  export ADE_LIB_INSTALL_DIR=~/.local/lib
  export ADE_LIB_BIN_DIR=~/.local/bin"
    fi
}

# Install library
install_library() {
    local src_file="$(dirname "$0")/ade-crypt-lib.sh"
    local dest_dir="$INSTALL_DIR/$LIB_NAME"
    local dest_file="$dest_dir/ade-crypt-lib.sh"
    
    # Check source exists
    [[ -f "$src_file" ]] || error "Library file not found: $src_file"
    
    # Create destination directory
    mkdir -p "$dest_dir"
    
    # Copy library
    cp "$src_file" "$dest_file"
    chmod 644 "$dest_file"
    
    success "Installed library to: $dest_file"
}

# Create wrapper script
create_wrapper() {
    local wrapper_file="$BIN_DIR/ade-crypt-lib"
    
    cat > "$wrapper_file" << 'EOF'
#!/bin/bash
# ADE crypt Library Wrapper
# Provides CLI access to library functions

source "/usr/local/lib/ade-crypt-lib/ade-crypt-lib.sh"

show_help() {
    echo "ADE crypt Library CLI v2.1.0"
    echo ""
    echo "Usage: ade-crypt-lib <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  encrypt <input> [output] [key]  - Encrypt file"
    echo "  decrypt <input> [output] [key]  - Decrypt file" 
    echo "  store <name> <value> [key]      - Store secret"
    echo "  get <name> [key]                - Get secret"
    echo "  list-secrets                    - List all secrets"
    echo "  list-keys                       - List all keys"
    echo "  generate-key [name]             - Generate encryption key"
    echo "  checksum <file>                 - Calculate file checksum"
    echo "  info                           - Show library info"
    echo ""
    echo "Environment:"
    echo "  ADE_CRYPT_HOME     - Library home directory (default: ~/.ade)"
    echo "  ADE_LIB_QUIET      - Quiet mode (1 = quiet, 0 = verbose)"
    echo "  ADE_LIB_DEBUG      - Debug mode (1 = debug, 0 = normal)"
}

case "${1:-help}" in
    encrypt)
        ade_encrypt_file "${2:-}" "${3:-}" "${4:-}"
        ;;
    decrypt)
        ade_decrypt_file "${2:-}" "${3:-}" "${4:-}"
        ;;
    store)
        [[ -n "${2:-}" ]] || { echo "Usage: ade-crypt-lib store <name> <value> [key]"; exit 1; }
        [[ -n "${3:-}" ]] || { echo "Usage: ade-crypt-lib store <name> <value> [key]"; exit 1; }
        ade_store_secret "$2" "$3" "${4:-}"
        ;;
    get)
        [[ -n "${2:-}" ]] || { echo "Usage: ade-crypt-lib get <name> [key]"; exit 1; }
        ade_get_secret "$2" "${3:-}"
        ;;
    list-secrets)
        ade_list_secrets
        ;;
    list-keys)
        ade_list_keys
        ;;
    generate-key)
        ade_generate_key "${2:-}"
        ;;
    checksum)
        [[ -n "${2:-}" ]] || { echo "Usage: ade-crypt-lib checksum <file>"; exit 1; }
        ade_checksum "$2"
        ;;
    info)
        ade_lib_info
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: ${1:-}"
        echo "Run 'ade-crypt-lib help' for usage information."
        exit 1
        ;;
esac
EOF

    chmod 755 "$wrapper_file"
    success "Created CLI wrapper: $wrapper_file"
}

# Create usage examples
create_examples() {
    local examples_file="$INSTALL_DIR/$LIB_NAME/examples.sh"
    
    cat > "$examples_file" << 'EOF'
#!/bin/bash
# ADE crypt Library Usage Examples

# Source the library
source "/usr/local/lib/ade-crypt-lib/ade-crypt-lib.sh"

# Example 1: Basic file encryption
echo "== Example 1: File Encryption =="
echo "test content" > /tmp/test.txt
encrypted_file=$(ade_encrypt_file "/tmp/test.txt")
decrypted_file=$(ade_decrypt_file "$encrypted_file")
echo "Original: $(cat /tmp/test.txt)"
echo "Decrypted: $(cat "$decrypted_file")"
rm -f /tmp/test.txt "$encrypted_file" "$decrypted_file"

# Example 2: Secret management
echo -e "\n== Example 2: Secret Management =="
ade_store_secret "api-key" "super-secret-value"
secret_value=$(ade_get_secret "api-key")
echo "Stored and retrieved secret: $secret_value"

# Example 3: Multiple keys
echo -e "\n== Example 3: Multiple Keys =="
ade_generate_key "project-key"
ade_store_secret "project-secret" "project-value" "project-key"
project_value=$(ade_get_secret "project-secret" "project-key")
echo "Project secret: $project_value"

# Example 4: List resources
echo -e "\n== Example 4: List Resources =="
echo "Available keys:"
ade_list_keys
echo "Available secrets:"
ade_list_secrets

# Example 5: Checksums
echo -e "\n== Example 5: File Checksums =="
echo "checksum test" > /tmp/checksum-test.txt
checksum=$(ade_checksum "/tmp/checksum-test.txt")
echo "File checksum: $checksum"
ade_verify_checksum "/tmp/checksum-test.txt" "$checksum"
rm -f /tmp/checksum-test.txt

echo -e "\n== Library Info =="
ade_lib_info
EOF

    chmod 644 "$examples_file"
    success "Created examples: $examples_file"
}

# Main installation
main() {
    info "Installing ADE crypt Library v$LIB_VERSION..."
    
    check_permissions
    install_library
    create_wrapper
    create_examples
    
    info ""
    success "Installation complete!"
    info ""
    info "Usage:"
    info "  # In scripts:"
    info "  source \"$INSTALL_DIR/$LIB_NAME/ade-crypt-lib.sh\""
    info ""
    info "  # Command line:"
    info "  ade-crypt-lib help"
    info ""
    info "  # Examples:"
    info "  bash $INSTALL_DIR/$LIB_NAME/examples.sh"
    info ""
    info "Documentation: https://github.com/phdsystems/ade-crypt"
}

main "$@"