# ADE crypt

> Advanced modular encryption utility for Agentic Development Environment with enterprise features, cloud sync, and comprehensive secret management.

[![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)](https://github.com/phdsystems/ade-crypt/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash%204.0%2B-orange.svg)](https://www.gnu.org/software/bash/)

## Quick Start

```bash
# Install
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/install.sh | bash

# Encrypt a file
ade-crypt encrypt file sensitive.txt

# Store a secret
ade-crypt secrets store api-key

# Generate encryption key
ade-crypt keys generate project-key
```

## Features

- 🔐 **AES-256-CBC encryption** with compression support
- 👥 **Multi-recipient encryption** for team collaboration
- 🔑 **Two-factor authentication** (key + password)
- ☁️ **Cloud sync** (AWS S3, Google Drive, Dropbox)
- 📦 **Secret management** with versioning
- 🎯 **Modular architecture** for extensibility
- 📚 **Standalone library** for integration
- 🧪 **Comprehensive testing** with 120+ tests
- 🔒 **Security auditing** and automated fixes
- ⚡ **Performance monitoring** with benchmarks

## Installation

### System-wide
```bash
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/install.sh | bash
```

### As Library
```bash
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/lib/install.sh | bash
```

See [Installation Guide](docs/INSTALLATION.md) for more options.

## Documentation

| Document | Description |
|----------|-------------|
| [User Guide](docs/USER_GUIDE.md) | Complete usage instructions and examples |
| [Installation](docs/INSTALLATION.md) | Detailed installation options |
| [Architecture](docs/ARCHITECTURE.md) | Technical design and structure |
| [API Reference](docs/API_REFERENCE.md) | Module and function documentation |
| [Testing](docs/TESTING.md) | Testing and quality assurance |
| [Development](docs/DEVELOPMENT.md) | Development guidelines and workflow |
| [Security](docs/SECURITY.md) | Security best practices |
| [Library Usage](lib/README.md) | Standalone library integration |
| [Changelog](CHANGELOG.md) | Version history and changes |

## Usage Examples

### Basic Operations
```bash
# Encrypt/decrypt files
ade-crypt encrypt file document.pdf
ade-crypt decrypt file document.pdf.enc

# Manage secrets
ade-crypt secrets store github-token
ade-crypt secrets get github-token
ade-crypt secrets list

# Key management
ade-crypt keys generate production
ade-crypt keys rotate
```

### Advanced Features
```bash
# Multi-recipient encryption
ade-crypt encrypt multi -m "alice.key,bob.key" file.pdf

# Two-factor encryption
ade-crypt encrypt file sensitive.doc -2

# Stream encryption
cat data.txt | ade-crypt encrypt stream > data.enc

# Cloud backup
ade-crypt backup create
ade-crypt backup push
```

See [User Guide](docs/USER_GUIDE.md) for comprehensive examples.

## Development

### Requirements
- Bash 4.0+
- OpenSSL
- Standard Unix utilities

### Setup
```bash
git clone https://github.com/phdsystems/ade-crypt.git
cd ade-crypt
make setup
```

### Testing
```bash
make test        # Run all tests
make lint        # Run ShellCheck linting
make coverage    # Generate coverage report
make security    # Run security audit
make ci          # Full CI pipeline
```

**Test Coverage**: 120+ tests across 12 test files
- Unit tests for core modules
- Integration tests for workflows
- Security vulnerability tests
- Performance benchmarks

See [Testing Guide](docs/TESTING.md) for details.

## Project Structure

```
ade-crypt/
├── src/           # Source code
├── lib/           # Standalone library
├── docs/          # Documentation
├── tests/         # Test suite
└── scripts/       # Development tools
```

See [Architecture](docs/ARCHITECTURE.md) for detailed structure.

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) first.

## License

MIT License - see [LICENSE](LICENSE) file.

## Support

- **Issues**: [GitHub Issues](https://github.com/phdsystems/ade-crypt/issues)
- **Discussions**: [GitHub Discussions](https://github.com/phdsystems/ade-crypt/discussions)
- **Security**: Report vulnerabilities privately via GitHub Security

## Credits

Developed by [PHD Systems](https://github.com/phdsystems) as part of the Agentic Development Environment (ADE) initiative.