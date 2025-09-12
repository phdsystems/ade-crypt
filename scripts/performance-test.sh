#!/bin/bash
# Performance testing script for ADE crypt
# Benchmarks key operations and identifies bottlenecks

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

# Test data setup
TEST_DIR="/tmp/ade-perf-test-$$"
mkdir -p "${TEST_DIR}"
trap "rm -rf ${TEST_DIR}" EXIT INT TERM

echo -e "${CYAN}${BOLD}ADE crypt Performance Testing${NC}"
echo -e "${CYAN}=============================${NC}"
echo ""

# Create test files of various sizes
echo -e "${CYAN}Creating test data...${NC}"
echo "Small test data" > "${TEST_DIR}/small.txt"
dd if=/dev/urandom of="${TEST_DIR}/medium.txt" bs=1M count=1 2>/dev/null
dd if=/dev/urandom of="${TEST_DIR}/large.txt" bs=1M count=10 2>/dev/null
dd if=/dev/urandom of="${TEST_DIR}/xlarge.txt" bs=1M count=100 2>/dev/null

# Setup test environment
export ADE_CRYPT_HOME="${TEST_DIR}/.ade-test"
mkdir -p "${ADE_CRYPT_HOME}/keys"

# Generate test key
./ade-crypt keys generate test-key >/dev/null 2>&1 || true

echo -e "${GREEN}✓ Test environment ready${NC}"
echo ""

# Function to run performance test
run_perf_test() {
    local name=$1
    local command=$2
    local iterations=${3:-10}
    
    echo -e "${CYAN}Testing: ${name}${NC}"
    
    if command -v hyperfine >/dev/null 2>&1; then
        hyperfine \
            --warmup 2 \
            --runs "${iterations}" \
            --export-json "${TEST_DIR}/${name}.json" \
            --export-markdown "${TEST_DIR}/${name}.md" \
            "${command}" 2>/dev/null || echo "Command: ${command}"
    else
        # Fallback to time command
        echo "  Using basic timing (hyperfine not installed)"
        local total_time=0
        for i in $(seq 1 "${iterations}"); do
            local start=$(date +%s%N)
            eval "${command}" >/dev/null 2>&1
            local end=$(date +%s%N)
            local elapsed=$((end - start))
            total_time=$((total_time + elapsed))
        done
        local avg_time=$((total_time / iterations / 1000000))
        echo "  Average time: ${avg_time}ms (${iterations} runs)"
    fi
    echo ""
}

echo -e "${CYAN}${BOLD}1. Encryption Performance${NC}"
echo -e "${CYAN}========================${NC}"

run_perf_test "encrypt-small" "./ade-crypt encrypt ${TEST_DIR}/small.txt ${TEST_DIR}/small.enc"
run_perf_test "encrypt-medium" "./ade-crypt encrypt ${TEST_DIR}/medium.txt ${TEST_DIR}/medium.enc"
run_perf_test "encrypt-large" "./ade-crypt encrypt ${TEST_DIR}/large.txt ${TEST_DIR}/large.enc"

echo -e "${CYAN}${BOLD}2. Decryption Performance${NC}"
echo -e "${CYAN}========================${NC}"

# Ensure files are encrypted first
./ade-crypt encrypt "${TEST_DIR}/small.txt" "${TEST_DIR}/small.enc" 2>/dev/null
./ade-crypt encrypt "${TEST_DIR}/medium.txt" "${TEST_DIR}/medium.enc" 2>/dev/null
./ade-crypt encrypt "${TEST_DIR}/large.txt" "${TEST_DIR}/large.enc" 2>/dev/null

run_perf_test "decrypt-small" "./ade-crypt decrypt ${TEST_DIR}/small.enc ${TEST_DIR}/small.dec"
run_perf_test "decrypt-medium" "./ade-crypt decrypt ${TEST_DIR}/medium.enc ${TEST_DIR}/medium.dec"
run_perf_test "decrypt-large" "./ade-crypt decrypt ${TEST_DIR}/large.enc ${TEST_DIR}/large.dec"

echo -e "${CYAN}${BOLD}3. Secret Operations Performance${NC}"
echo -e "${CYAN}===============================${NC}"

run_perf_test "secret-store" "echo 'test-secret' | ./ade-crypt secrets store perf-test"
run_perf_test "secret-retrieve" "./ade-crypt secrets get perf-test"
run_perf_test "secret-list" "./ade-crypt secrets list"

echo -e "${CYAN}${BOLD}4. Key Operations Performance${NC}"
echo -e "${CYAN}============================${NC}"

run_perf_test "key-generate" "./ade-crypt keys generate perf-key-test"
run_perf_test "key-list" "./ade-crypt keys list"

echo -e "${CYAN}${BOLD}5. Comparative Analysis${NC}"
echo -e "${CYAN}======================${NC}"

if command -v hyperfine >/dev/null 2>&1; then
    echo -e "${CYAN}Comparing encryption algorithms...${NC}"
    hyperfine \
        --warmup 1 \
        --runs 5 \
        'openssl enc -aes-256-cbc -salt -in '"${TEST_DIR}/medium.txt"' -out '"${TEST_DIR}/test1.enc"' -pass pass:test' \
        'openssl enc -aes-128-cbc -salt -in '"${TEST_DIR}/medium.txt"' -out '"${TEST_DIR}/test2.enc"' -pass pass:test' \
        'gzip -c '"${TEST_DIR}/medium.txt"' > '"${TEST_DIR}/test.gz"
else
    echo -e "${YELLOW}⚠ Install hyperfine for detailed comparative analysis${NC}"
fi

echo ""
echo -e "${CYAN}${BOLD}6. Bottleneck Analysis${NC}"
echo -e "${CYAN}=====================${NC}"

if command -v strace >/dev/null 2>&1; then
    echo -e "${CYAN}System call analysis for encryption...${NC}"
    strace -c ./ade-crypt encrypt "${TEST_DIR}/small.txt" "${TEST_DIR}/trace.enc" 2>&1 | head -20
else
    echo -e "${YELLOW}⚠ Install strace for system call analysis${NC}"
fi

echo ""
echo -e "${CYAN}${BOLD}7. Memory Usage Analysis${NC}"
echo -e "${CYAN}=======================${NC}"

if command -v /usr/bin/time >/dev/null 2>&1; then
    echo -e "${CYAN}Memory usage for large file encryption...${NC}"
    /usr/bin/time -v ./ade-crypt encrypt "${TEST_DIR}/large.txt" "${TEST_DIR}/mem-test.enc" 2>&1 | grep -E "Maximum resident|Elapsed"
else
    echo -e "${YELLOW}⚠ GNU time not available for memory analysis${NC}"
fi

echo ""
echo -e "${GREEN}${BOLD}Performance Test Summary${NC}"
echo -e "${GREEN}=======================${NC}"

# Generate summary report
if [ -f "${TEST_DIR}/encrypt-small.json" ] && command -v jq >/dev/null 2>&1; then
    echo -e "${CYAN}Operation Performance (milliseconds):${NC}"
    for test in encrypt-small encrypt-medium encrypt-large decrypt-small decrypt-medium decrypt-large; do
        if [ -f "${TEST_DIR}/${test}.json" ]; then
            mean=$(jq '.results[0].mean * 1000' "${TEST_DIR}/${test}.json")
            stddev=$(jq '.results[0].stddev * 1000' "${TEST_DIR}/${test}.json")
            printf "  %-20s: %8.2f ms (±%.2f)\n" "${test}" "${mean}" "${stddev}"
        fi
    done
fi

echo ""
echo -e "${CYAN}${BOLD}Recommendations:${NC}"
echo "1. Consider caching for frequently accessed secrets"
echo "2. Use compression only for large files (>1MB)"
echo "3. Implement parallel processing for batch operations"
echo "4. Add progress indicators for large file operations"
echo "5. Consider using hardware acceleration if available"

echo ""
echo -e "${GREEN}✓ Performance testing complete${NC}"