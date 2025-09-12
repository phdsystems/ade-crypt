# ADE crypt Architecture

## Overview

ADE crypt follows a modular, layered architecture designed for extensibility, maintainability, and reusability. The system is built as a collection of independent modules coordinated through a central dispatcher.

## Architecture Principles

1. **Modularity**: Each feature is a self-contained module
2. **Separation of Concerns**: Clear boundaries between layers
3. **Reusability**: Common functions in shared libraries
4. **Extensibility**: Easy to add new modules
5. **Security First**: Encryption and secure practices throughout

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    User Interface                        │
│              (CLI / Library API / Scripts)               │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Core Layer                            │
│                                                          │
│  ┌──────────────┐      ┌─────────────────────┐         │
│  │  Dispatcher  │◄────►│    Help System      │         │
│  └──────────────┘      └─────────────────────┘         │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   Module Layer                           │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │ Encrypt  │  │ Decrypt  │  │ Secrets  │             │
│  └──────────┘  └──────────┘  └──────────┘             │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │   Keys   │  │  Export  │  │  Backup  │             │
│  └──────────┘  └──────────┘  └──────────┘             │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   Library Layer                          │
│                                                          │
│              ┌──────────────────────┐                   │
│              │    common.sh         │                   │
│              │  (Shared Functions)  │                   │
│              └──────────────────────┘                   │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   Storage Layer                          │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │   Keys   │  │ Secrets  │  │ Metadata │             │
│  └──────────┘  └──────────┘  └──────────┘             │
└─────────────────────────────────────────────────────────┘
```

## Component Details

### Core Layer

#### Dispatcher (`src/core/dispatcher.sh`)
- Routes commands to appropriate modules
- Handles legacy command compatibility
- Manages module loading and validation
- Provides error handling and recovery

#### Help System (`src/core/help.sh`)
- Displays help and usage information
- Shows module-specific documentation
- Manages version information
- Provides command examples

### Module Layer

Each module is a self-contained unit with:
- Independent command handling
- Module-specific functions
- Error handling
- Help documentation

#### Encryption Module (`src/modules/encrypt.sh`)
- File encryption
- Directory encryption
- Stream encryption
- Multi-recipient encryption
- Two-factor encryption

#### Decryption Module (`src/modules/decrypt.sh`)
- File decryption
- Directory decryption
- Stream decryption
- Signature verification

#### Secrets Module (`src/modules/secrets.sh`)
- Secret storage
- Secret retrieval
- Secret listing and search
- Metadata management
- Expiration handling

#### Keys Module (`src/modules/keys.sh`)
- Key generation
- Key rotation
- Key import/export
- Key health checks

#### Export Module (`src/modules/export.sh`)
- Export to JSON/YAML/ENV
- Import from various formats
- Docker/Kubernetes integration
- QR code generation

#### Backup Module (`src/modules/backup.sh`)
- Backup creation
- Backup restoration
- Cloud synchronization
- Backup verification

### Library Layer

#### Common Library (`src/lib/common.sh`)
Provides shared functionality:
- Configuration management
- Directory initialization
- Dependency checking
- Message formatting
- Audit logging
- Encryption/decryption wrappers
- File operations
- Checksum calculations
- Metadata management

### Storage Layer

#### File System Structure
```
~/.ade/
├── keys/           # Encryption keys
│   ├── default.key
│   └── *.key
├── secrets/        # Encrypted secrets
│   └── *.enc
├── metadata/       # Secret/key metadata
│   └── *.json
├── versions/       # Secret version history
│   └── */
├── signatures/     # Digital signatures
│   └── *.sig
├── config          # User configuration
├── audit.log       # Audit trail
└── history         # Command history
```

## Data Flow

### Encryption Flow
```
Input → Validation → Compression → Encryption → Storage → Audit
```

### Decryption Flow
```
Storage → Key Validation → Decryption → Decompression → Output
```

### Secret Management Flow
```
Secret Input → Encryption → Metadata Creation → Storage → Indexing
```

## Security Architecture

### Encryption
- **Algorithm**: AES-256-CBC with salt
- **Key Size**: 256-bit
- **Key Storage**: File system with restricted permissions (600)
- **Password Mode**: PBKDF2 for password-based encryption

### Access Control
- Directory permissions: 700
- File permissions: 600
- Key file validation
- Audit logging of all operations

### Data Protection
- Secure deletion with shred
- Checksum verification
- Digital signatures
- Expiration management

## Module Communication

### Inter-module Communication
Modules communicate through:
1. **Shared Library**: Common functions in `common.sh`
2. **Environment Variables**: Configuration and paths
3. **File System**: Shared data directories
4. **Exit Codes**: Success/failure indication

### Module API Contract
Each module must:
1. Source the common library
2. Implement a main command handler
3. Provide help information
4. Handle errors gracefully
5. Return appropriate exit codes

## Extensibility

### Adding New Modules

1. Create module file: `src/modules/newmodule.sh`
2. Implement module interface:
```bash
#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"

# Module functions
module_function() {
    # Implementation
}

# Command handler
case "${1:-}" in
    command)
        module_function "$@"
        ;;
    *)
        show_module_help
        ;;
esac
```

3. Register in dispatcher
4. Add help documentation
5. Create tests

### Plugin Architecture
Future support for plugins through:
- Plugin directory scanning
- Dynamic module loading
- Hook system for events
- External module API

## Performance Considerations

### Optimization Strategies
- Lazy loading of modules
- Caching of frequently used data
- Efficient file operations
- Minimal external dependencies

### Scalability
- Handles large files through streaming
- Batch operations support
- Parallel processing capability
- Efficient key management

## Testing Architecture

### Test Structure
```
tests/
├── basic.bats          # Core functionality
├── modules/            # Module-specific tests
│   ├── encrypt.bats
│   └── secrets.bats
└── test_helper.bash    # Shared test utilities
```

### Test Coverage
- Unit tests for individual functions
- Integration tests for workflows
- Security tests for vulnerabilities
- Performance tests for scalability

## Standalone Library Architecture

### Library Design
The standalone library (`lib/ade-crypt-lib.sh`) is a single-file implementation that:
- Includes core encryption functions
- Auto-initializes on load
- Exports functions for external use
- Maintains backward compatibility

### Library API
```bash
# Core functions
ade_encrypt_file()
ade_decrypt_file()
ade_store_secret()
ade_get_secret()
ade_generate_key()
```

## Future Architecture Considerations

### Planned Enhancements
1. **Service Architecture**: REST API for remote operations
2. **Database Backend**: Optional database storage
3. **Multi-user Support**: User management and permissions
4. **Hardware Security**: HSM/TPM integration
5. **Distributed Operations**: Multi-node synchronization

### Compatibility
- Backward compatibility maintained
- Version checking for upgrades
- Migration tools for data
- Legacy command support

## Conclusion

The modular architecture of ADE crypt provides a robust, extensible foundation for secure file and secret management. The clear separation of concerns, comprehensive testing, and security-first design ensure reliability and maintainability.