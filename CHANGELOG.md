# Changelog

All notable changes to ADE crypt will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive test suite with 120+ tests across 12 test files
- Security audit tool (`scripts/security-audit.sh`) for vulnerability scanning
- Automated security fix tool (`scripts/fix-security.sh`)
- Performance benchmarking tool (`scripts/performance-test.sh`)
- Test coverage reporting with bashcov integration
- Test summary tool for quick coverage overview
- Makefile targets for security, performance, and quality checks
- Pre-commit hooks configuration for automated checks
- Security documentation (SECURITY.md)

### Changed
- Enhanced ShellCheck linting with automatic installation
- Improved test runner to handle all test files properly
- Updated documentation with test coverage information
- Standardized project name to "ADE crypt" (with space)

### Fixed
- ShellCheck warnings across all shell scripts (SC2155, SC2086, SC2250, SC2181, SC2206, SC2162, SC2012, SC1090)
- Security vulnerabilities including:
  - Predictable temporary file names
  - Missing trap handlers for cleanup
  - Insecure file deletion operations
  - Unquoted variables
- Test helper environment issues
- Module sourcing with proper shellcheck directives

## [2.1.0] - 2024-01-12

### Added
- Multi-recipient encryption for team collaboration
- Two-factor authentication combining keys and passwords
- Streaming encryption for pipeline operations
- Digital signatures for file authenticity
- Cloud synchronization (AWS S3, Google Drive, Dropbox)
- Secret versioning with rollback capability
- Audit logging for compliance tracking
- Interactive mode for beginners
- Docker/Kubernetes integration
- Git hooks for automatic encryption
- QR code sharing for secure secret distribution
- Compression support (gzip, bzip2, xz)
- Batch processing for bulk operations
- Key expiration and automatic rotation
- Import/Export in JSON, YAML, ENV formats

### Changed
- Modular architecture with separate modules for each feature
- Enhanced configuration file support
- Improved error handling and logging
- Better progress indicators for large operations

## [2.0.0] - 2023-12-01

### Added
- Complete rewrite with modular architecture
- Separate library package for integration
- Comprehensive documentation
- Make-based build system
- BATS test framework integration

### Changed
- Restructured codebase into src/, lib/, docs/, tests/
- Improved command-line interface
- Better error messages and user feedback

## [1.0.0] - 2023-06-01

### Added
- Initial release
- Basic file encryption/decryption
- Secret storage functionality
- Key generation and management
- Backup and restore capabilities

[Unreleased]: https://github.com/phdsystems/ade-crypt/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/phdsystems/ade-crypt/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/phdsystems/ade-crypt/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/phdsystems/ade-crypt/releases/tag/v1.0.0