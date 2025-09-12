#!/bin/bash
# ADE crypt Backup & Sync Module  
# Handles backups, restore, and cloud synchronization

# Source common library
source "$(dirname "$0")/../lib/common.sh"

# Create backup
backup_create() {
    local backup_name="ade-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    local backup_path="${1:-$HOME/$backup_name}"
    
    info_msg "Creating backup..."
    
    # Create backup
    tar czf "$backup_path" -C "$BASE_DIR" \
        secrets keys metadata versions 2>/dev/null
    
    if [ $? -eq 0 ]; then
        # Calculate checksum
        local checksum=$(sha256sum "$backup_path" | cut -d' ' -f1)
        echo "$checksum" > "${backup_path}.sha256"
        
        audit_log "BACKUP: Created $backup_path (checksum: $checksum)"
        success_msg "Backup created: $backup_path"
        info_msg "Checksum: $checksum"
        
        # Optional cloud sync
        if [ "${AUTO_CLOUD_BACKUP:-0}" -eq 1 ]; then
            cloud_push "$backup_path"
        fi
    else
        error_exit "Backup failed"
    fi
}

# Restore backup
backup_restore() {
    local backup_file="$1"
    
    [ -f "$backup_file" ] || error_exit "Backup file not found: $backup_file"
    
    # Verify checksum if exists
    if [ -f "${backup_file}.sha256" ]; then
        info_msg "Verifying backup integrity..."
        local expected=$(cat "${backup_file}.sha256")
        local actual=$(sha256sum "$backup_file" | cut -d' ' -f1)
        
        if [ "$expected" != "$actual" ]; then
            error_exit "Backup checksum mismatch!"
        fi
        success_msg "Backup integrity verified"
    fi
    
    if confirm_action "This will overwrite existing data. Continue?"; then
        info_msg "Restoring from backup..."
        tar xzf "$backup_file" -C "$BASE_DIR"
        
        audit_log "RESTORE: From $backup_file"
        success_msg "Backup restored"
    else
        echo "Cancelled"
    fi
}

# List backups
backup_list() {
    local backup_dir="${1:-$HOME}"
    
    info_msg "Available backups in $backup_dir:"
    echo ""
    
    local found=0
    for backup in "$backup_dir"/ade-backup-*.tar.gz; do
        [ -f "$backup" ] || continue
        
        local size=$(du -h "$backup" | cut -f1)
        local date=$(stat -c %y "$backup" 2>/dev/null || stat -f "%Sm" "$backup" 2>/dev/null)
        
        echo "  $(basename "$backup")"
        echo "    Size: $size"
        echo "    Date: $date"
        
        if [ -f "${backup}.sha256" ]; then
            echo "    Checksum: ✓"
        else
            echo "    Checksum: ✗"
        fi
        echo ""
        ((found++))
    done
    
    [ $found -eq 0 ] && echo "  No backups found"
}

# Cloud push
cloud_push() {
    local source="${1:-$BASE_DIR}"
    local provider="${CLOUD_PROVIDER:-s3}"
    local bucket="${CLOUD_BUCKET:-ade-crypt-backup}"
    local path="${CLOUD_PATH:-/}"
    
    info_msg "Pushing to cloud: $provider"
    
    case "$provider" in
        s3|aws)
            check_dependency "aws"
            aws s3 sync "$source" "s3://$bucket$path" \
                --exclude "*.log" --exclude "*.tmp"
            ;;
            
        gcs|gcloud)
            check_dependency "gsutil"
            gsutil -m rsync -r "$source" "gs://$bucket$path"
            ;;
            
        azure)
            check_dependency "az"
            az storage blob upload-batch \
                --source "$source" \
                --destination "$bucket" \
                --destination-path "$path"
            ;;
            
        local)
            # Local backup to another directory
            local dest="${CLOUD_BUCKET:-/backup/ade-crypt}"
            mkdir -p "$dest"
            rsync -av --exclude="*.log" "$source/" "$dest/"
            ;;
            
        *)
            error_exit "Unknown cloud provider: $provider"
            ;;
    esac
    
    audit_log "CLOUD_PUSH: $source to $provider"
    success_msg "Cloud sync complete"
}

# Cloud pull
cloud_pull() {
    local dest="${1:-$BASE_DIR}"
    local provider="${CLOUD_PROVIDER:-s3}"
    local bucket="${CLOUD_BUCKET:-ade-crypt-backup}"
    local path="${CLOUD_PATH:-/}"
    
    info_msg "Pulling from cloud: $provider"
    
    if ! confirm_action "This will overwrite local data. Continue?"; then
        echo "Cancelled"
        return
    fi
    
    case "$provider" in
        s3|aws)
            check_dependency "aws"
            aws s3 sync "s3://$bucket$path" "$dest"
            ;;
            
        gcs|gcloud)
            check_dependency "gsutil"
            gsutil -m rsync -r "gs://$bucket$path" "$dest"
            ;;
            
        azure)
            check_dependency "az"
            az storage blob download-batch \
                --source "$bucket" \
                --source-path "$path" \
                --destination "$dest"
            ;;
            
        local)
            local source="${CLOUD_BUCKET:-/backup/ade-crypt}"
            rsync -av "$source/" "$dest/"
            ;;
            
        *)
            error_exit "Unknown cloud provider: $provider"
            ;;
    esac
    
    audit_log "CLOUD_PULL: from $provider to $dest"
    success_msg "Cloud sync complete"
}

# Configure cloud
cloud_config() {
    info_msg "Cloud Configuration"
    echo ""
    
    echo "Current settings:"
    echo "  Provider: ${CLOUD_PROVIDER:-not set}"
    echo "  Bucket:   ${CLOUD_BUCKET:-not set}"
    echo "  Path:     ${CLOUD_PATH:-/}"
    echo ""
    
    if confirm_action "Update cloud configuration?"; then
        read -p "Provider (s3/gcs/azure/local): " provider
        read -p "Bucket/Path: " bucket
        read -p "Path prefix [/]: " path
        
        # Update config
        cat >> "$CONFIG_FILE" << EOF

# Cloud sync settings
CLOUD_PROVIDER="$provider"
CLOUD_BUCKET="$bucket"
CLOUD_PATH="${path:-/}"
AUTO_CLOUD_BACKUP=1
EOF
        
        success_msg "Cloud configuration updated"
        info_msg "Reload config to apply changes"
    fi
}

# Main execution
case "${1:-}" in
    create)
        shift
        backup_create "$@"
        ;;
    restore)
        shift
        backup_restore "$@"
        ;;
    list)
        shift
        backup_list "$@"
        ;;
    push)
        shift
        cloud_push "$@"
        ;;
    pull)
        shift
        cloud_pull "$@"
        ;;
    config)
        cloud_config
        ;;
    *)
        echo "Usage: $(basename "$0") {create|restore|list|push|pull|config} [options]"
        exit 1
        ;;
esac