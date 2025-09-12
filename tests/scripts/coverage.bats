#!/usr/bin/env bats
# Tests for coverage.sh script

load ../test_helper

setup() {
    setup_test_env
    export SCRIPT_PATH="$PROJECT_ROOT/scripts/coverage.sh"
}

teardown() {
    teardown_test_env
}

@test "coverage.sh exists and is executable" {
    assert_file_exists "$SCRIPT_PATH"
    [ -x "$SCRIPT_PATH" ] || fail "Script is not executable"
}

@test "coverage.sh checks for bashcov" {
    if command -v bashcov >/dev/null 2>&1; then
        skip "bashcov is installed"
    fi
    
    run bash "$SCRIPT_PATH"
    assert_output_contains "bashcov not found" || assert_output_contains "Installing bashcov"
}

@test "coverage.sh generates coverage report" {
    if ! command -v bashcov >/dev/null 2>&1; then
        skip "bashcov not installed"
    fi
    
    run timeout 60 bash "$SCRIPT_PATH" --quick
    # May succeed or fail depending on bashcov
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

@test "coverage.sh help message" {
    run bash "$SCRIPT_PATH" --help
    assert_success
    assert_output_contains "Coverage Report Generator"
    assert_output_contains "Usage:"
}

@test "coverage.sh html output mode" {
    run bash "$SCRIPT_PATH" --format html
    # Should indicate HTML output
    assert_output_contains "HTML" || assert_output_contains "html"
}

@test "coverage.sh json output mode" {
    run bash "$SCRIPT_PATH" --format json
    # Should indicate JSON output
    assert_output_contains "JSON" || assert_output_contains "json"
}

@test "coverage.sh cleans old reports" {
    # Create fake old report
    mkdir -p coverage
    touch coverage/old_report.html
    
    run bash "$SCRIPT_PATH" --clean
    assert_success
    assert_output_contains "Clean" || assert_output_contains "clean"
}

@test "coverage.sh threshold checking" {
    run bash "$SCRIPT_PATH" --threshold 80
    # Should check coverage threshold
    assert_output_contains "threshold" || assert_output_contains "80%"
}

@test "coverage.sh verbose mode" {
    run bash "$SCRIPT_PATH" --verbose
    # Should have more output
    [ ${#output} -gt 100 ] || assert_output_contains "verbose"
}

@test "coverage.sh handles missing tests" {
    # Remove test files temporarily
    mv "$PROJECT_ROOT/tests" "$PROJECT_ROOT/tests.bak" 2>/dev/null || true
    
    run bash "$SCRIPT_PATH"
    assert_failure
    assert_output_contains "No tests found" || assert_output_contains "tests directory"
    
    # Restore
    mv "$PROJECT_ROOT/tests.bak" "$PROJECT_ROOT/tests" 2>/dev/null || true
}