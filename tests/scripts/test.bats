#!/usr/bin/env bats
# Tests for test.sh script

load ../test_helper

setup() {
    setup_test_env
    export SCRIPT_PATH="$PROJECT_ROOT/scripts/test.sh"
}

teardown() {
    teardown_test_env
}

@test "test.sh exists and is executable" {
    assert_file_exists "$SCRIPT_PATH"
    [ -x "$SCRIPT_PATH" ] || fail "Script is not executable"
}

@test "test.sh runs basic tests" {
    run timeout 30 bash "$SCRIPT_PATH" --quick
    # Should complete successfully
    assert_success
    assert_output_contains "test" || assert_output_contains "Test"
}

@test "test.sh checks for bats" {
    if command -v bats >/dev/null 2>&1; then
        skip "bats is installed"
    fi
    
    run bash "$SCRIPT_PATH"
    assert_output_contains "bats not found" || assert_output_contains "Installing bats"
}

@test "test.sh runs specific test file" {
    # Create simple test
    cat > simple.bats <<'EOF'
#!/usr/bin/env bats
@test "simple test" {
    [ 1 -eq 1 ]
}
EOF
    
    run bash "$SCRIPT_PATH" simple.bats
    assert_success
    assert_output_contains "1 test" || assert_output_contains "✓"
}

@test "test.sh verbose mode" {
    run bash "$SCRIPT_PATH" --verbose
    assert_success
    # Should show detailed output
    assert_output_contains "Running" || assert_output_contains "verbose"
}

@test "test.sh tap output format" {
    run bash "$SCRIPT_PATH" --tap
    assert_success
    # Should use TAP format
    assert_output_contains "ok" || assert_output_contains "TAP"
}

@test "test.sh parallel execution" {
    run bash "$SCRIPT_PATH" --parallel
    # Should run tests in parallel
    assert_output_contains "parallel" || assert_output_contains "Parallel"
}

@test "test.sh filter tests by pattern" {
    run bash "$SCRIPT_PATH" --filter "basic"
    assert_success
    # Should only run matching tests
    assert_output_contains "basic" || assert_output_contains "filter"
}

@test "test.sh help message" {
    run bash "$SCRIPT_PATH" --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "test"
}

@test "test.sh counts test results" {
    run bash "$SCRIPT_PATH" --summary
    assert_success
    # Should show test counts
    assert_output_contains "passed" || assert_output_contains "failed" || assert_output_contains "total"
}

@test "test.sh handles test failures" {
    # Create failing test
    cat > failing.bats <<'EOF'
#!/usr/bin/env bats
@test "failing test" {
    [ 1 -eq 2 ]
}
EOF
    
    run bash "$SCRIPT_PATH" failing.bats
    assert_failure
    assert_output_contains "fail" || assert_output_contains "Fail"
}

@test "test.sh timeout handling" {
    # Create slow test
    cat > slow.bats <<'EOF'
#!/usr/bin/env bats
@test "slow test" {
    sleep 60
}
EOF
    
    run timeout 5 bash "$SCRIPT_PATH" slow.bats
    # Should timeout
    [ "$status" -ne 0 ]
}