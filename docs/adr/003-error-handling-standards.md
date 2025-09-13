# ADR-003: Error Handling Standards

## Status
Accepted

## Context
Consistent and secure error handling is critical for a security tool. Poor error handling can lead to:
- Information disclosure through verbose error messages
- Incomplete cleanup of sensitive data
- Inconsistent user experience
- Security vulnerabilities through unexpected program states

ADE crypt needs standardized error handling patterns that ensure security while providing useful feedback to users.

## Decision
We establish the following error handling standards for all modules:

**Required Error Handling Functions:**
Every module must implement or import:
- `error_exit()` - Exit with error message and cleanup
- `cleanup()` - Secure cleanup of temporary files and sensitive data
- Proper `trap` handlers for EXIT, INT, TERM signals

**Error Handling Patterns:**
- Use `set -euo pipefail` in all scripts for automatic error propagation
- Validate all user inputs before processing
- Check command return codes explicitly: `command || error_exit "Command failed"`
- Never expose sensitive information in error messages
- Always cleanup temporary files and sensitive data on error

**Secure Error Messages:**
- Generic messages for users: "Operation failed"
- Detailed logging for developers (if logging enabled)
- Never include file paths, keys, or sensitive data in user-visible errors
- Use consistent error codes for programmatic handling

**Cleanup Requirements:**
- All temporary files must be tracked and cleaned up
- Use `shred` for secure deletion of sensitive files when available
- Reset terminal state if modified
- Clear sensitive variables before exit

## Consequences

**Positive:**
- Consistent error handling across all modules
- Prevents information leakage through error messages  
- Ensures cleanup of sensitive data on failure
- Improves reliability and user experience
- Enables better testing and debugging

**Negative:**
- More verbose code due to explicit error checking
- Generic error messages may make debugging harder for users
- Additional complexity in implementing cleanup handlers

**Implementation Requirements:**
- All modules must pass error handling validation checks
- Error messages must be reviewed for information disclosure
- Cleanup functions must be tested to ensure they run properly

## Security Considerations
This decision addresses several security concerns:
- **Information Disclosure**: Generic error messages prevent leaking system information
- **Incomplete Cleanup**: Trap handlers ensure sensitive data is cleaned up even on unexpected termination
- **State Corruption**: Explicit error checking prevents programs from continuing in invalid states
- **Resource Leaks**: Proper cleanup prevents temporary files from accumulating

The standardized approach ensures that security-critical cleanup always occurs, even when operations fail unexpectedly.

## Validation Rules
```yaml
rules:
  - id: required-error-functions
    description: All modules must have error_exit, cleanup functions
    automated: true
    script: scripts/validate-architecture.sh
    
  - id: proper-error-propagation  
    description: Scripts must use set -e or explicit error checking
    automated: true
    script: scripts/validate-architecture.sh
    
  - id: trap-handlers
    description: Scripts with temp files must have trap handlers
    automated: true
    script: scripts/validate-architecture.sh
```

**Manual Review Required:**
- Error message content review for information disclosure
- Cleanup function testing
- Signal handler behavior verification

## References
- [OWASP Error Handling](https://owasp.org/www-community/Improper_Error_Handling)  
- [Google Shell Style Guide - Error Handling](https://google.github.io/styleguide/shellguide.html#s7.4-error-handling)
- [Bash Error Handling](https://mywiki.wooledge.org/BashFAQ/105)
- [Signal Safety](https://man7.org/linux/man-pages/man7/signal-safety.7.html)