# Development Guide

## Getting Started

### Prerequisites

- Git
- Bash 4.0+
- Make
- ShellCheck (for linting)
- BATS (for testing)

### Clone and Setup

```bash
# Clone the repository
git clone https://github.com/phdsystems/ade-crypt.git
cd ade-crypt

# Install development dependencies
./scripts/install-dev-deps.sh

# Set up development environment
make setup

# Verify setup
make test
```

## Development Workflow

### 1. Make Changes

```bash
# Create feature branch
git checkout -b feature/my-feature

# Edit files
vim src/modules/mymodule.sh

# Test changes locally
./ade-crypt mymodule test
```

### 2. Quality Checks

```bash
# Run all tests (120+ tests)
make test

# Architecture validation (NEW)
make validate-arch

# Security scanning
make security

# Complete quality check
make deep-review

# Run specific test file
./scripts/test.sh basic.bats
```

### 3. Lint Code

```bash
# Run linting
make lint

# Fix specific issues
shellcheck -f gcc src/modules/mymodule.sh
```

### 4. Check Coverage

```bash
# Generate coverage report
make coverage

# View report
open coverage/index.html
```

### 5. Run Full CI

```bash
# Run complete CI pipeline locally
make ci
```

## Make Commands

### Core Commands

```bash
make help        # Show all available targets
make test        # Run all 120+ tests
make lint        # Run ShellCheck linting
make coverage    # Generate coverage report
make ci          # Full CI pipeline
make dev         # Quick dev cycle (lint + test)
```

### Security & Quality Commands

```bash
make security    # Run security vulnerability scan
make performance # Run performance benchmarks
make fix-security # Auto-fix common security issues
make all-checks  # Run ALL quality checks (lint + test + security + performance)
make metrics     # Show code metrics and statistics
```

### Setup Commands

```bash
make setup       # Set up development environment
make check-deps  # Check dependencies
make install-dev # Install dev dependencies
make clean       # Clean temporary files
```

### Architecture & Design Commands (NEW)

```bash
make validate-arch    # Validate architectural decisions
make deep-review     # Comprehensive validation
# See docs/adr/ for Architectural Decision Records
```

### Build Commands

```bash
make install     # Install system-wide
make release     # Create release package
make docs        # Generate documentation
```

## Project Structure

### Source Organization

```
src/
├── core/           # Core functionality
│   ├── dispatcher.sh   # Command routing
│   └── help.sh        # Help system
├── lib/            # Shared libraries
│   └── common.sh      # Common functions
└── modules/        # Feature modules
    ├── encrypt.sh     # Encryption module
    ├── decrypt.sh     # Decryption module
    ├── secrets.sh     # Secrets management
    ├── keys.sh        # Key management
    ├── export.sh      # Export/import
    └── backup.sh      # Backup/restore
```

### Test Organization

```
tests/
├── test_helper.bash    # Test utilities
├── basic.bats         # Basic tests
└── modules/           # Module tests
    ├── encrypt.bats
    └── secrets.bats
```

## Adding New Features

### Creating a New Module

1. **Create module file:**
```bash
touch src/modules/newfeature.sh
chmod +x src/modules/newfeature.sh
```

2. **Implement module structure:**
```bash
#!/bin/bash
# New Feature Module

# Source common library
source "$(dirname "$0")/../lib/common.sh"

# Module functions
do_something() {
    local input="$1"
    # Implementation
    success_msg "Operation completed"
}

# Command handler
case "${1:-}" in
    action)
        shift
        do_something "$@"
        ;;
    help)
        echo "Usage: newfeature {action} [options]"
        ;;
    *)
        error_exit "Unknown command: ${1:-}"
        ;;
esac
```

3. **Register in dispatcher:**
```bash
# Edit src/core/dispatcher.sh
# Add to dispatch_module function:
newfeature)
    "$MODULES_DIR/newfeature.sh" "$@"
    ;;
```

4. **Add help documentation:**
```bash
# Edit src/core/help.sh
# Add to show_module_help function
```

5. **Create tests:**
```bash
# Create tests/modules/newfeature.bats
#!/usr/bin/env bats

load ../test_helper

@test "newfeature action works" {
    run run_ade_crypt newfeature action test
    assert_success
}
```

### Adding Functions to Common Library

1. **Add function to `src/lib/common.sh`:**
```bash
# New utility function
my_utility_function() {
    local param="$1"
    # Implementation
    echo "Result"
}
```

2. **Export function:**
```bash
export -f my_utility_function
```

3. **Add to library documentation:**
```bash
# Update lib/ade-crypt-lib.sh if needed
```

## Testing

### Test Coverage Overview

- **Total Tests**: 120+ tests across 12 test files
- **Script Coverage**: 8/11 scripts tested (73%)
- **Module Coverage**: 3/6 modules tested (50%)
- **Line Coverage**: 16.19% (397/2452 lines)

### Writing Tests

#### Test Structure
```bash
#!/usr/bin/env bats

load test_helper

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "description of test" {
    # Arrange
    create_test_file "input.txt"
    
    # Act
    run run_ade_crypt encrypt file input.txt
    
    # Assert
    assert_success
    assert_file_exists "input.txt.enc"
}
```

#### Test Helpers
```bash
# Available helpers
setup_test_env()        # Initialize test environment
teardown_test_env()     # Clean up after test
run_ade_crypt()        # Run ade-crypt with timeout
create_test_file()      # Create test file
create_test_secret()    # Create test secret
assert_success()        # Check exit code 0
assert_failure()        # Check exit code non-zero
assert_file_exists()    # Check file exists
assert_output_contains() # Check output contains text
```

### Running Tests

```bash
# Run all tests
make test

# Run specific test file
./scripts/test.sh tests/modules/encrypt.bats

# Run single test
bats tests/basic.bats -f "specific test name"

# Debug mode
VERBOSE=true ./scripts/test.sh
```

## Code Style Guide

### Shell Script Best Practices

1. **Use strict mode:**
```bash
set -euo pipefail
```

2. **Quote variables:**
```bash
# Good
echo "$variable"

# Bad
echo $variable
```

3. **Use local variables:**
```bash
function_name() {
    local var="value"
    # Use var
}
```

4. **Check command existence:**
```bash
if command -v tool >/dev/null 2>&1; then
    # Use tool
fi
```

5. **Handle errors:**
```bash
if ! command; then
    error_exit "Command failed"
fi
```

### Naming Conventions

- **Files**: `lowercase_with_underscores.sh`
- **Functions**: `lowercase_with_underscores()`
- **Constants**: `UPPERCASE_WITH_UNDERSCORES`
- **Local variables**: `lowercase_with_underscores`

### Comments

```bash
#!/bin/bash
# Module: Feature Name
# Description: What this module does

# Function: do_something
# Purpose: Performs specific action
# Parameters:
#   $1 - Input parameter
# Returns:
#   0 - Success
#   1 - Failure
do_something() {
    # Implementation details
}
```

## Debugging

### Debug Mode

```bash
# Enable debug output
export ADE_LIB_DEBUG=1

# Run with bash debug
bash -x ade-crypt command

# Use debug function
debug_output "Variable value: $var"
```

### Common Issues

#### ShellCheck Warnings
```bash
# See all warnings
shellcheck src/modules/*.sh

# Ignore specific warning
# shellcheck disable=SC2034
UNUSED_VAR="value"
```

#### Test Failures
```bash
# Get detailed output
VERBOSE=true make test

# Check test environment
ls -la /tmp/ade-crypt-test-*
```

## Release Process

### Version Bumping

1. Update version in:
   - `src/lib/common.sh`
   - `lib/ade-crypt-lib.sh`
   - `README.md`

2. Update changelog:
   - Add version section
   - List changes
   - Credit contributors

### Creating Release

```bash
# Create release branch
git checkout -b release/v2.2.0

# Update version numbers
vim src/lib/common.sh

# Run full test suite
make ci

# Create release package
make release

# Tag release
git tag -a v2.2.0 -m "Release version 2.2.0"

# Push to GitHub
git push origin release/v2.2.0
git push origin v2.2.0
```

## Continuous Integration

### GitHub Actions Workflow

The CI pipeline runs on every push and PR:

1. **Lint Job**: ShellCheck on all scripts
2. **Test Job**: BATS tests on multiple OS versions
3. **Security Job**: Security scanning
4. **Integration Job**: End-to-end testing
5. **Release Job**: Package creation (main branch)

### Local CI Simulation

```bash
# Run same checks as CI
make ci

# Individual steps
make lint
make test
make integration
```

## Documentation

### Updating Documentation

1. **User-facing docs**: Update `docs/USER_GUIDE.md`
2. **API changes**: Update `docs/API_REFERENCE.md`
3. **Architecture changes**: Update `docs/ARCHITECTURE.md`
4. **Installation**: Update `docs/INSTALLATION.md`

### Documentation Standards

- Use clear, concise language
- Include code examples
- Keep formatting consistent
- Update table of contents
- Test all examples

## Contributing

### Contribution Process

1. Fork the repository
2. Create feature branch
3. Make changes
4. Add tests
5. Run `make ci`
6. Submit pull request

### Pull Request Guidelines

- Clear description of changes
- Reference related issues
- Include test coverage
- Pass all CI checks
- Follow code style guide

## Resources

### Tools

- [ShellCheck](https://www.shellcheck.net/) - Shell script linter
- [BATS](https://github.com/bats-core/bats-core) - Bash testing framework
- [Bashcov](https://github.com/infertux/bashcov) - Code coverage

### References

- [Bash Manual](https://www.gnu.org/software/bash/manual/)
- [Advanced Bash Guide](https://tldp.org/LDP/abs/html/)
- [Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

## Support

For development questions:

1. Check existing documentation
2. Search GitHub issues
3. Ask in discussions
4. Create an issue with details