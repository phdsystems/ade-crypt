# ADE-Crypt

A standalone encryption/decryption utility extracted from PHD-ADE (PHD Application Development Environment).

## Features

- 🔐 **File & Directory Encryption**: Encrypt individual files or entire directories
- 🔑 **Secret Management**: Store and retrieve secrets securely
- 🔄 **Key Rotation**: Rotate encryption keys for enhanced security
- 📦 **Backup & Restore**: Backup and restore encrypted secrets
- 🔒 **Multiple Encryption Methods**: Password-based or key-file encryption
- 🗑️ **Secure Deletion**: Option to shred original files after encryption

## Installation

### Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/install.sh | bash
```

### Manual Install

```bash
# Download the script
wget https://raw.githubusercontent.com/phdsystems/ade-crypt/main/ade-crypt

# Make it executable
chmod +x ade-crypt

# Move to PATH (optional)
sudo mv ade-crypt /usr/local/bin/
```

## Usage

### Basic Commands

#### Encrypt a file
```bash
ade-crypt encrypt sensitive.txt
# Creates: sensitive.txt.enc
```

#### Decrypt a file
```bash
ade-crypt decrypt sensitive.txt.enc
# Restores: sensitive.txt
```

#### Encrypt a directory recursively
```bash
ade-crypt encrypt -r ./secrets-folder
```

#### Encrypt and shred original
```bash
ade-crypt encrypt -s confidential.doc
```

### Secret Storage

#### Store a secret
```bash
ade-crypt store api-key
# Enter secret when prompted
```

#### Retrieve a secret
```bash
ade-crypt get api-key
```

#### List all stored secrets
```bash
ade-crypt list
```

#### Delete a secret
```bash
ade-crypt delete api-key
```

### Advanced Features

#### Generate encryption key
```bash
ade-crypt generate-key
```

#### Rotate encryption keys
```bash
ade-crypt rotate-keys
```

#### Lock all secrets with master key
```bash
ade-crypt lock
```

#### Unlock all secrets
```bash
ade-crypt unlock
```

#### Backup encrypted secrets
```bash
ade-crypt backup
```

#### Restore from backup
```bash
ade-crypt restore backup-file.tar.gz
```

## Options

- `-k, --key <file>`: Use specific key file
- `-o, --output <file>`: Output to specific file  
- `-r, --recursive`: Encrypt directory recursively
- `-s, --shred`: Shred original after encryption
- `-p, --password`: Use password-based encryption
- `-a, --armor`: ASCII armor output (base64)

## Examples

### Encrypt with password
```bash
ade-crypt encrypt -p secret-document.pdf
```

### Decrypt to specific output
```bash
ade-crypt decrypt -o recovered.txt encrypted.txt.enc
```

### Use custom key file
```bash
ade-crypt encrypt -k ~/.keys/mykey.key data.json
```

### ASCII armor output (for email/text)
```bash
ade-crypt encrypt -a message.txt
```

## Security Notes

- Default encryption uses AES-256-CBC
- Keys are stored in `~/.ade-crypt/` directory
- Original files can be securely shredded with `-s` option
- Password-based encryption uses PBKDF2 for key derivation
- Always backup your encryption keys securely

## Requirements

- Bash 4.0+
- OpenSSL
- Standard Unix utilities (shred, tar, etc.)

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and feature requests, please visit:
https://github.com/phdsystems/ade-crypt/issues

## Credits

Originally developed as part of [PHD-ADE](https://github.com/phdsystems/phd-ade)