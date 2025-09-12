# ADE crypt Library

Standalone library version of ADE crypt for integration into other projects.

## Features

- **Single-file library** - No dependencies on main project structure
- **Simple API** - Clean function interfaces for encryption, secrets, keys
- **Auto-initialization** - Sets up required directories automatically  
- **Error handling** - Comprehensive validation and error messages
- **Configurable** - Environment variables for customization

## Quick Start

### Installation

```bash
# System-wide installation (requires sudo)
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/lib/install.sh | bash

# Local installation
export ADE_LIB_INSTALL_DIR=~/.local/lib
export ADE_LIB_BIN_DIR=~/.local/bin
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/lib/install.sh | bash
```

### Usage in Scripts

```bash
#!/bin/bash
# Your project script

# Source the library
source "/usr/local/lib/ade-crypt-lib/ade-crypt-lib.sh"

# Encrypt a file
encrypted_file=$(ade_encrypt_file "sensitive.txt")
echo "Encrypted to: $encrypted_file"

# Store a secret
ade_store_secret "api-key" "super-secret-value"

# Retrieve the secret
secret=$(ade_get_secret "api-key") 
echo "Secret: $secret"

# Generate a key for a specific project
ade_generate_key "project-key"

# Use the key for encryption
ade_encrypt_file "data.txt" "data.enc" "project-key"
```

### Command Line Usage

```bash
# After installation, use the CLI wrapper
ade-crypt-lib encrypt myfile.txt
ade-crypt-lib decrypt myfile.txt.enc
ade-crypt-lib store api-key "my-secret-value"
ade-crypt-lib get api-key
ade-crypt-lib list-secrets
ade-crypt-lib generate-key project-key
```

## API Reference

### Encryption Functions

#### `ade_encrypt_file(input, [output], [key_name])`
Encrypts a file using AES-256-CBC encryption.
- **input**: Input file path (required)
- **output**: Output file path (default: input.enc)
- **key_name**: Key name to use (default: "default")
- **Returns**: Path to encrypted file

#### `ade_decrypt_file(input, [output], [key_name])`  
Decrypts an encrypted file.
- **input**: Encrypted file path (required)
- **output**: Output file path (auto-detected from .enc extension)
- **key_name**: Key name to use (default: "default")  
- **Returns**: Path to decrypted file

### Secret Management

#### `ade_store_secret(name, value, [key_name])`
Stores a secret securely.
- **name**: Secret name (required)
- **value**: Secret value (required)
- **key_name**: Key to encrypt with (default: "default")

#### `ade_get_secret(name, [key_name])`
Retrieves a stored secret.
- **name**: Secret name (required)
- **key_name**: Key to decrypt with (default: "default")
- **Returns**: Secret value to stdout

#### `ade_list_secrets()`
Lists all stored secret names.
- **Returns**: One secret name per line

### Key Management

#### `ade_generate_key([name])`
Generates a new 256-bit encryption key.
- **name**: Key name (default: "default")
- **Returns**: Path to generated key file

#### `ade_list_keys()`
Lists all available key names.
- **Returns**: One key name per line

### Utility Functions

#### `ade_checksum(file)`
Calculates SHA-256 checksum of a file.
- **file**: File path (required)
- **Returns**: Hexadecimal checksum string

#### `ade_verify_checksum(file, expected)`
Verifies file checksum against expected value.
- **file**: File path (required) 
- **expected**: Expected checksum (required)
- **Returns**: 0 if match, 1 if mismatch

### Message Functions

#### `ade_success(message)`, `ade_error(message)`, `ade_warn(message)`, `ade_debug(message)`
Display formatted messages with colors.
- **message**: Message text
- Respects `ADE_LIB_QUIET` and `ADE_LIB_DEBUG` environment variables

## Configuration

### Environment Variables

- `ADE_CRYPT_HOME` - Base directory for keys/secrets (default: ~/.ade)
- `ADE_LIB_QUIET` - Suppress success/warning messages (0/1)
- `ADE_LIB_DEBUG` - Show debug messages (0/1)

### Directory Structure

```
$ADE_CRYPT_HOME/
├── keys/        # Encryption keys
├── secrets/     # Encrypted secrets  
├── encrypted/   # Temporary encrypted files
└── metadata/    # File metadata
```

## Examples

### Basic Usage

```bash
source "ade-crypt-lib.sh"

# Encrypt configuration file
ade_encrypt_file "config.json" "config.json.enc" "prod-key"

# Store database password
ade_store_secret "db_password" "super_secure_pwd" "prod-key"

# In another script, retrieve and use
DB_PASSWORD=$(ade_get_secret "db_password" "prod-key")
mysql -p"$DB_PASSWORD" myapp
```

### Project Integration

```bash
#!/bin/bash
# deployment.sh

source "/usr/local/lib/ade-crypt-lib/ade-crypt-lib.sh"

# Set project-specific key
PROJECT_KEY="deploy-$(date +%Y%m)"
ade_generate_key "$PROJECT_KEY"

# Encrypt deployment secrets
for secret_file in secrets/*.json; do
    ade_encrypt_file "$secret_file" "$secret_file.enc" "$PROJECT_KEY"
done

# Store deployment metadata
ade_store_secret "deploy_key_name" "$PROJECT_KEY"
ade_store_secret "deploy_date" "$(date -Iseconds)"

echo "Deployment encrypted with key: $PROJECT_KEY"
```

### Backup Script Integration

```bash
#!/bin/bash
# backup.sh

source "ade-crypt-lib.sh"

# Create encrypted backup
BACKUP_FILE="/backups/app-$(date +%Y%m%d).tar"
tar -cf "$BACKUP_FILE" /var/www/app
encrypted_backup=$(ade_encrypt_file "$BACKUP_FILE" "$BACKUP_FILE.enc")

# Store backup metadata
ade_store_secret "last_backup" "$encrypted_backup"
ade_store_secret "last_backup_date" "$(date -Iseconds)"

# Clean up unencrypted backup
rm "$BACKUP_FILE"

echo "Backup created: $encrypted_backup"
```

## Requirements

- Bash 4.0+
- OpenSSL (for encryption)
- sha256sum (for checksums)

## Installation Locations

### System Installation (with sudo)
- Library: `/usr/local/lib/ade-crypt-lib/ade-crypt-lib.sh`
- CLI: `/usr/local/bin/ade-crypt-lib`
- Examples: `/usr/local/lib/ade-crypt-lib/examples.sh`

### Local Installation 
- Library: `~/.local/lib/ade-crypt-lib/ade-crypt-lib.sh`  
- CLI: `~/.local/bin/ade-crypt-lib`
- Examples: `~/.local/lib/ade-crypt-lib/examples.sh`

## License

MIT License - Same as main ADE crypt project

## Support

- Issues: https://github.com/phdsystems/ade-crypt/issues
- Documentation: https://github.com/phdsystems/ade-crypt