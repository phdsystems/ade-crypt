#!/usr/bin/env bats
# Secrets module tests

load ../test_helper

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "store and retrieve secret" {
    run bash -c 'echo "my-secret-value" | '"$ADE_CRYPT"' secrets store test-secret'
    assert_success
    
    run run_ade_crypt secrets get test-secret
    assert_success
    assert_output_contains "my-secret-value"
}

@test "list secrets" {
    # Store multiple secrets
    create_test_secret "secret1" "value1"
    create_test_secret "secret2" "value2"
    
    run run_ade_crypt secrets list
    assert_success
    assert_output_contains "secret1"
    assert_output_contains "secret2"
}

@test "search secrets" {
    create_test_secret "api-key" "sk-123"
    create_test_secret "db-password" "secret123"
    create_test_secret "api-token" "token-456"
    
    # Search for 'api'
    run run_ade_crypt secrets search api
    assert_success
    assert_output_contains "api-key"
    assert_output_contains "api-token"
    
    # Should not contain db-password
    run bash -c 'echo "$output" | grep -v db-password'
    assert_success
}

@test "delete secret" {
    create_test_secret "temp-secret" "temp-value"
    
    # Verify it exists
    run run_ade_crypt secrets get temp-secret
    assert_success
    
    # Delete it (simulate user confirmation)
    run bash -c 'echo "y" | '"$ADE_CRYPT"' secrets delete temp-secret'
    assert_success
    
    # Verify it's gone
    run run_ade_crypt secrets get temp-secret
    assert_failure
}

@test "secret expiration" {
    create_test_secret "expiring-secret" "temp-value"
    
    # Set expiration to 1 day
    run run_ade_crypt secrets expire expiring-secret 1
    assert_success
    assert_output_contains "expires in 1 days"
}

@test "secret tagging" {
    create_test_secret "tagged-secret" "tagged-value"
    
    # Add tags
    run run_ade_crypt secrets tag tagged-secret "production,critical"
    assert_success
    assert_output_contains "Tags added"
}

@test "secret categories" {
    create_test_secret "categorized-secret" "cat-value"
    
    # Set category
    run run_ade_crypt secrets category categorized-secret "development"
    assert_success
    assert_output_contains "Category set"
}