#!/usr/bin/env bats
# Tests for architecture validation script

load test_helper

setup() {
    setup_test_env
    # Create test directory structure
    mkdir -p "$TEST_TMPDIR/test_src/modules"
    # Set PROJECT_ROOT for script access
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    export PROJECT_ROOT
}

teardown() {
    teardown_test_env
}

@test "validate-arch: detects approved encryption algorithms" {
    # Create test file with approved algorithm
    cat > "$TEST_TMPDIR/test_src/modules/test.sh" << 'EOF'
#!/bin/bash
echo "test data" | openssl enc -aes-256-cbc -salt -out file.enc
EOF
    
    # Run validation on test directory
    cd "$TEST_TMPDIR" && run "$PROJECT_ROOT/scripts/validate-architecture.sh"
    assert_success
    assert_output_contains "All encryption algorithms are approved"
}

@test "validate-arch: rejects weak encryption algorithms" {
    # Create test file with weak algorithm
    cat > "$TEST_TMPDIR/test_src/modules/test.sh" << 'EOF'
#!/bin/bash
echo "test data" | openssl enc -aes-128-cbc -salt -out file.enc
EOF
    
    # Run validation on test directory
    cd "$TEST_TMPDIR" && run "$PROJECT_ROOT/scripts/validate-architecture.sh"
    assert_failure
    assert_output_contains "Unapproved algorithm: aes-128-cbc"
}

@test "validate-arch: ignores openssl flags correctly" {
    # Create test file with flags that shouldn't be parsed as algorithms
    cat > "$TEST_TMPDIR/test_src/modules/test.sh" << 'EOF'
#!/bin/bash
echo -n "test data" | openssl enc -e -salt -aes-256-gcm -out file.enc
EOF
    
    # Run validation on test directory  
    cd "$TEST_TMPDIR" && run ../../scripts/validate-architecture.sh
    assert_success
    assert_output_contains "All encryption algorithms are approved"
}

@test "validate-arch: detects insecure key storage" {
    # Create test file with insecure key path
    cat > "$TEST_TMPDIR/test_src/modules/test.sh" << 'EOF'
#!/bin/bash
KEY_FILE="/tmp/myapp.key"
openssl enc -aes-256-cbc -in data.txt -out data.enc -pass file:"$KEY_FILE"
EOF
    
    # Run validation on test directory
    cd "$TEST_TMPDIR" && run "$PROJECT_ROOT/scripts/validate-architecture.sh"
    assert_failure
    assert_output_contains "Keys/secrets stored in insecure location"
}

@test "validate-arch: accepts secure key storage" {
    # Create test file with secure key path  
    cat > "$TEST_TMPDIR/test_src/modules/test.sh" << 'EOF'
#!/bin/bash
KEY_FILE="$HOME/.ade/keys/app.key"
openssl enc -aes-256-cbc -in data.txt -out data.enc -pass file:"$KEY_FILE"
EOF
    
    # Run validation on test directory
    cd "$TEST_TMPDIR" && run "$PROJECT_ROOT/scripts/validate-architecture.sh"
    assert_success
}

@test "validate-arch: detects missing error handling" {
    # Create test file without error handling
    cat > "$TEST_TMPDIR/test_src/modules/test.sh" << 'EOF'
#!/bin/bash
source ../lib/common.sh
do_something() {
    echo "no error handling"
}
EOF
    
    # Run validation on test directory
    cd "$TEST_TMPDIR" && run "$PROJECT_ROOT/scripts/validate-architecture.sh"
    # Should warn about missing error handling
    assert_output_contains "lacking error handling"
}

@test "validate-arch: validates module interface consistency" {
    # Create test file with inconsistent interface
    cat > "$TEST_TMPDIR/test_src/modules/test.sh" << 'EOF'
#!/bin/bash
source ../lib/common.sh
echo "No command dispatcher case statement"
EOF
    
    # Run validation on test directory
    cd "$TEST_TMPDIR" && run "$PROJECT_ROOT/scripts/validate-architecture.sh"
    assert_output_contains "no command dispatcher"
}

@test "validate-arch: detects security anti-patterns" {
    # Create test file with unsafe patterns
    cat > "$TEST_TMPDIR/test_src/modules/test.sh" << 'EOF'
#!/bin/bash
# Unsafe variable expansion
echo $*
eval "rm -rf $user_input"
EOF
    
    # Run validation on test directory
    cd "$TEST_TMPDIR" && run "$PROJECT_ROOT/scripts/validate-architecture.sh"
    assert_failure
    assert_output_contains "Unsafe"
}

@test "validate-arch: handles empty source directory" {
    # Remove source directory
    rm -rf "$TEST_TMPDIR/test_src"
    
    # Run validation on test directory
    cd "$TEST_TMPDIR" && run "$PROJECT_ROOT/scripts/validate-architecture.sh"
    # Should handle gracefully without crashing
    assert_success
}

@test "validate-arch: validates ADR compliance when ADRs exist" {
    # Create ADR directory structure
    mkdir -p "$TEST_TMPDIR/docs/adr"
    
    # Create test ADR with missing sections
    cat > "$TEST_TMPDIR/docs/adr/001-test.md" << 'EOF'
# ADR-001: Test Decision
## Status
Accepted
## Context  
Test context
# Missing Decision and Consequences sections
EOF
    
    # Run validation on test directory
    cd "$TEST_TMPDIR" && run "$PROJECT_ROOT/scripts/validate-architecture.sh"
    assert_output_contains "missing sections"
}

@test "validate-arch: exit code reflects validation status" {
    # Create test file with multiple violations
    mkdir -p "$TEST_TMPDIR/src/modules"
    cat > "$TEST_TMPDIR/src/modules/bad.sh" << 'EOF'
#!/bin/bash
# Multiple violations
echo "test" | openssl enc -des-cbc -out /tmp/file.key  
eval "$user_input"
EOF
    
    # Run validation - should fail
    cd "$TEST_TMPDIR" && run ../../scripts/validate-architecture.sh
    assert_failure
    
    # Create clean test file
    cat > "$TEST_TMPDIR/src/modules/good.sh" << 'EOF'
#!/bin/bash
source ../lib/common.sh
case "${1:-}" in
    help) echo "help" ;;
    *) error_exit "unknown" ;;
esac  
EOF
    
    # Run validation - should pass
    cd "$TEST_TMPDIR" && run ../../scripts/validate-architecture.sh
    assert_success
}