# API Reference

## Module APIs

### Encryption Module

#### `encrypt file <filename> [options]`
Encrypts a single file.

**Parameters:**
- `filename` - File to encrypt (required)
- `-k <keyfile>` - Use specific key file
- `-o <output>` - Output filename
- `-c <type>` - Compression (gzip/bzip2/xz/none)
- `-P` - Show progress indicator
- `-2` - Two-factor encryption

**Returns:** Exit code 0 on success, 1 on failure

**Example:**
```bash
ade-crypt encrypt file document.pdf -c gzip
```

#### `encrypt directory <dirname> [options]`
Encrypts an entire directory.

**Parameters:**
- `dirname` - Directory to encrypt (required)
- `-k <keyfile>` - Use specific key file
- `-o <output>` - Output archive name

**Returns:** Exit code 0 on success, 1 on failure

#### `encrypt stream [options]`
Encrypts data from stdin.

**Usage:**
```bash
cat data.txt | ade-crypt encrypt stream > data.enc
```

#### `encrypt multi [options]`
Multi-recipient encryption.

**Parameters:**
- `-m <keys>` - Comma-separated list of recipient keys
- `-S` - Sign the encrypted file

### Decryption Module

#### `decrypt file <filename> [options]`
Decrypts an encrypted file.

**Parameters:**
- `filename` - File to decrypt (required)
- `-k <keyfile>` - Use specific key file
- `-o <output>` - Output filename

**Returns:** Exit code 0 on success, 1 on failure

#### `decrypt directory <archive> [options]`
Decrypts and extracts an encrypted archive.

**Parameters:**
- `archive` - Archive to decrypt (required)
- `-k <keyfile>` - Use specific key file
- `-d <directory>` - Extract to directory

#### `decrypt stream [options]`
Decrypts data from stdin.

**Usage:**
```bash
cat data.enc | ade-crypt decrypt stream > data.txt
```

### Secrets Module

#### `secrets store <name> [options]`
Stores a secret.

**Parameters:**
- `name` - Secret name (required)
- `--category <cat>` - Secret category
- `--tags <tags>` - Comma-separated tags
- `--expire <days>` - Expiration in days

**Input:** Reads secret value from stdin or prompt

**Returns:** Exit code 0 on success

#### `secrets get <name>`
Retrieves a secret.

**Parameters:**
- `name` - Secret name (required)

**Output:** Secret value to stdout

**Returns:** Exit code 0 if found, 1 if not found

#### `secrets list [options]`
Lists all secrets.

**Parameters:**
- `--category <cat>` - Filter by category
- `--tags <tags>` - Filter by tags
- `--expired` - Show only expired secrets

**Output:** Secret names, one per line

#### `secrets delete <name>`
Deletes a secret.

**Parameters:**
- `name` - Secret name (required)
- `-f` - Force deletion without confirmation

**Returns:** Exit code 0 on success

#### `secrets search <pattern>`
Searches for secrets.

**Parameters:**
- `pattern` - Search pattern (supports wildcards)

**Output:** Matching secret names

### Keys Module

#### `keys generate [name]`
Generates a new encryption key.

**Parameters:**
- `name` - Key name (optional, default: "default")

**Output:** Key file path

**Returns:** Exit code 0 on success

#### `keys list`
Lists all keys.

**Output:** Key names, one per line

#### `keys rotate`
Rotates encryption keys.

**Process:**
1. Backs up current keys
2. Generates new keys
3. Re-encrypts all secrets

**Returns:** Exit code 0 on success

#### `keys delete <name>`
Deletes a key.

**Parameters:**
- `name` - Key name (required)
- `-f` - Force deletion

**Returns:** Exit code 0 on success

#### `keys export <name> [file]`
Exports a key.

**Parameters:**
- `name` - Key name (required)
- `file` - Output file (optional, stdout if not specified)

#### `keys import <file> [name]`
Imports a key.

**Parameters:**
- `file` - Key file to import (required)
- `name` - Key name (optional, derived from filename)

### Export Module

#### `export env [options]`
Exports secrets as environment variables.

**Output Format:**
```bash
export SECRET_NAME="secret_value"
```

**Parameters:**
- `--category <cat>` - Filter by category
- `--prefix <prefix>` - Add prefix to variable names

#### `export json [options]`
Exports secrets as JSON.

**Output Format:**
```json
{
  "secret_name": "secret_value",
  "metadata": {...}
}
```

#### `export yaml [options]`
Exports secrets as YAML.

**Output Format:**
```yaml
secrets:
  secret_name: secret_value
metadata:
  ...
```

#### `export docker [options]`
Exports for Docker.

**Output:** Docker secret creation commands

#### `export k8s [options]`
Exports for Kubernetes.

**Output:** Kubernetes Secret YAML

### Backup Module

#### `backup create [options]`
Creates a backup.

**Parameters:**
- `-o <file>` - Output file (optional)
- `--exclude-keys` - Don't backup keys
- `--exclude-secrets` - Don't backup secrets

**Output:** Backup filename

**Returns:** Exit code 0 on success

#### `backup restore <file>`
Restores from backup.

**Parameters:**
- `file` - Backup file (required)
- `-f` - Force restore without confirmation

**Returns:** Exit code 0 on success

#### `backup list`
Lists available backups.

**Output:** Backup files with dates and sizes

#### `backup push [options]`
Pushes backup to cloud.

**Parameters:**
- `--provider <name>` - Cloud provider (s3/gcs/azure)
- `--bucket <name>` - Bucket/container name

#### `backup pull [options]`
Pulls backup from cloud.

**Parameters:**
- `--provider <name>` - Cloud provider
- `--latest` - Get latest backup

## Library API

### Core Functions

#### `ade_init()`
Initializes the library environment.

**Creates:**
- `$ADE_LIB_HOME/keys/`
- `$ADE_LIB_HOME/secrets/`
- `$ADE_LIB_HOME/metadata/`

**Returns:** 0 on success

#### `ade_check_deps()`
Checks for required dependencies.

**Checks:**
- openssl
- sha256sum

**Returns:** 0 if all present, 1 if missing

### Encryption Functions

#### `ade_encrypt_file(input, [output], [key_name])`
Encrypts a file.

**Parameters:**
- `input` - Input file path (required)
- `output` - Output file path (default: input.enc)
- `key_name` - Key to use (default: "default")

**Returns:** Encrypted file path on success

**Example:**
```bash
encrypted=$(ade_encrypt_file "data.txt" "data.enc" "mykey")
```

#### `ade_decrypt_file(input, [output], [key_name])`
Decrypts a file.

**Parameters:**
- `input` - Encrypted file path (required)
- `output` - Output file path (auto-detected)
- `key_name` - Key to use (default: "default")

**Returns:** Decrypted file path on success

### Secret Functions

#### `ade_store_secret(name, value, [key_name])`
Stores a secret.

**Parameters:**
- `name` - Secret name (required)
- `value` - Secret value (required)
- `key_name` - Encryption key (default: "default")

**Returns:** 0 on success, 1 on failure

**Example:**
```bash
ade_store_secret "api_key" "secret123" "prod-key"
```

#### `ade_get_secret(name, [key_name])`
Retrieves a secret.

**Parameters:**
- `name` - Secret name (required)
- `key_name` - Decryption key (default: "default")

**Output:** Secret value to stdout

**Returns:** 0 on success, 1 on failure

**Example:**
```bash
api_key=$(ade_get_secret "api_key" "prod-key")
```

#### `ade_list_secrets()`
Lists all secret names.

**Output:** One secret name per line

**Returns:** 0 always

### Key Functions

#### `ade_generate_key([name])`
Generates an encryption key.

**Parameters:**
- `name` - Key name (default: "default")

**Output:** Key file path

**Returns:** 0 on success

**Example:**
```bash
key_path=$(ade_generate_key "project-key")
```

#### `ade_list_keys()`
Lists all key names.

**Output:** One key name per line

**Returns:** 0 always

### Utility Functions

#### `ade_checksum(file)`
Calculates file checksum.

**Parameters:**
- `file` - File path (required)

**Output:** SHA-256 checksum

**Returns:** 0 on success, 1 on failure

#### `ade_verify_checksum(file, expected)`
Verifies file checksum.

**Parameters:**
- `file` - File path (required)
- `expected` - Expected checksum (required)

**Returns:** 0 if match, 1 if mismatch

### Message Functions

#### `ade_success(message)`
Shows success message.

**Parameters:**
- `message` - Message text

**Output:** Green checkmark with message

#### `ade_error(message)`
Shows error message.

**Parameters:**
- `message` - Message text

**Output:** Red X with message to stderr

**Returns:** 1 always

#### `ade_warn(message)`
Shows warning message.

**Parameters:**
- `message` - Message text

**Output:** Yellow warning symbol with message

#### `ade_debug(message)`
Shows debug message.

**Parameters:**
- `message` - Message text

**Output:** Cyan debug message (only if ADE_LIB_DEBUG=1)

## Environment Variables

### Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ADE_CRYPT_HOME` | `~/.ade` | Base directory for data |
| `ADE_LIB_QUIET` | `0` | Suppress messages (0/1) |
| `ADE_LIB_DEBUG` | `0` | Show debug output (0/1) |
| `ALGORITHM` | `aes-256-cbc` | Encryption algorithm |
| `COMPRESSION` | `gzip` | Default compression |
| `AUDIT_ENABLED` | `1` | Enable audit logging |
| `KEY_EXPIRY_DAYS` | `90` | Default key expiration |
| `SECRET_EXPIRY_DAYS` | `180` | Default secret expiration |

### Path Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SECRETS_DIR` | `$ADE_CRYPT_HOME/secrets` | Secret storage |
| `KEYS_DIR` | `$ADE_CRYPT_HOME/keys` | Key storage |
| `METADATA_DIR` | `$ADE_CRYPT_HOME/metadata` | Metadata storage |
| `CONFIG_FILE` | `$ADE_CRYPT_HOME/config` | Configuration file |
| `AUDIT_LOG` | `$ADE_CRYPT_HOME/audit.log` | Audit log file |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Missing dependency |
| 3 | File not found |
| 4 | Permission denied |
| 5 | Invalid arguments |
| 6 | Encryption/decryption failed |
| 7 | Key error |
| 8 | Secret not found |

## Error Handling

All functions follow consistent error handling:

1. Validate inputs
2. Check dependencies
3. Perform operation
4. Return appropriate exit code
5. Display error message on failure

Example error handling:
```bash
if ! ade_encrypt_file "input.txt"; then
    echo "Encryption failed"
    exit 1
fi
```