#!/bin/bash
# ADE-Crypt Core Dispatcher
# Main logic for command routing and module loading

# Get base directory (two levels up from core)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export MODULES_DIR="$BASE_DIR/src/modules"
export LIB_DIR="$BASE_DIR/src/lib"

# Source common library
source "$LIB_DIR/common.sh"

# Module dispatcher
dispatch_module() {
    local module="$1"
    shift
    
    case "$module" in
        encrypt|enc)
            "$MODULES_DIR/encrypt.sh" "$@"
            ;;
        decrypt|dec)
            "$MODULES_DIR/decrypt.sh" "$@"
            ;;
        secrets|secret|sec)
            "$MODULES_DIR/secrets.sh" "$@"
            ;;
        keys|key)
            "$MODULES_DIR/keys.sh" "$@"
            ;;
        export|import|share)
            "$MODULES_DIR/export.sh" "$@"
            ;;
        backup|sync)
            "$MODULES_DIR/backup.sh" "$@"
            ;;
        *)
            error_exit "Unknown module: $module"
            ;;
    esac
}

# Compatibility layer for old commands
handle_legacy_command() {
    local command="$1"
    shift
    
    case "$command" in
        encrypt)
            "$MODULES_DIR/encrypt.sh" file "$@"
            ;;
        decrypt)
            "$MODULES_DIR/decrypt.sh" file "$@"
            ;;
        store)
            "$MODULES_DIR/secrets.sh" store "$@"
            ;;
        get)
            "$MODULES_DIR/secrets.sh" get "$@"
            ;;
        list)
            "$MODULES_DIR/secrets.sh" list "$@"
            ;;
        generate-key)
            "$MODULES_DIR/keys.sh" generate "$@"
            ;;
        rotate-keys)
            "$MODULES_DIR/keys.sh" rotate
            ;;
        backup)
            "$MODULES_DIR/backup.sh" create "$@"
            ;;
        restore)
            "$MODULES_DIR/backup.sh" restore "$@"
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}

# Check if all modules are executable
check_modules() {
    local missing=0
    
    for module in encrypt decrypt secrets keys export backup; do
        if [ ! -x "$MODULES_DIR/${module}.sh" ]; then
            chmod +x "$MODULES_DIR/${module}.sh" 2>/dev/null || {
                warning_msg "Module not executable: ${module}.sh"
                ((missing++))
            }
        fi
    done
    
    [ $missing -gt 0 ] && error_exit "Some modules are not properly installed"
}

# Export functions for use by main script
export -f dispatch_module
export -f handle_legacy_command
export -f check_modules