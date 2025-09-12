#!/usr/bin/env bats
# Tests for security-audit.sh script

load ../test_helper

setup() {
    setup_test_env
    export SCRIPT_PATH="$PROJECT_ROOT/scripts/security-audit.sh"
}

teardown() {
    teardown_test_env
}

@test "security-audit.sh exists and is executable" {
    assert_file_exists "$SCRIPT_PATH"
    [ -x "$SCRIPT_PATH" ] || fail "Script is not executable"
}

@test "security-audit.sh runs without errors" {
    run timeout 30 bash "$SCRIPT_PATH"
    # May have warnings but should not crash
    [[ "$status" -eq 0 || "$status" -eq 1 ]] || fail "Script crashed with status $status"
}

@test "security-audit.sh detects missing trap handlers" {
    # Create a script without trap handler
    cat > test_script.sh <<'EOF'
#!/bin/bash
temp_file=$(mktemp)
echo "data" > $temp_file
rm -f $temp_file
EOF
    
    run bash "$SCRIPT_PATH"
    assert_output_contains "Missing trap handlers"
}

@test "security-audit.sh detects predictable temp files" {
    # Create script with predictable temp file
    cat > bad_temp.sh <<'EOF'
#!/bin/bash
temp_file="/tmp/myapp_$$"
echo "data" > $temp_file
EOF
    
    run bash "$SCRIPT_PATH"
    assert_output_contains "Predictable temp files"
}

@test "security-audit.sh detects insecure rm operations" {
    # Create script with insecure deletion
    cat > insecure_rm.sh <<'EOF'
#!/bin/bash
rm -f sensitive.key
rm -rf secrets/
EOF
    
    run bash "$SCRIPT_PATH"
    assert_output_contains "Insecure file deletion"
}

@test "security-audit.sh detects potential hardcoded secrets" {
    # Create script with hardcoded secret
    cat > hardcoded.sh <<'EOF'
#!/bin/bash
API_KEY="sk_live_abcd1234"
PASSWORD="mysecretpass123"
EOF
    
    run bash "$SCRIPT_PATH"
    assert_output_contains "hardcoded secrets"
}

@test "security-audit.sh checks file permissions" {
    # Create file with insecure permissions
    mkdir -p test_keys
    touch test_keys/private.key
    chmod 777 test_keys/private.key
    
    run bash "$SCRIPT_PATH"
    assert_output_contains "File permission issues"
}

@test "security-audit.sh generates summary report" {
    run bash "$SCRIPT_PATH"
    assert_output_contains "Security Audit Summary"
    assert_output_contains "Total Issues Found:"
}

@test "security-audit.sh handles empty directories gracefully" {
    # Run in empty directory
    rm -rf *
    run bash "$SCRIPT_PATH"
    assert_success
}

@test "security-audit.sh respects quiet mode" {
    run bash "$SCRIPT_PATH" --quiet
    # Should have minimal output
    [ ${#output} -lt 500 ] || fail "Too much output in quiet mode"
}