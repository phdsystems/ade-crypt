# ADE-Crypt

Advanced modular encryption utility with enterprise features, cloud sync, and comprehensive secret management.

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

- **Encryption**: AES-256-CBC with compression support
- **Multi-Recipient**: Encrypt for multiple users
- **Two-Factor**: Combined key + password protection  
- **Cloud Sync**: AWS S3, Google Drive, Dropbox
- **Streaming**: Pipeline encryption/decryption
- **Audit Logging**: Complete operation tracking
- **Interactive Mode**: Menu-driven interface
- **Docker/K8s**: Container secret integration

## What's New in v2.0

- Multi-recipient encryption
- Two-factor authentication
- Streaming encryption (stdin/stdout)
- Cloud synchronization
- Digital signatures
- Secret versioning
- Audit logging
- Interactive mode
- Docker/K8s integration
- [Full changelog](DOCS.md#whats-new-in-v20)

## Common Usage

```bash
# Interactive mode
ade-crypt interactive

# Multi-recipient encryption
ade-crypt multi-encrypt -m "alice.key,bob.key" file.pdf

# Two-factor encryption
ade-crypt encrypt -2 sensitive.doc

# Stream encryption
cat data.txt | ade-crypt stream-encrypt > data.enc

# Cloud backup
ade-crypt backup && ade-crypt cloud-sync push

# Export secrets
ade-crypt export env > .env
```

## Project Structure

```
ade-crypt/
├── bin/           # Executables
├── src/           # Source code
│   ├── core/      # Core logic
│   ├── lib/       # Shared libraries
│   └── modules/   # Feature modules
├── docs/          # Documentation
└── tests/         # Test suite
```

See [Project Structure](docs/PROJECT_STRUCTURE.md) for detailed layout.

## Documentation

- [Detailed Documentation](docs/DOCS.md)
- [Modular Architecture](docs/MODULAR.md)
- [Project Structure](docs/PROJECT_STRUCTURE.md)

## Requirements

- Bash 4.0+
- OpenSSL
- Standard Unix utilities

## License

MIT - See [LICENSE](LICENSE)

## Support

[Issues](https://github.com/phdsystems/ade-crypt/issues) | [PHD-ADE](https://github.com/phdsystems/phd-ade)