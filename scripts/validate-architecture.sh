#!/bin/bash
# Architectural validation script for ADE crypt
# Validates design decisions against ADRs

set -euo pipefail

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

echo -e "${CYAN}${BOLD}ADE crypt Architecture Validation${NC}"
echo -e "${CYAN}==================================${NC}"
echo ""

VALIDATION_FAILED=0

# Validation: Approved encryption algorithms only
validate_encryption_algorithms() {
    echo -e "${CYAN}[1/5] Validating encryption algorithms...${NC}"
    
    # Approved algorithms per security standards
    local approved_algos="aes-256-cbc aes-256-gcm aes-256-ofb aes-256-cfb chacha20-poly1305"
    local found_violations=0
    
    # Check for algorithm usage
    while IFS= read -r line; do
        # Extract algorithm from openssl enc commands
        if echo "$line" | grep -q "openssl enc"; then
            # Look for cipher algorithm after openssl enc, skip flags like -n, -e, -d
            local algo=$(echo "$line" | grep -oP 'openssl enc\s+(-[a-zA-Z]\s+)*-\K[a-z0-9\-]+')
            
            if [[ -n "$algo" && ! " $approved_algos " =~ " $algo " ]]; then
                echo -e "  ${RED}✗ Unapproved algorithm: $algo${NC}"
                echo "    Location: $line"
                ((found_violations++))
            fi
        fi
    done < <(grep -r "openssl enc" src/ 2>/dev/null || true)
    
    if [[ $found_violations -eq 0 ]]; then
        echo -e "  ${GREEN}✓ All encryption algorithms are approved${NC}"
    else
        echo -e "  ${YELLOW}See docs/adr/001-encryption-algorithms.md for approved list${NC}"
        VALIDATION_FAILED=1
    fi
    echo ""
}

# Validation: Key storage security
validate_key_storage() {
    echo -e "${CYAN}[2/5] Validating key storage locations...${NC}"
    
    # Forbidden locations for key storage
    local forbidden_paths="/tmp /var/tmp /dev/shm /usr/tmp"
    local found_violations=0
    
    for path in $forbidden_paths; do
        if grep -r "${path}.*\.key\|${path}.*secret\|${path}.*password" src/ 2>/dev/null | grep -v "mktemp"; then
            echo -e "  ${RED}✗ Keys/secrets stored in insecure location: $path${NC}"
            ((found_violations++))
        fi
    done
    
    # Check for hardcoded key paths
    if grep -r '"/home/\|"/root/\|"~/\|/Users/' src/ 2>/dev/null | grep -E "\.key|secret|password" | grep -v '$HOME'; then
        echo -e "  ${YELLOW}⚠ Hardcoded user-specific paths detected${NC}"
        ((found_violations++))
    fi
    
    if [[ $found_violations -eq 0 ]]; then
        echo -e "  ${GREEN}✓ Key storage follows security best practices${NC}"
    else
        VALIDATION_FAILED=1
    fi
    echo ""
}

# Validation: Error handling patterns
validate_error_handling() {
    echo -e "${CYAN}[3/5] Validating error handling patterns...${NC}"
    
    local modules_without_error_handling=()
    
    for module in src/modules/*.sh; do
        if [[ -f "$module" ]]; then
            # Check for error handling functions
            if ! grep -q "error_exit\|die\|fatal\|cleanup" "$module"; then
                modules_without_error_handling+=("$(basename "$module")")
            fi
            
            # Check for set -e or error handling
            if ! grep -q "set -e\|set -o errexit" "$module"; then
                if ! grep -q "|| return\||| exit\||| error" "$module"; then
                    echo -e "  ${YELLOW}⚠ No automatic error handling in: $(basename "$module")${NC}"
                fi
            fi
        fi
    done
    
    if [[ ${#modules_without_error_handling[@]} -eq 0 ]]; then
        echo -e "  ${GREEN}✓ All modules have proper error handling${NC}"
    else
        echo -e "  ${YELLOW}⚠ Modules lacking error handling: ${modules_without_error_handling[*]}${NC}"
    fi
    echo ""
}

# Validation: Module interface consistency
validate_module_interfaces() {
    echo -e "${CYAN}[4/5] Validating module interface consistency...${NC}"
    
    local inconsistent_modules=()
    local expected_functions=("help" "version")
    
    for module in src/modules/*.sh; do
        if [[ -f "$module" ]]; then
            local module_name=$(basename "$module" .sh)
            local missing_functions=()
            
            # Check for standard command structure
            if ! grep -q 'case.*in' "$module"; then
                inconsistent_modules+=("$module_name: no command dispatcher")
                continue
            fi
            
            # Check for help command
            if ! grep -q "help)" "$module"; then
                missing_functions+=("help")
            fi
            
            if [[ ${#missing_functions[@]} -gt 0 ]]; then
                inconsistent_modules+=("$module_name: missing ${missing_functions[*]}")
            fi
        fi
    done
    
    if [[ ${#inconsistent_modules[@]} -eq 0 ]]; then
        echo -e "  ${GREEN}✓ All modules have consistent interfaces${NC}"
    else
        echo -e "  ${YELLOW}⚠ Interface inconsistencies found:${NC}"
        for issue in "${inconsistent_modules[@]}"; do
            echo "    - $issue"
        done
    fi
    echo ""
}

# Validation: Security patterns
validate_security_patterns() {
    echo -e "${CYAN}[5/5] Validating security patterns...${NC}"
    
    local security_issues=0
    
    # Check for unsafe variable expansion
    if grep -r '\$\*' src/ 2>/dev/null | grep -v '"\$\*"'; then
        echo -e "  ${RED}✗ Unsafe \$* usage found (use \"\$@\" instead)${NC}"
        ((security_issues++))
    fi
    
    # Check for eval usage
    if grep -r '^[^#]*eval' src/ 2>/dev/null; then
        echo -e "  ${RED}✗ Dangerous eval usage detected${NC}"
        ((security_issues++))
    fi
    
    # Check for proper quoting in comparisons
    if grep -r '\[ \$' src/ 2>/dev/null | grep -v '"\$'; then
        echo -e "  ${YELLOW}⚠ Unquoted variable in test condition${NC}"
        ((security_issues++))
    fi
    
    # Check for command substitution in unsafe contexts
    if grep -r 'echo.*`\|echo.*$(' src/ 2>/dev/null | grep -v '#'; then
        echo -e "  ${YELLOW}⚠ Command substitution in echo (potential injection)${NC}"
        ((security_issues++))
    fi
    
    if [[ $security_issues -eq 0 ]]; then
        echo -e "  ${GREEN}✓ Security patterns are properly implemented${NC}"
    else
        VALIDATION_FAILED=1
    fi
    echo ""
}

# Check for ADR compliance
check_adr_compliance() {
    echo -e "${CYAN}Checking ADR Compliance...${NC}"
    
    if [[ -d "docs/adr" ]]; then
        local adr_count=$(find docs/adr -name "*.md" -type f | wc -l)
        echo -e "  Found $adr_count ADR documents"
        
        # Validate each ADR has required sections
        for adr in docs/adr/*.md; do
            if [[ -f "$adr" && "$adr" != *"template.md" ]]; then
                local missing_sections=()
                
                for section in "Status" "Context" "Decision" "Consequences"; do
                    if ! grep -q "## $section" "$adr"; then
                        missing_sections+=("$section")
                    fi
                done
                
                if [[ ${#missing_sections[@]} -gt 0 ]]; then
                    echo -e "  ${YELLOW}⚠ $(basename "$adr") missing sections: ${missing_sections[*]}${NC}"
                fi
            fi
        done
    else
        echo -e "  ${YELLOW}⚠ No ADR directory found. Create docs/adr/ for architectural decisions${NC}"
    fi
    echo ""
}

# Generate validation report
generate_report() {
    echo -e "${CYAN}${BOLD}Architecture Validation Summary${NC}"
    echo -e "${CYAN}==============================${NC}"
    
    if [[ $VALIDATION_FAILED -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓ All architectural validations passed!${NC}"
        echo ""
        echo "Your code adheres to the defined architectural patterns and security requirements."
    else
        echo -e "${RED}${BOLD}✗ Architectural violations detected${NC}"
        echo ""
        echo "Please address the issues above to maintain architectural integrity."
        echo ""
        echo "For more information, see:"
        echo "  - docs/ARCHITECTURE.md"
        echo "  - docs/adr/ (Architectural Decision Records)"
        echo "  - docs/SECURITY.md"
    fi
}

# Main execution
main() {
    validate_encryption_algorithms
    validate_key_storage
    validate_error_handling
    validate_module_interfaces
    validate_security_patterns
    check_adr_compliance
    generate_report
    
    exit $VALIDATION_FAILED
}

main "$@"