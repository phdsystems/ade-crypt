#!/bin/bash
# Automated security fix script for ADE-Crypt
# Fixes common security issues automatically where possible

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Get project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"

echo -e "${CYAN}${BOLD}ADE-Crypt Automated Security Fixes${NC}"
echo -e "${CYAN}===================================${NC}"
echo ""

FIXES_APPLIED=0

# 1. Fix predictable temp files
echo -e "${CYAN}[1/5] Fixing predictable temp files...${NC}"
TEMP_FILE_COUNT=$(grep -r '\$\$' --include="*.sh" src/ 2>/dev/null | wc -l || echo 0)
if [ "${TEMP_FILE_COUNT}" -gt 0 ]; then
    echo "Found ${TEMP_FILE_COUNT} predictable temp file patterns"
    find src -name "*.sh" -exec sed -i.bak 's|/tmp/\([a-zA-Z_]*\)\$\$|$(mktemp /tmp/\1_XXXXXX)|g' {} \;
    rm -f src/**/*.sh.bak src/*.sh.bak
    echo -e "${GREEN}✓ Fixed predictable temp files${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
else
    echo -e "${GREEN}✓ No predictable temp files found${NC}"
fi
echo ""

# 2. Add trap handlers where missing
echo -e "${CYAN}[2/5] Adding trap handlers...${NC}"
for file in src/modules/*.sh; do
    if [ -f "${file}" ]; then
        # Check if file needs trap handler (has temp operations but no trap)
        if grep -q "/tmp/\|mktemp\|TEMP_FILES" "${file}" 2>/dev/null; then
            if ! grep -q "^trap\|^\s*trap" "${file}" 2>/dev/null; then
                echo "Adding trap handler to: $(basename "${file}")"
                # Add trap handler after source line
                sed -i.bak '/^source.*common\.sh/a\
\
# Cleanup function for trap\
cleanup_$(basename "${file}" .sh)() {\
    local exit_code=$?\
    if [ -n "${TEMP_FILES:-}" ]; then\
        for temp_file in ${TEMP_FILES}; do\
            if [ -f "${temp_file}" ]; then\
                shred -vzu "${temp_file}" 2>/dev/null || rm -f "${temp_file}"\
            fi\
        done\
    fi\
    exit ${exit_code}\
}\
\
# Set trap for cleanup\
trap cleanup_$(basename "${file}" .sh) EXIT INT TERM\
\
# Track temp files for cleanup\
TEMP_FILES=""' "${file}"
                rm -f "${file}.bak"
                echo -e "${GREEN}✓ Added trap to $(basename "${file}")${NC}"
                FIXES_APPLIED=$((FIXES_APPLIED + 1))
            fi
        fi
    fi
done
echo ""

# 3. Replace insecure rm with shred for sensitive files
echo -e "${CYAN}[3/5] Securing file deletions...${NC}"
INSECURE_RM_COUNT=$(grep -r 'rm -f.*\.key\|rm -f.*\.enc\|rm -f.*secret' --include="*.sh" src/ 2>/dev/null | wc -l || echo 0)
if [ "${INSECURE_RM_COUNT}" -gt 0 ]; then
    echo "Found ${INSECURE_RM_COUNT} insecure deletions of sensitive files"
    # Replace rm -f for key and encrypted files with shred
    find src -name "*.sh" -exec sed -i.bak \
        -e 's|rm -f \("\${*[^}]*\.key[^}]*}\*"\)|shred -vzu \1 2>/dev/null \|\| rm -f \1|g' \
        -e 's|rm -f \("\${*[^}]*\.enc[^}]*}\*"\)|shred -vzu \1 2>/dev/null \|\| rm -f \1|g' \
        {} \;
    rm -f src/**/*.sh.bak src/*.sh.bak
    echo -e "${GREEN}✓ Secured sensitive file deletions${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
else
    echo -e "${GREEN}✓ File deletions already secure${NC}"
fi
echo ""

# 4. Fix file permissions
echo -e "${CYAN}[4/5] Fixing file permissions...${NC}"
# Ensure scripts are executable
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x ade-crypt 2>/dev/null || true

# Ensure sensitive directories have proper permissions
for dir in "${HOME}/.ade/keys" "${HOME}/.ade/secrets" "${HOME}/.ade/encrypted"; do
    if [ -d "${dir}" ]; then
        chmod 700 "${dir}"
        echo "Set permissions 700 on: ${dir}"
    fi
done
echo -e "${GREEN}✓ File permissions fixed${NC}"
FIXES_APPLIED=$((FIXES_APPLIED + 1))
echo ""

# 5. Add security headers to scripts
echo -e "${CYAN}[5/5] Adding security options to scripts...${NC}"
for file in src/**/*.sh src/*.sh; do
    if [ -f "${file}" ]; then
        # Check if security options are missing
        if ! grep -q "set -euo pipefail" "${file}" 2>/dev/null; then
            # Add after shebang
            sed -i.bak '1a\
# Security options\
set -euo pipefail\
IFS=$'"'"'\\n\\t'"'"'' "${file}"
            rm -f "${file}.bak"
            echo "Added security options to: $(basename "${file}")"
            FIXES_APPLIED=$((FIXES_APPLIED + 1))
        fi
    fi
done
echo ""

# Summary
echo -e "${CYAN}${BOLD}Security Fix Summary${NC}"
echo -e "${CYAN}===================${NC}"

if [ ${FIXES_APPLIED} -gt 0 ]; then
    echo -e "${GREEN}✓ Applied ${FIXES_APPLIED} security fixes${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run 'make security' to verify fixes"
    echo "2. Run 'make test' to ensure nothing broke"
    echo "3. Commit the changes"
else
    echo -e "${GREEN}✓ No security fixes needed - code is secure!${NC}"
fi

echo ""
echo -e "${CYAN}Run 'make security' to verify all fixes${NC}"