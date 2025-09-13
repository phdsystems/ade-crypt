# ADR-002: Key Storage Security Requirements

## Status
Accepted

## Context
Cryptographic keys are the most critical security assets in ADE crypt. Improper key storage can completely compromise the security of encrypted data, regardless of how strong the encryption algorithms are. We need clear standards for where keys can be stored, how they should be protected, and what locations are prohibited.

Common security vulnerabilities in key storage include:
- Keys stored in predictable locations accessible to other users
- Keys stored in temporary directories that may be readable by other processes
- Keys stored with incorrect file permissions
- Keys embedded in code or configuration files

## Decision
We establish the following key storage security requirements:

**Approved Storage Locations:**
- User's secure directory: `$HOME/.ade/keys/` (permissions 700)
- XDG-compliant location: `$XDG_DATA_HOME/ade-crypt/keys/` (permissions 700) 
- Temporary files: Only using `mktemp` with secure templates
- System keyring integration where available (macOS Keychain, Linux Secret Service)

**Prohibited Storage Locations:**
- World-readable temporary directories: `/tmp/`, `/var/tmp/`, `/dev/shm/`, `/usr/tmp/`
- Shared directories: `/home/shared/`, `/opt/`, `/usr/local/share/`
- Version control directories (already covered by .gitignore)
- Hardcoded absolute paths that assume specific usernames or system layouts

**File Permission Requirements:**
- Key files: `600` (owner read/write only) or `400` (owner read only)
- Key directories: `700` (owner access only)
- No group or world permissions on key-related files

**Temporary File Requirements:**
- Must use `mktemp` with appropriate templates
- Must register cleanup handlers with `trap`
- Must use `shred` for secure deletion when available

## Consequences

**Positive:**
- Keys are protected from unauthorized access by other users
- Consistent key storage patterns across different environments
- Automatic cleanup of temporary key files
- Defense against common key compromise vectors

**Negative:**  
- May require migration of existing keys to compliant locations
- Additional complexity in handling different operating system conventions
- May not work correctly in containerized environments with unusual permission models

**Implementation Requirements:**
- All modules must validate key file permissions before use
- Key creation functions must set appropriate permissions atomically
- Temporary key files must be tracked for cleanup

## Security Considerations
This decision protects against several attack vectors:
- **Local privilege escalation**: Other users cannot read keys from shared directories
- **Temporary file attacks**: Race conditions and predictable naming prevented
- **Information disclosure**: Keys are not accidentally committed or shared
- **Forensic analysis**: Proper cleanup reduces key recovery from deleted files

Risk mitigation:
- Keys stored with minimal required permissions
- Temporary storage uses cryptographically secure random names
- Automatic cleanup prevents key material from persisting unnecessarily
- Multiple storage options provide flexibility while maintaining security

## Validation Rules
```yaml
rules:
  - id: no-insecure-key-paths
    description: Keys must not be stored in world-readable locations  
    automated: true
    script: scripts/validate-architecture.sh
    
  - id: no-hardcoded-paths
    description: Key paths must not be hardcoded to specific users
    automated: true
    script: scripts/validate-architecture.sh
    
  - id: secure-temp-files
    description: Temporary files must use mktemp, not predictable names
    automated: true
    script: scripts/validate-architecture.sh
```

## References
- [OWASP Key Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Key_Management_Cheat_Sheet.html)
- [NIST SP 800-57: Recommendations for Key Management](https://csrc.nist.gov/publications/detail/sp/800-57-part-1/rev-5/final)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/)
- [Secure Programming for Linux: Temporary Files](https://dwheeler.com/secure-programs/Secure-Programs-HOWTO/avoid-race.html)