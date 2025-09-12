#!/usr/bin/env bats
# Tests for lint.sh script

load ../test_helper

setup() {
    setup_test_env
    export SCRIPT_PATH="$PROJECT_ROOT/scripts/lint.sh"
}

teardown() {
    teardown_test_env
}

@test "lint.sh exists and is executable" {
    assert_file_exists "$SCRIPT_PATH"
    [ -x "$SCRIPT_PATH" ] || fail "Script is not executable"
}

@test "lint.sh runs ShellCheck on valid script" {
    # Create valid script
    cat > valid.sh <<'EOF'
#!/bin/bash
echo "Hello World"
exit 0
EOF
    
    run bash "$SCRIPT_PATH" valid.sh
    assert_success
    assert_output_contains "No issues found" || assert_output_contains "✓"
}

@test "lint.sh detects ShellCheck errors" {
    # Create script with issues
    cat > bad.sh <<'EOF'
#!/bin/bash
VAR = "value"  # Space around =
echo $VAR      # Unquoted variable
rm -rf $1      # Unquoted parameter
EOF
    
    run bash "$SCRIPT_PATH" bad.sh
    assert_failure
    assert_output_contains "SC" || assert_output_contains "error"
}

@test "lint.sh checks for ShellCheck installation" {
    # Test with PATH manipulation to hide shellcheck
    PATH=/usr/bin:/bin run bash "$SCRIPT_PATH" --version
    
    if ! command -v shellcheck >/dev/null 2>&1; then
        assert_output_contains "not found" || assert_output_contains "Installing"
    else
        assert_output_contains "ShellCheck"
    fi
}

@test "lint.sh auto-installs ShellCheck if missing" {
    if command -v shellcheck >/dev/null 2>&1; then
        skip "ShellCheck already installed"
    fi
    
    run bash "$SCRIPT_PATH" --install
    assert_output_contains "Installing ShellCheck"
}

@test "lint.sh lints all project scripts" {
    run timeout 30 bash "$SCRIPT_PATH"
    # Should run on all scripts
    assert_output_contains "Linting" || assert_output_contains "Checking"
}

@test "lint.sh recursive mode" {
    mkdir -p subdir
    cat > subdir/script.sh <<'EOF'
#!/bin/bash
echo "test"
EOF
    
    run bash "$SCRIPT_PATH" --recursive .
    assert_success
    assert_output_contains "subdir/script.sh" || assert_output_contains "1 file"
}

@test "lint.sh excludes patterns" {
    cat > test.sh <<'EOF'
#!/bin/bash
echo "test"
EOF
    
    cat > exclude.sh <<'EOF'
#!/bin/bash
VAR = "bad"
EOF
    
    run bash "$SCRIPT_PATH" --exclude "exclude.sh" *.sh
    assert_success
    ! assert_output_contains "exclude.sh"
}

@test "lint.sh format options" {
    cat > test.sh <<'EOF'
#!/bin/bash
echo $1
EOF
    
    run bash "$SCRIPT_PATH" --format json test.sh
    assert_output_contains "{" || assert_output_contains "json"
}

@test "lint.sh severity levels" {
    cat > warning.sh <<'EOF'
#!/bin/bash
VAR="value"
echo $VAR  # Warning level issue
EOF
    
    run bash "$SCRIPT_PATH" --severity error warning.sh
    assert_success  # Only warnings, not errors
}

@test "lint.sh fix mode" {
    cat > fixable.sh <<'EOF'
#!/bin/bash
VAR="value"
echo $VAR
EOF
    
    run bash "$SCRIPT_PATH" --fix fixable.sh
    # Should attempt to fix or indicate it would
    assert_output_contains "fix" || assert_output_contains "Fix"
}

@test "lint.sh help message" {
    run bash "$SCRIPT_PATH" --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "ShellCheck"
}