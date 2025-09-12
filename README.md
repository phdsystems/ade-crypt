# ADE-Crypt

Standalone encryption utility for files, directories, and secrets management.

## Quick Start

```bash
# Install
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/install.sh | bash

# Encrypt a file
ade-crypt encrypt sensitive.txt

# Decrypt a file  
ade-crypt decrypt sensitive.txt.enc

# Store a secret
ade-crypt store api-key

# Get a secret
ade-crypt get api-key
```

## Core Features

- **Encryption**: Files and directories with AES-256-CBC
- **Secrets**: Secure storage and retrieval
- **Key Management**: Generation and rotation
- **Backup/Restore**: Full data protection

## Common Usage

```bash
# Encrypt with password
ade-crypt encrypt -p document.pdf

# Encrypt and shred original
ade-crypt encrypt -s confidential.doc

# Encrypt directory
ade-crypt encrypt -r ./secrets-folder

# List stored secrets
ade-crypt list

# Rotate encryption keys
ade-crypt rotate-keys
```

## Documentation

For detailed documentation, examples, and security information, see [DOCS.md](DOCS.md)

## Requirements

- Bash 4.0+
- OpenSSL
- Standard Unix utilities

## License

MIT - See [LICENSE](LICENSE)

## Support

[Issues](https://github.com/phdsystems/ade-crypt/issues) | [PHD-ADE](https://github.com/phdsystems/phd-ade)