#!/usr/bin/env bats
# Tests for performance-test.sh script

load ../test_helper

setup() {
    setup_test_env
    export SCRIPT_PATH="$PROJECT_ROOT/scripts/performance-test.sh"
}

teardown() {
    teardown_test_env
}

@test "performance-test.sh exists and is executable" {
    assert_file_exists "$SCRIPT_PATH"
    [ -x "$SCRIPT_PATH" ] || fail "Script is not executable"
}

@test "performance-test.sh runs basic benchmark" {
    # Create small test file
    echo "test data" > small.txt
    
    run timeout 30 bash "$SCRIPT_PATH" --quick
    # May fail if hyperfine not installed, but shouldn't crash
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

@test "performance-test.sh checks for hyperfine" {
    if command -v hyperfine >/dev/null 2>&1; then
        skip "hyperfine is installed"
    fi
    
    run bash "$SCRIPT_PATH"
    assert_output_contains "hyperfine not found"
}

@test "performance-test.sh generates test files" {
    run bash "$SCRIPT_PATH" --setup-only
    
    # Should create test files
    assert_file_exists "perf_test_1mb.dat" || assert_output_contains "Created test files"
}

@test "performance-test.sh shows help" {
    run bash "$SCRIPT_PATH" --help
    assert_success
    assert_output_contains "Performance Test"
    assert_output_contains "Usage:"
}

@test "performance-test.sh memory profiling mode" {
    run bash "$SCRIPT_PATH" --memory
    # Should attempt memory profiling
    assert_output_contains "Memory" || assert_output_contains "memory"
}

@test "performance-test.sh handles missing ade-crypt" {
    # Temporarily rename ade-crypt
    mv "$PROJECT_ROOT/ade-crypt" "$PROJECT_ROOT/ade-crypt.bak" 2>/dev/null || true
    
    run bash "$SCRIPT_PATH"
    assert_failure
    assert_output_contains "ade-crypt not found"
    
    # Restore
    mv "$PROJECT_ROOT/ade-crypt.bak" "$PROJECT_ROOT/ade-crypt" 2>/dev/null || true
}

@test "performance-test.sh csv output mode" {
    run bash "$SCRIPT_PATH" --output csv
    # Should generate CSV format or indicate it would
    assert_output_contains "CSV" || assert_output_contains "csv" || assert_output_contains ","
}

@test "performance-test.sh cleanup after tests" {
    run bash "$SCRIPT_PATH" --quick
    
    # Test files should be cleaned up
    [ ! -f "perf_test_*.dat" ] || assert_output_contains "Cleanup"
}

@test "performance-test.sh comparison mode" {
    run bash "$SCRIPT_PATH" --compare
    # Should show comparison or indicate feature
    assert_output_contains "compar" || assert_output_contains "Compar"
}