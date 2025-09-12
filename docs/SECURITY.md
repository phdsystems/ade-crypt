# Security Best Practices for ADE crypt

## Overview

This document outlines security best practices for developing and maintaining ADE crypt.

## Security Principles

### 1. Defense in Depth
- Multiple layers of security controls
- Assume any single control can fail
- Validate at every boundary

### 2. Least Privilege
- Scripts run with minimal required permissions
- No sudo unless absolutely necessary
- Restrictive file permissions (700 for sensitive directories)

### 3. Secure by Default
- Safe defaults for all operations
- Explicit opt-in for less secure options
- Clear warnings for security implications

## Implementation Guidelines

### Temporary Files

**❌ DON'T:**
```bash
# Predictable temp files are vulnerable to attacks
temp_file="/tmp/myapp_$$"
temp_file="/tmp/data_$(date +%s)"
```

**✅ DO:**
```bash
# Use mktemp for secure random filenames
temp_file=$(mktemp /tmp/myapp_XXXXXX)
temp_dir=$(mktemp -d /tmp/myapp_XXXXXX)
```

### Cleanup Handlers

**❌ DON'T:**
```bash
# No cleanup on script exit
temp_file=$(mktemp)
# ... use temp_file ...
rm -f "${temp_file}"  # Never reached if script fails
```

**✅ DO:**
```bash
# Trap ensures cleanup even on failure
TEMP_FILES=""
cleanup() {
    for file in ${TEMP_FILES}; do
        [ -f "${file}" ] && shred -vzu "${file}" 2>/dev/null
    done
}
trap cleanup EXIT INT TERM

temp_file=$(mktemp)
TEMP_FILES="${TEMP_FILES} ${temp_file}"
```

### Secure Deletion

**❌ DON'T:**
```bash
# Simple deletion leaves data recoverable
rm -f sensitive_file.key
rm -rf secrets_directory/
```

**✅ DO:**
```bash
# Overwrite before deletion
shred -vzu sensitive_file.key 2>/dev/null || rm -f sensitive_file.key

# Use secure_delete function from common.sh
secure_delete sensitive_file.key
```

### Input Validation

**❌ DON'T:**
```bash
# Unvalidated input can cause injection
file_path=$1
cat "${file_path}"  # Path traversal risk
```

**✅ DO:**
```bash
# Validate and sanitize input
file_path=$1
# Check for directory traversal
if [[ "${file_path}" == *".."* ]]; then
    error_exit "Invalid path: directory traversal detected"
fi
# Verify file exists and is readable
[ -f "${file_path}" ] || error_exit "File not found: ${file_path}"
```

### Secret Management

**❌ DON'T:**
```bash
# Never hardcode secrets
PASSWORD="mysecretpass123"
API_KEY="sk_live_abcd1234"
```

**✅ DO:**
```bash
# Read from environment or secure storage
PASSWORD="${ADE_PASSWORD:-}"
[ -z "${PASSWORD}" ] && error_exit "Password not provided"

# Or use the secrets module
PASSWORD=$(./ade-crypt secrets get app-password)
```

### Error Handling

**❌ DON'T:**
```bash
# Silent failures hide security issues
openssl enc -aes-256-cbc -in file -out file.enc 2>/dev/null
```

**✅ DO:**
```bash
# Check and log errors
if ! openssl enc -aes-256-cbc -in file -out file.enc; then
    audit_log "ENCRYPT_FAILED: ${file}"
    error_exit "Encryption failed for ${file}"
fi
```

## Security Checklist

Before committing code, ensure:

- [ ] No hardcoded secrets or credentials
- [ ] All temp files use `mktemp`
- [ ] Trap handlers for cleanup
- [ ] Sensitive files deleted with `shred`
- [ ] Input validation on all user data
- [ ] Error handling doesn't leak information
- [ ] File permissions are restrictive
- [ ] Audit logging for security events

## Running Security Checks

```bash
# Full security audit
make security

# Scan for secrets
make gitleaks

# Auto-fix common issues
make fix-security

# Run all checks
make all-checks
```

## Security Tools

### Installed by `make install-security-tools`

1. **Gitleaks** - Scans for secrets in code and git history
2. **TruffleHog** - Entropy-based secret detection
3. **ShellCheck** - Static analysis for shell scripts
4. **hyperfine** - Performance testing (can reveal timing attacks)

### Custom Scripts

1. **security-audit.sh** - Comprehensive security scan
2. **fix-security.sh** - Automated security fixes
3. **performance-test.sh** - Performance and resource testing

## Responding to Security Issues

1. **Immediate Response**
   - Run `make security` to assess
   - Run `make fix-security` for auto-fixes
   - Manual review of remaining issues

2. **Verification**
   - Run `make test` to ensure fixes work
   - Run `make security` again to confirm
   - Review audit logs

3. **Documentation**
   - Update this document with new patterns
   - Add test cases for the vulnerability
   - Document in commit message

## Regular Security Tasks

### Daily Development
```bash
make pre-commit  # Before each commit
```

### Weekly
```bash
make all-checks  # Comprehensive analysis
```

### Before Release
```bash
make full-ci     # Complete CI pipeline
make security    # Final security check
```

## Contact

For security concerns or to report vulnerabilities:
- Open a security issue on GitHub
- Email: security@ade-crypt.org (if applicable)

## References

- [OWASP Secure Coding Practices](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)