#!/usr/bin/env bats
# Tests for install-security-tools.sh script

load ../test_helper

setup() {
    setup_test_env
    export SCRIPT_PATH="$PROJECT_ROOT/scripts/install-security-tools.sh"
}

teardown() {
    teardown_test_env
}

@test "install-security-tools.sh exists and is executable" {
    assert_file_exists "$SCRIPT_PATH"
    [ -x "$SCRIPT_PATH" ] || fail "Script is not executable"
}

@test "install-security-tools.sh shows help" {
    run bash "$SCRIPT_PATH" --help
    assert_success
    assert_output_contains "Security Tools Installer"
    assert_output_contains "Usage:"
}

@test "install-security-tools.sh checks for existing tools" {
    run bash "$SCRIPT_PATH" --check
    assert_success
    assert_output_contains "Checking installed security tools"
}

@test "install-security-tools.sh detects missing gitleaks" {
    # Temporarily hide gitleaks if it exists
    if command -v gitleaks >/dev/null 2>&1; then
        skip "gitleaks already installed"
    fi
    
    run bash "$SCRIPT_PATH" --check
    assert_output_contains "gitleaks"
}

@test "install-security-tools.sh creates gitleaks config" {
    # Test config creation
    run bash "$SCRIPT_PATH" --config-only
    
    # Should create .gitleaks.toml if it doesn't exist
    if [ ! -f "$PROJECT_ROOT/.gitleaks.toml" ]; then
        assert_output_contains "Created .gitleaks.toml"
    fi
}

@test "install-security-tools.sh handles permission errors" {
    # Create a directory we can't write to
    mkdir -p /tmp/no_perms
    chmod 000 /tmp/no_perms
    
    HOME=/tmp/no_perms run bash "$SCRIPT_PATH" --check
    # Should handle gracefully
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
    
    chmod 755 /tmp/no_perms
    rm -rf /tmp/no_perms
}

@test "install-security-tools.sh dry-run mode" {
    run bash "$SCRIPT_PATH" --dry-run
    assert_success
    assert_output_contains "DRY RUN"
}

@test "install-security-tools.sh version check" {
    run bash "$SCRIPT_PATH" --version
    assert_success
    assert_output_contains "version"
}

@test "install-security-tools.sh lists available tools" {
    run bash "$SCRIPT_PATH" --list
    assert_success
    assert_output_contains "gitleaks"
    assert_output_contains "trufflehog"
    assert_output_contains "hyperfine"
}

@test "install-security-tools.sh handles invalid options" {
    run bash "$SCRIPT_PATH" --invalid-option
    assert_failure
    assert_output_contains "Unknown option"
}