#!/usr/bin/env bats
# Tests for fix-security.sh script

load ../test_helper

setup() {
    setup_test_env
    export SCRIPT_PATH="$PROJECT_ROOT/scripts/fix-security.sh"
}

teardown() {
    teardown_test_env
}

@test "fix-security.sh exists and is executable" {
    assert_file_exists "$SCRIPT_PATH"
    [ -x "$SCRIPT_PATH" ] || fail "Script is not executable"
}

@test "fix-security.sh fixes predictable temp files" {
    # Create script with bad temp file
    cat > bad_temp.sh <<'EOF'
#!/bin/bash
temp_file="/tmp/myapp_$$"
echo "data" > $temp_file
EOF
    
    run bash "$SCRIPT_PATH" bad_temp.sh
    assert_success
    
    # Check if fixed
    assert_file_contains bad_temp.sh "mktemp"
    ! grep -q '/tmp/myapp_$$' bad_temp.sh
}

@test "fix-security.sh adds trap handlers" {
    # Create script without trap
    cat > no_trap.sh <<'EOF'
#!/bin/bash
temp_file=$(mktemp)
echo "data" > $temp_file
rm -f $temp_file
EOF
    
    run bash "$SCRIPT_PATH" no_trap.sh
    assert_success
    
    # Check if trap added
    assert_file_contains no_trap.sh "trap"
}

@test "fix-security.sh fixes insecure rm operations" {
    # Create script with insecure rm
    cat > insecure_rm.sh <<'EOF'
#!/bin/bash
rm -f sensitive.key
rm -rf secrets/
EOF
    
    run bash "$SCRIPT_PATH" insecure_rm.sh
    assert_success
    
    # Check if fixed to use shred
    assert_file_contains insecure_rm.sh "shred" || assert_file_contains insecure_rm.sh "secure_delete"
}

@test "fix-security.sh dry-run mode" {
    cat > test.sh <<'EOF'
#!/bin/bash
temp="/tmp/test_$$"
EOF
    
    run bash "$SCRIPT_PATH" --dry-run test.sh
    assert_success
    assert_output_contains "DRY RUN" || assert_output_contains "Would fix"
    
    # File should not be changed
    assert_file_contains test.sh '/tmp/test_$$'
}

@test "fix-security.sh backs up files" {
    cat > original.sh <<'EOF'
#!/bin/bash
temp="/tmp/bad_$$"
EOF
    
    run bash "$SCRIPT_PATH" --backup original.sh
    assert_success
    
    # Backup should exist
    assert_file_exists original.sh.bak || assert_output_contains "Backup created"
}

@test "fix-security.sh handles multiple files" {
    cat > file1.sh <<'EOF'
#!/bin/bash
temp="/tmp/file1_$$"
EOF
    
    cat > file2.sh <<'EOF'
#!/bin/bash
temp="/tmp/file2_$$"
EOF
    
    run bash "$SCRIPT_PATH" file1.sh file2.sh
    assert_success
    
    # Both files should be fixed
    assert_file_contains file1.sh "mktemp"
    assert_file_contains file2.sh "mktemp"
}

@test "fix-security.sh shows statistics" {
    cat > fix_me.sh <<'EOF'
#!/bin/bash
temp="/tmp/bad_$$"
rm -f secret.key
EOF
    
    run bash "$SCRIPT_PATH" --verbose fix_me.sh
    assert_success
    assert_output_contains "Fixed" || assert_output_contains "fixed"
    assert_output_contains "2" || assert_output_contains "issues"
}

@test "fix-security.sh handles non-existent files" {
    run bash "$SCRIPT_PATH" nonexistent.sh
    assert_failure
    assert_output_contains "not found" || assert_output_contains "does not exist"
}

@test "fix-security.sh preserves file permissions" {
    cat > perm_test.sh <<'EOF'
#!/bin/bash
temp="/tmp/test_$$"
EOF
    chmod 755 perm_test.sh
    
    run bash "$SCRIPT_PATH" perm_test.sh
    assert_success
    
    # Permissions should be preserved
    [ -x perm_test.sh ] || fail "Executable permission lost"
}

@test "fix-security.sh help message" {
    run bash "$SCRIPT_PATH" --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "fix-security"
}