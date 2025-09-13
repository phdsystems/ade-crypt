# ADR-001: Encryption Algorithm Standards

## Status
Accepted

## Context
ADE crypt is a security-critical tool for encrypting sensitive data. The choice of encryption algorithms directly impacts the security posture of all encrypted data. We need to establish clear standards for which algorithms are approved for use and which should be avoided due to security vulnerabilities.

Recent cryptographic research and industry standards have identified several algorithms as either deprecated (due to vulnerabilities) or recommended (due to proven security and performance characteristics).

## Decision
We will restrict encryption algorithms to the following approved list:

**Approved Symmetric Algorithms:**
- `aes-256-cbc` - AES with 256-bit key in Cipher Block Chaining mode
- `aes-256-gcm` - AES with 256-bit key in Galois/Counter Mode (preferred for new implementations)
- `aes-256-ofb` - AES with 256-bit key in Output Feedback mode
- `aes-256-cfb` - AES with 256-bit key in Cipher Feedback mode  
- `chacha20-poly1305` - ChaCha20 stream cipher with Poly1305 authenticator

**Prohibited Algorithms:**
- Any algorithm with key length < 256 bits (e.g., `aes-128-*`)
- Deprecated algorithms: `des`, `3des`, `rc4`, `blowfish`
- Weak hash functions: `md5`, `sha1` (except where required for compatibility)

**Rationale:**
- 256-bit keys provide adequate security against current and foreseeable attacks
- AES-256-GCM provides both confidentiality and authenticity
- ChaCha20-Poly1305 offers excellent performance on systems without AES hardware acceleration
- Smaller key sizes are vulnerable to advances in cryptanalysis and quantum computing

## Consequences

**Positive:**
- Consistent security posture across all encrypted data
- Future-proofed against cryptographic advances
- Clear guidance for developers
- Automated validation prevents accidental use of weak algorithms

**Negative:**
- May break compatibility with systems requiring legacy algorithms
- Slightly larger keys may impact performance in resource-constrained environments
- Developers must be educated about approved algorithms

**Migration:**
- Existing data encrypted with non-approved algorithms should be re-encrypted
- New code must only use approved algorithms
- Legacy compatibility should be handled through explicit opt-in mechanisms

## Security Considerations
This decision directly impacts the confidentiality of all encrypted data. Using weak algorithms could lead to:
- Compromise of encrypted secrets and keys
- Unauthorized access to user data
- Regulatory compliance failures
- Loss of user trust

The approved algorithms provide:
- Resistance to known cryptographic attacks
- Adequate security margins for at least 20 years
- Industry-standard compliance (FIPS 140-2, NIST recommendations)

## Validation Rules
```yaml
rules:
  - id: approved-algorithms
    description: Only approved encryption algorithms may be used
    automated: true
    script: scripts/validate-architecture.sh
  
  - id: no-weak-algorithms  
    description: Prohibited algorithms must not appear in code
    automated: true
    script: scripts/validate-architecture.sh
```

## References
- [NIST Special Publication 800-57 Part 1](https://csrc.nist.gov/publications/detail/sp/800-57-part-1/rev-5/final)
- [OWASP Cryptographic Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)
- [RFC 7539: ChaCha20 and Poly1305](https://tools.ietf.org/html/rfc7539)
- [FIPS 140-2 Security Requirements](https://csrc.nist.gov/publications/detail/fips/140/2/final)