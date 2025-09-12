#!/usr/bin/env bats
# Tests for secrets module

load ../test_helper

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "store and retrieve secret" {
    echo "my-secret-value" | run run_ade_crypt secrets store test-secret
    assert_success
    
    run run_ade_crypt secrets get test-secret
    assert_success
    assert_output_contains "my-secret-value"
}

@test "list secrets" {
    create_test_secret "secret1" "value1"
    create_test_secret "secret2" "value2"
    
    run run_ade_crypt secrets list
    assert_success
    assert_output_contains "secret1"
    assert_output_contains "secret2"
}

@test "delete secret" {
    create_test_secret "to-delete" "value"
    
    run run_ade_crypt secrets delete to-delete
    assert_success
    
    run run_ade_crypt secrets get to-delete
    assert_failure
}

@test "update existing secret" {
    create_test_secret "test-secret" "old-value"
    
    echo "new-value" | run run_ade_crypt secrets store test-secret
    assert_success
    
    run run_ade_crypt secrets get test-secret
    assert_success
    assert_output_contains "new-value"
    ! assert_output_contains "old-value"
}

@test "secret with metadata" {
    echo "value" | run run_ade_crypt secrets store test-secret --category prod --tags "api,key"
    assert_success
    
    run run_ade_crypt secrets list --verbose
    assert_success
    assert_output_contains "test-secret"
}

@test "search secrets" {
    create_test_secret "api-key" "key1"
    create_test_secret "db-password" "pass1"
    
    run run_ade_crypt secrets search "api"
    assert_success
    assert_output_contains "api-key"
    ! assert_output_contains "db-password"
}

@test "export secrets" {
    create_test_secret "TEST_VAR" "test_value"
    
    run run_ade_crypt secrets export env
    assert_success
    assert_output_contains "export TEST_VAR="
}

@test "import secrets" {
    echo "NEW_SECRET=imported_value" > secrets.env
    
    run run_ade_crypt secrets import secrets.env
    assert_success
    
    run run_ade_crypt secrets get NEW_SECRET
    assert_success
    assert_output_contains "imported_value"
}

@test "rotate secrets" {
    create_test_secret "test-secret" "old-value"
    
    run run_ade_crypt secrets rotate
    assert_success
    
    # Secret should still be accessible
    run run_ade_crypt secrets get test-secret
    assert_success
}

@test "secret versioning" {
    create_test_secret "versioned" "v1"
    echo "v2" | run run_ade_crypt secrets store versioned
    
    run run_ade_crypt secrets version versioned 1
    assert_success
    assert_output_contains "v1"
}
