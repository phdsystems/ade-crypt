# ADE crypt Project Structure

## Directory Layout

```
ade-crypt/
├── ade-crypt               # Main executable
│
├── src/                    # Source code
│   ├── core/              # Core functionality
│   │   ├── dispatcher.sh  # Command routing
│   │   └── help.sh        # Help system
│   │
│   ├── lib/               # Shared libraries
│   │   └── common.sh      # Common functions
│   │
│   └── modules/           # Feature modules
│       ├── encrypt.sh     # Encryption operations
│       ├── decrypt.sh     # Decryption operations
│       ├── secrets.sh     # Secret management
│       ├── keys.sh        # Key management
│       ├── export.sh      # Import/Export
│       └── backup.sh      # Backup & sync
│
├── docs/                   # Documentation
│   ├── DOCS.md            # Detailed documentation
│   └── MODULAR.md         # Modular architecture guide
│
├── tests/                  # Test suite (future)
│
├── ade-crypt -> bin/ade-crypt  # Symlink for convenience
├── install.sh             # Installation script
├── README.md              # Project readme
├── LICENSE                # MIT License
└── .gitignore            # Git ignore rules
```

## Component Descriptions

### `/bin`
User-facing executable scripts. The main `ade-crypt` script is the entry point.

### `/src/core`
Core functionality including command dispatching and help system.

### `/src/lib`
Shared libraries with common functions, variables, and utilities used across all modules.

### `/src/modules`
Feature modules, each handling a specific domain:
- **encrypt.sh**: All encryption operations
- **decrypt.sh**: All decryption operations
- **secrets.sh**: Secret storage and management
- **keys.sh**: Key generation and lifecycle
- **export.sh**: Import/export in various formats
- **backup.sh**: Backup creation and cloud sync

### `/src/legacy`
Previous versions kept for reference and rollback capability.

### `/docs`
Comprehensive documentation including usage guides and architecture details.

## Data Storage

User data is stored in `~/.ade/`:

```
~/.ade/
├── secrets/        # Encrypted secrets
├── keys/           # Encryption keys
├── metadata/       # Secret and key metadata
├── versions/       # Secret version history
├── signatures/     # Digital signatures
├── config          # User configuration
├── audit.log       # Audit trail
└── history         # Command history
```

## Module Communication

Modules communicate through:
1. **Common Library**: Shared functions in `src/lib/common.sh`
2. **Environment Variables**: Paths and settings
3. **File System**: Shared data directories
4. **Exit Codes**: Success/failure indication

## Execution Flow

1. User runs `ade-crypt` (or `bin/ade-crypt`)
2. Main script sources core components
3. Dispatcher routes to appropriate module
4. Module executes operation
5. Results returned to user

## Development Guidelines

### Adding a New Module

1. Create `src/modules/newmodule.sh`
2. Source common library
3. Implement module functions
4. Add to dispatcher in `src/core/dispatcher.sh`
5. Update help in `src/core/help.sh`
6. Document in `docs/`

### Module Template

```bash
#!/bin/bash
# Module description

source "$(dirname "$0")/../lib/common.sh"

# Module functions
function_name() {
    # Implementation
}

# Main execution
case "${1:-}" in
    command)
        shift
        function_name "$@"
        ;;
    *)
        echo "Usage: $(basename "$0") {command} [options]"
        exit 1
        ;;
esac
```

## Testing

Run tests with:
```bash
# Test individual module
./src/modules/encrypt.sh file test.txt

# Test through main executable
./bin/ade-crypt encrypt file test.txt

# Run test suite (future)
./tests/run_tests.sh
```

## Deployment

1. **Development**: Run from source
2. **Installation**: Use `install.sh` to copy to system
3. **Docker**: Build container with Dockerfile (future)
4. **Package**: Create deb/rpm packages (future)