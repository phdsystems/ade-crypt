#!/usr/bin/env bats
# Tests for check-deps.sh script

load ../test_helper

setup() {
    setup_test_env
    export SCRIPT_PATH="$PROJECT_ROOT/scripts/check-deps.sh"
}

teardown() {
    teardown_test_env
}

@test "check-deps.sh exists and is executable" {
    assert_file_exists "$SCRIPT_PATH"
    [ -x "$SCRIPT_PATH" ] || fail "Script is not executable"
}

@test "check-deps.sh checks for required dependencies" {
    run bash "$SCRIPT_PATH"
    assert_success
    assert_output_contains "Checking dependencies"
}

@test "check-deps.sh checks for bash version" {
    run bash "$SCRIPT_PATH"
    assert_output_contains "bash" || assert_output_contains "Bash"
}

@test "check-deps.sh checks for openssl" {
    run bash "$SCRIPT_PATH"
    assert_output_contains "openssl" || assert_output_contains "OpenSSL"
}

@test "check-deps.sh checks for gpg" {
    run bash "$SCRIPT_PATH"
    assert_output_contains "gpg" || assert_output_contains "GPG"
}

@test "check-deps.sh reports missing dependencies" {
    # Test with PATH manipulation to hide a command
    PATH=/usr/bin:/bin run bash "$SCRIPT_PATH"
    
    # Should still complete even with missing deps
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

@test "check-deps.sh verbose mode" {
    run bash "$SCRIPT_PATH" --verbose
    assert_success
    # Should show more details
    assert_output_contains "version" || assert_output_contains "Version"
}

@test "check-deps.sh quiet mode" {
    run bash "$SCRIPT_PATH" --quiet
    assert_success
    # Should have minimal output
    [ ${#output} -lt 200 ] || fail "Too much output in quiet mode"
}

@test "check-deps.sh install missing dependencies" {
    run bash "$SCRIPT_PATH" --install
    # Should attempt installation or show how to install
    assert_output_contains "install" || assert_output_contains "Install"
}

@test "check-deps.sh json output" {
    run bash "$SCRIPT_PATH" --format json
    # Should output JSON format
    assert_output_contains "{" || assert_output_contains "json"
}

@test "check-deps.sh checks optional dependencies" {
    run bash "$SCRIPT_PATH" --all
    assert_success
    # Should check optional deps too
    assert_output_contains "optional" || assert_output_contains "Optional" || assert_output_contains "bats"
}

@test "check-deps.sh help message" {
    run bash "$SCRIPT_PATH" --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "dependencies"
}

@test "check-deps.sh exit codes" {
    run bash "$SCRIPT_PATH"
    
    # Exit 0 if all deps found, 1 if missing
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

@test "check-deps.sh version check for dependencies" {
    run bash "$SCRIPT_PATH" --check-versions
    assert_success
    # Should show version numbers
    assert_output_contains "." || assert_output_contains "version"
}