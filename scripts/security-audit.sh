#!/bin/bash
# Security audit script for ADE crypt
# Performs comprehensive security analysis including trap handlers, temp files, and secrets

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Get project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"

# Counters
ISSUES_FOUND=0
WARNINGS=0

echo -e "${CYAN}${BOLD}ADE crypt Security Audit${NC}"
echo -e "${CYAN}========================${NC}"
echo ""

# 1. Check for trap handlers (IMMEDIATE)
echo -e "${CYAN}[1/7] Checking for trap handlers...${NC}"
FILES_WITHOUT_TRAPS=()
for file in src/**/*.sh; do
    if [ -f "${file}" ]; then
        # Check if file has temp files or cleanup needs
        if grep -q "/tmp/\|mktemp\|cleanup\|rm -f" "${file}" 2>/dev/null; then
            # Check if it has trap handlers
            if ! grep -q "^trap\|^\s*trap" "${file}" 2>/dev/null; then
                FILES_WITHOUT_TRAPS+=("${file}")
            fi
        fi
    fi
done

if [ ${#FILES_WITHOUT_TRAPS[@]} -gt 0 ]; then
    echo -e "${RED}✗ Files with cleanup operations but no trap handlers:${NC}"
    for file in "${FILES_WITHOUT_TRAPS[@]}"; do
        echo -e "  ${YELLOW}⚠${NC} ${file}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    done
else
    echo -e "${GREEN}✓ All files with cleanup operations have trap handlers${NC}"
fi
echo ""

# 2. Check for predictable temp files (IMMEDIATE)
echo -e "${CYAN}[2/7] Scanning for predictable temp files...${NC}"
PREDICTABLE_TEMPS=$(grep -rn '\$\$\|/tmp/[a-zA-Z_]*\$' --include="*.sh" src/ 2>/dev/null || true)
if [ -n "${PREDICTABLE_TEMPS}" ]; then
    echo -e "${RED}✗ Predictable temp file patterns found:${NC}"
    echo "${PREDICTABLE_TEMPS}" | while IFS= read -r line; do
        echo -e "  ${YELLOW}⚠${NC} ${line}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    done
    echo -e "  ${CYAN}Fix: Use mktemp instead of \$\$ for temp files${NC}"
else
    echo -e "${GREEN}✓ No predictable temp file patterns found${NC}"
fi
echo ""

# 3. Check for insecure file operations (IMMEDIATE)
echo -e "${CYAN}[3/7] Checking for insecure file operations...${NC}"
INSECURE_RM=$(grep -rn 'rm -rf\|rm -f' --include="*.sh" src/ | grep -v "shred\|secure_delete" || true)
if [ -n "${INSECURE_RM}" ]; then
    echo -e "${YELLOW}⚠ Non-secure file deletions found:${NC}"
    echo "${INSECURE_RM}" | head -5 | while IFS= read -r line; do
        echo -e "  ${line}"
        WARNINGS=$((WARNINGS + 1))
    done
    echo -e "  ${CYAN}Consider using shred for sensitive files${NC}"
else
    echo -e "${GREEN}✓ File deletions use secure methods${NC}"
fi
echo ""

# 4. Check for hardcoded secrets patterns (IMPORTANT)
echo -e "${CYAN}[4/7] Scanning for potential hardcoded secrets...${NC}"
# Exclude false positives: variable names, paths, and boolean values
SECRET_PATTERNS=$(grep -riE '(password|passwd|pwd|secret|key|token|api_key|apikey|auth|credential)(\s*)=(\s*)["'"'"'][^"'"'"']+["'"'"']' --include="*.sh" src/ 2>/dev/null | \
    grep -v '="${[A-Z_]*}\|:-false}\|:-true}\|/default\.key\|\.pem"\|use_password\|private_key="${KEYS_DIR}\|new_key="${KEYS_DIR}' || true)
if [ -n "${SECRET_PATTERNS}" ]; then
    echo -e "${RED}✗ Potential hardcoded secrets found:${NC}"
    echo "${SECRET_PATTERNS}" | head -5 | while IFS= read -r line; do
        echo -e "  ${YELLOW}⚠${NC} ${line}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    done
else
    echo -e "${GREEN}✓ No obvious hardcoded secrets found${NC}"
fi
echo ""

# 5. Check for world-readable sensitive files
echo -e "${CYAN}[5/7] Checking file permissions...${NC}"
PERMISSION_ISSUES=0
for dir in keys secrets encrypted; do
    if [ -d "src/test_${dir}" ] || [ -d "test_${dir}" ]; then
        find . -name "*${dir}*" -type f -perm /044 2>/dev/null | while read -r file; do
            echo -e "  ${YELLOW}⚠${NC} World-readable: ${file}"
            PERMISSION_ISSUES=$((PERMISSION_ISSUES + 1))
        done
    fi
done
if [ ${PERMISSION_ISSUES} -eq 0 ]; then
    echo -e "${GREEN}✓ No permission issues found${NC}"
fi
echo ""

# 6. Check for missing input validation
echo -e "${CYAN}[6/7] Checking for input validation...${NC}"
UNVALIDATED_INPUTS=$(grep -rn '\$1\|\$2\|\$@\|\$\*' --include="*.sh" src/ | grep -v '"\$' | grep -v "shift\|set\|local\|readonly" | head -10 || true)
if [ -n "${UNVALIDATED_INPUTS}" ]; then
    echo -e "${YELLOW}⚠ Potentially unvalidated input usage:${NC}"
    echo "${UNVALIDATED_INPUTS}" | head -5 | while IFS= read -r line; do
        echo -e "  ${line}"
        WARNINGS=$((WARNINGS + 1))
    done
else
    echo -e "${GREEN}✓ Input validation appears adequate${NC}"
fi
echo ""

# 7. Run external scanners if available
echo -e "${CYAN}[7/7] Running external security scanners...${NC}"

# Gitleaks
if command -v gitleaks >/dev/null 2>&1; then
    echo -e "${CYAN}Running Gitleaks...${NC}"
    if gitleaks detect --no-git --source . --verbose 2>/dev/null; then
        echo -e "${GREEN}✓ Gitleaks: No secrets detected${NC}"
    else
        echo -e "${RED}✗ Gitleaks found potential secrets${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
else
    echo -e "${YELLOW}⚠ Gitleaks not installed (install with: brew install gitleaks)${NC}"
fi

# TruffleHog
if command -v trufflehog >/dev/null 2>&1; then
    echo -e "${CYAN}Running TruffleHog...${NC}"
    trufflehog filesystem . --no-verification --json 2>/dev/null | jq -r '.Raw' 2>/dev/null | head -5 || true
else
    echo -e "${YELLOW}⚠ TruffleHog not installed (install with: pip install truffleHog3)${NC}"
fi

echo ""
echo -e "${CYAN}${BOLD}Security Audit Summary${NC}"
echo -e "${CYAN}=====================${NC}"

if [ ${ISSUES_FOUND} -eq 0 ] && [ ${WARNINGS} -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ No security issues found!${NC}"
    exit 0
else
    echo -e "${RED}Issues found: ${ISSUES_FOUND}${NC}"
    echo -e "${YELLOW}Warnings: ${WARNINGS}${NC}"
    echo ""
    echo -e "${CYAN}Recommendations:${NC}"
    echo "1. Add trap handlers to all scripts with temp files"
    echo "2. Replace \$\$ with mktemp for temp file creation"
    echo "3. Use shred for secure file deletion"
    echo "4. Install and configure Gitleaks for continuous secret scanning"
    echo "5. Review and validate all user inputs"
    exit 1
fi