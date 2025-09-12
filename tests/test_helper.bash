#!/usr/bin/env bash
# Test helper functions for ADE-Crypt BATS tests

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Set up test environment
export TEST_TMPDIR="${BATS_TMPDIR:-/tmp}/ade-crypt-tests"
export ADE_CRYPT_HOME="$TEST_TMPDIR/.ade-test"
export ADE_CRYPT="$PROJECT_ROOT/ade-crypt"

# Colors for test output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# Set up clean test environment
setup_test_env() {
    rm -rf "$TEST_TMPDIR"
    mkdir -p "$TEST_TMPDIR"
    cd "$TEST_TMPDIR"
    
    # Create test files
    echo "This is a test file" > test.txt
    echo "Secret test data" > secret.txt
    echo -e "line1\nline2\nline3" > multiline.txt
}

# Clean up test environment
teardown_test_env() {
    cd /
    rm -rf "$TEST_TMPDIR"
}

# Run ade-crypt command with timeout
run_ade_crypt() {
    timeout 30 "$ADE_CRYPT" "$@"
}

# Check if command exists
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# Skip test if dependency missing
require_command() {
    local cmd="$1"
    local package="${2:-$1}"
    
    if ! has_command "$cmd"; then
        skip "$cmd not installed (try: apt-get install $package)"
    fi
}

# Create test secret
create_test_secret() {
    local name="${1:-test-secret}"
    local value="${2:-test-value-123}"
    
    echo "$value" | run_ade_crypt secrets store "$name"
}

# Generate test key
create_test_key() {
    local name="${1:-test-key}"
    run_ade_crypt keys generate "$name"
}

# Assert file exists
assert_file_exists() {
    [ -f "$1" ] || {
        echo "Expected file to exist: $1"
        return 1
    }
}

# Assert file contains text
assert_file_contains() {
    local file="$1"
    local text="$2"
    
    grep -q "$text" "$file" || {
        echo "Expected file '$file' to contain '$text'"
        echo "File contents:"
        cat "$file"
        return 1
    }
}

# Assert command output contains text
assert_output_contains() {
    local text="$1"
    echo "$output" | grep -q "$text" || {
        echo "Expected output to contain '$text'"
        echo "Actual output:"
        echo "$output"
        return 1
    }
}

# Assert command succeeded
assert_success() {
    [ "$status" -eq 0 ] || {
        echo "Expected command to succeed (exit 0), got $status"
        echo "Output: $output"
        return 1
    }
}

# Assert command failed
assert_failure() {
    [ "$status" -ne 0 ] || {
        echo "Expected command to fail (exit non-zero), got $status"
        echo "Output: $output"
        return 1
    }
}