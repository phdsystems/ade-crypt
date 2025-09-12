# ADE-Crypt Documentation

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Commands Reference](#commands-reference)
- [Options Reference](#options-reference)
- [Examples](#examples)
- [Security](#security)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)

## Overview

ADE-Crypt is a comprehensive encryption utility that provides secure file and directory encryption, secrets management, and key rotation capabilities. Originally developed as part of PHD-ADE (PHD Application Development Environment), it now stands as an independent security tool.

### Key Features

- **Military-grade encryption** using AES-256-CBC
- **Flexible encryption modes** (key-based or password-based)
- **Secure secrets vault** for API keys, tokens, and credentials
- **Automated key rotation** for compliance and security
- **Backup and restore** capabilities
- **Secure file shredding** to prevent recovery

## Installation

### Prerequisites

- Bash 4.0 or higher
- OpenSSL 1.1.1 or higher
- GPG (for password-based encryption)
- Standard Unix utilities (tar, shred, etc.)

### Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/install.sh | bash
```

### Manual Installation

```bash
# Download the script
wget https://raw.githubusercontent.com/phdsystems/ade-crypt/main/ade-crypt

# Make executable
chmod +x ade-crypt

# Move to system path
sudo mv ade-crypt /usr/local/bin/

# Create configuration directory
mkdir -p ~/.ade-crypt
```

### Verification

```bash
# Verify installation
ade-crypt --help

# Check version and dependencies
ade-crypt --version
```

## Commands Reference

### File Operations

#### `encrypt <file>`
Encrypts a single file using the default or specified key.

```bash
ade-crypt encrypt document.pdf
# Output: document.pdf.enc
```

#### `decrypt <file>`
Decrypts an encrypted file.

```bash
ade-crypt decrypt document.pdf.enc
# Output: document.pdf
```

### Directory Operations

#### Encrypt Directory
Encrypts an entire directory into a single encrypted archive.

```bash
ade-crypt encrypt -r ./sensitive-data
# Output: sensitive-data.tar.enc
```

#### Decrypt Directory
Decrypts and extracts an encrypted directory archive.

```bash
ade-crypt decrypt sensitive-data.tar.enc
# Extracts to current directory
```

### Secret Management

#### `store <name>`
Stores a secret securely in the vault.

```bash
ade-crypt store github-token
# Prompts for secret value
```

#### `get <name>`
Retrieves a stored secret.

```bash
ade-crypt get github-token
# Outputs the secret value
```

#### `list`
Lists all stored secrets (names only).

```bash
ade-crypt list
# Output:
#   • github-token
#   • api-key
#   • db-password
```

#### `delete <name>`
Permanently deletes a stored secret.

```bash
ade-crypt delete old-token
# Confirms before deletion
```

### Key Management

#### `generate-key [name]`
Generates a new encryption key.

```bash
# Generate default key
ade-crypt generate-key

# Generate named key
ade-crypt generate-key project-key
```

#### `rotate-keys`
Rotates all encryption keys and re-encrypts existing secrets.

```bash
ade-crypt rotate-keys
# Backs up old key to ~/.ade/keys/default.key.old
```

### Backup and Restore

#### `backup`
Creates a complete backup of all secrets and keys.

```bash
ade-crypt backup
# Output: ade-secrets-20240112-143022.tar.gz
```

#### `restore <backup-file>`
Restores secrets and keys from a backup file.

```bash
ade-crypt restore ade-secrets-20240112-143022.tar.gz
# Prompts for confirmation
```

## Options Reference

| Option | Long Form | Description |
|--------|-----------|-------------|
| `-k` | `--key <file>` | Use specific key file for encryption/decryption |
| `-o` | `--output <file>` | Specify output filename |
| `-r` | `--recursive` | Process directories recursively |
| `-s` | `--shred` | Securely delete original file after encryption |
| `-p` | `--password` | Use password-based encryption (GPG) |
| `-a` | `--armor` | Create ASCII-armored output (base64) |

## Examples

### Basic File Encryption

```bash
# Simple encryption
ade-crypt encrypt report.doc

# With custom output name
ade-crypt encrypt -o report.secure report.doc

# Using specific key
ade-crypt encrypt -k ~/.keys/custom.key report.doc
```

### Password-Based Encryption

```bash
# Encrypt with password
ade-crypt encrypt -p sensitive.xlsx
# Enter password: ********

# Decrypt with password
ade-crypt decrypt -p sensitive.xlsx.enc
# Enter password: ********
```

### Secure Workflows

```bash
# Encrypt and shred original
ade-crypt encrypt -s confidential.pdf

# ASCII armor for email transmission
ade-crypt encrypt -a message.txt
# Creates base64-encoded output
```

### Batch Operations

```bash
# Encrypt multiple files
for file in *.doc; do
    ade-crypt encrypt "$file"
done

# Decrypt all .enc files
for file in *.enc; do
    ade-crypt decrypt "$file"
done
```

### Secret Management Workflows

```bash
# Store multiple secrets
for secret in api-key db-pass token; do
    echo "Storing $secret..."
    ade-crypt store "$secret"
done

# Backup before key rotation
ade-crypt backup
ade-crypt rotate-keys
```

## Security

### Encryption Standards

- **Algorithm**: AES-256-CBC (Advanced Encryption Standard)
- **Key Size**: 256-bit
- **Mode**: Cipher Block Chaining with salt
- **Password Derivation**: PBKDF2 (for password mode)

### Best Practices

1. **Key Management**
   - Store keys in secure locations
   - Use different keys for different data classifications
   - Rotate keys regularly (monthly/quarterly)
   - Never commit keys to version control

2. **File Security**
   - Use `-s` flag to shred originals after encryption
   - Verify backups regularly
   - Store backups in separate locations

3. **Secret Storage**
   - Use meaningful but non-obvious secret names
   - Regularly audit stored secrets with `list`
   - Delete unused secrets promptly

### Security Considerations

- Keys are stored in plaintext in `~/.ade/keys/`
- Ensure proper file permissions (700 for directories, 600 for files)
- Consider full-disk encryption for additional protection
- Use password mode for highly sensitive data requiring two-factor protection

## Architecture

### Directory Structure

```
~/.ade/
├── keys/           # Encryption keys
│   ├── default.key
│   └── *.key
├── secrets/        # Encrypted secrets
│   └── *.enc
└── encrypted/      # Temporary encrypted files
```

### File Formats

- **Encrypted Files**: Binary format with `.enc` extension
- **Keys**: Base64-encoded 256-bit random data
- **Secrets**: AES-256-CBC encrypted text files
- **Backups**: Tar.gz archives containing keys and secrets

### Process Flow

1. **Encryption Process**
   ```
   Input File → Read Key → AES-256-CBC → Salt → Output.enc
   ```

2. **Decryption Process**
   ```
   Input.enc → Read Key → Verify Salt → AES-256-CBC → Output File
   ```

## Troubleshooting

### Common Issues

#### "Key not found" Error
```bash
# Generate default key
ade-crypt generate-key

# Or specify existing key
ade-crypt decrypt -k ~/.keys/mykey.key file.enc
```

#### "Decryption failed" Error
- Verify correct key is being used
- Check file wasn't corrupted during transfer
- Ensure using same mode (password vs key)

#### Permission Denied
```bash
# Fix permissions
chmod 700 ~/.ade ~/.ade/keys ~/.ade/secrets
chmod 600 ~/.ade/keys/*.key
```

#### Missing Dependencies
```bash
# Ubuntu/Debian
sudo apt-get install openssl gpg

# RHEL/CentOS
sudo yum install openssl gnupg2

# macOS
brew install openssl gnupg
```

### Recovery Procedures

#### Lost Key Recovery
If you've lost your encryption key:
1. Check for backups in `~/.ade/keys/*.key.old`
2. Restore from system backup if available
3. Without the key, encrypted data cannot be recovered

#### Corrupted Secret Store
```bash
# List and verify secrets
ade-crypt list

# Restore from backup
ade-crypt restore last-backup.tar.gz
```

### Performance Tips

- Use key-based encryption for automation (faster)
- Use password-based for interactive security (more secure)
- Archive large directories before encrypting
- Consider parallel processing for batch operations

## Advanced Usage

### Integration with Scripts

```bash
#!/bin/bash
# Automated backup script

# Encrypt database dump
pg_dump mydb | ade-crypt encrypt -o db-backup.enc

# Store in secrets
echo "$API_KEY" | ade-crypt store api-key

# Retrieve for use
API_KEY=$(ade-crypt get api-key)
```

### CI/CD Integration

```yaml
# GitHub Actions example
- name: Decrypt credentials
  run: |
    echo "${{ secrets.ENCRYPT_KEY }}" > /tmp/ci.key
    ade-crypt decrypt -k /tmp/ci.key credentials.enc
```

### Cron Jobs

```bash
# Daily key rotation
0 2 * * * /usr/local/bin/ade-crypt rotate-keys

# Weekly backup
0 3 * * 0 /usr/local/bin/ade-crypt backup
```

## Support and Contributing

### Getting Help

- **Issues**: [GitHub Issues](https://github.com/phdsystems/ade-crypt/issues)
- **Documentation**: This file and inline help (`--help`)
- **Community**: PHD-ADE project discussions

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### License

MIT License - See LICENSE file for full details

### Credits

Developed by PHD Systems as part of the PHD Application Development Environment (PHD-ADE).