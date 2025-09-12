# Testing and Quality Assurance

## Overview

ADE-Crypt uses a comprehensive testing and quality assurance pipeline with industry-standard tools specifically designed for bash/shell projects.

## Tools Used

### 1. ShellCheck (Static Analysis)
- **Purpose**: Static analysis and linting for bash scripts
- **What it catches**: Syntax errors, common mistakes, style issues
- **Config**: `.shellcheckrc`

### 2. BATS (Testing Framework)  
- **Purpose**: Automated testing for bash scripts
- **Features**: Unit tests, integration tests, TAP output
- **Location**: `tests/` directory

### 3. Pre-commit Hooks
- **Purpose**: Run checks before commits
- **Config**: `.pre-commit-config.yaml`
- **Includes**: ShellCheck, file formatting, security checks

### 4. GitHub Actions (CI/CD)
- **Purpose**: Automated testing on every push/PR
- **Config**: `.github/workflows/ci.yml`
- **Jobs**: Lint, test, security scan, integration tests

### 5. Bashcov (Coverage)
- **Purpose**: Code coverage reporting
- **Output**: HTML reports showing test coverage

## Running Tests

### Make Commands

ADE crypt provides convenient make targets for all testing and development tasks:

```bash
# Testing
make test        # Run all tests via BATS
make lint        # Run ShellCheck linting  
make coverage    # Generate coverage report
make ci          # Full CI pipeline (lint + test + integration)
make dev         # Quick development cycle (lint + test)

# Environment
make setup       # Set up development environment
make check-deps  # Check all dependencies
make clean       # Clean temporary files
make help        # Show all available targets
```

### Script Commands

### Quick Test
```bash
# Run all tests
./scripts/test.sh
# or
make test

# Run specific test file
./scripts/test.sh basic.bats

# Run with verbose output
VERBOSE=true ./scripts/test.sh
```

### Linting
```bash
# Run ShellCheck on all scripts
./scripts/lint.sh
# or
make lint

# Check specific file
shellcheck src/modules/encrypt.sh
```

### Coverage
```bash
# Generate coverage report
./scripts/coverage.sh
# or
make coverage

# View report
open coverage/index.html
```

## Test Structure

```
tests/
├── test_helper.bash      # Common test functions
├── basic.bats           # Basic functionality tests
└── modules/             # Module-specific tests
    ├── encrypt.bats
    └── secrets.bats
```

## Writing Tests

### Test File Template
```bash
#!/usr/bin/env bats
# Description of test suite

load test_helper

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "description of what is being tested" {
    # Arrange
    echo "test data" > input.txt
    
    # Act
    run run_ade_crypt encrypt file input.txt
    
    # Assert
    assert_success
    assert_file_exists input.txt.enc
}
```

### Test Helper Functions
```bash
# Environment setup
setup_test_env()          # Clean test environment
teardown_test_env()       # Cleanup after test

# Command execution
run_ade_crypt()          # Run ade-crypt with timeout
has_command()            # Check if command exists
require_command()        # Skip test if dependency missing

# Test data creation
create_test_secret()     # Create test secret
create_test_key()        # Generate test key

# Assertions
assert_success()         # Command succeeded (exit 0)
assert_failure()         # Command failed (exit non-zero)
assert_file_exists()     # File exists
assert_file_contains()   # File contains text
assert_output_contains() # Output contains text
```

## Test Categories

### 1. Unit Tests
Test individual functions/modules in isolation.

```bash
@test "encrypt module handles invalid file" {
    run run_ade_crypt encrypt file nonexistent.txt
    assert_failure
    assert_output_contains "File not found"
}
```

### 2. Integration Tests
Test interaction between modules and end-to-end workflows.

```bash
@test "full encrypt-decrypt workflow" {
    echo "test data" > input.txt
    
    # Encrypt
    run run_ade_crypt encrypt file input.txt
    assert_success
    
    # Decrypt
    rm input.txt
    run run_ade_crypt decrypt file input.txt.enc
    assert_success
    assert_file_contains input.txt "test data"
}
```

### 3. Security Tests
Test security features and potential vulnerabilities.

```bash
@test "secret storage is encrypted" {
    create_test_secret "test" "secret-value"
    
    # Secret file should not contain plaintext
    run grep -q "secret-value" "$ADE_CRYPT_HOME/secrets/test.enc"
    assert_failure
}
```

## CI/CD Pipeline

The GitHub Actions workflow includes:

1. **Lint Job**: ShellCheck on all scripts
2. **Test Job**: BATS tests on multiple Ubuntu versions
3. **Security Job**: Security scanning
4. **Integration Job**: End-to-end testing
5. **Release Job**: Package creation (main branch only)

### Local CI Simulation
```bash
# Run the same checks as CI
./scripts/lint.sh && ./scripts/test.sh
# or
make ci

# Quick development cycle
make dev  # Equivalent to: make lint test
```

## Pre-commit Setup

Install pre-commit hooks to catch issues before committing:

```bash
# Install pre-commit (one time)
pip install pre-commit

# Install hooks (in project directory)
pre-commit install

# Run manually
pre-commit run --all-files
```

## Coverage Reports

### Generating Coverage
```bash
# Install bashcov (Ruby required)
gem install bashcov

# Generate report
./scripts/coverage.sh
```

### Coverage Targets
- **Unit Tests**: >80% line coverage
- **Integration Tests**: >60% feature coverage
- **Critical Paths**: 100% coverage (encryption/decryption)

### Interpreting Coverage
- **Green**: Well tested
- **Yellow**: Partially tested  
- **Red**: Untested (needs attention)

## Common Issues

### Test Failures
```bash
# Debug failing test
VERBOSE=true ./scripts/test.sh failing-test.bats

# Run single test
bats tests/basic.bats -f "specific test name"
```

### Linting Failures
```bash
# See detailed ShellCheck output
shellcheck -f gcc src/modules/encrypt.sh

# Ignore specific warning (if justified)
# shellcheck disable=SC2034
UNUSED_VAR="value"
```

### Environment Issues
```bash
# Check dependencies
./scripts/test.sh --version

# Clean test environment
rm -rf /tmp/ade-crypt-test-*
```

## Best Practices

### Test Writing
1. **One assertion per test**: Keep tests focused
2. **Descriptive names**: `@test "encrypt with compression creates smaller file"`
3. **Arrange-Act-Assert**: Structure tests clearly
4. **Clean environment**: Each test should be independent
5. **Mock external deps**: Don't rely on external services

### Code Quality
1. **Follow ShellCheck**: Fix all warnings when possible
2. **Use bash strict mode**: `set -euo pipefail`
3. **Quote variables**: `"$variable"` not `$variable`
4. **Check return codes**: `command || handle_error`
5. **Document complex logic**: Comments for non-obvious code

### CI/CD
1. **Fast feedback**: Keep tests under 5 minutes
2. **Parallel execution**: Run tests in parallel when possible
3. **Fail fast**: Stop on first critical failure
4. **Clear reports**: Make failures easy to understand
5. **Consistent environment**: Pin tool versions

## Performance Testing

### Load Testing
```bash
# Test with large files
dd if=/dev/zero of=large.dat bs=1M count=100
./ade-crypt encrypt file large.dat

# Test many operations
for i in {1..100}; do
    echo "data-$i" | ./ade-crypt secrets store "test-$i"
done
```

### Benchmarking
```bash
# Time operations
time ./ade-crypt encrypt file large-file.txt
time ./ade-crypt secrets get large-secret
```

## Security Testing

### Penetration Testing
```bash
# Test with malicious inputs
./ade-crypt secrets store "../../../etc/passwd" "evil"
./ade-crypt secrets store "'; rm -rf / #" "injection"
```

### Audit Trail Testing
```bash
# Verify audit logging
./ade-crypt secrets store test-secret
grep "STORE" ~/.ade/audit.log
```

This comprehensive testing setup ensures ADE-Crypt maintains high quality and reliability!