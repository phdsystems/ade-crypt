#!/usr/bin/env bats
# Basic functionality tests for ADE crypt

load test_helper

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "ade-crypt shows version" {
    run run_ade_crypt version
    assert_success
    assert_output_contains "ADE crypt"
    assert_output_contains "v2.1.0"
}

@test "ade-crypt shows help" {
    run run_ade_crypt help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "Modules:"
}

@test "ade-crypt handles unknown command" {
    run run_ade_crypt unknown-command
    assert_failure
    assert_output_contains "Unknown command"
}

@test "encrypt and decrypt basic file" {
    # Create test file
    echo "test data" > input.txt
    
    # Encrypt
    run run_ade_crypt encrypt file input.txt
    assert_success
    assert_file_exists input.txt.enc
    
    # Remove original
    rm input.txt
    
    # Decrypt
    run run_ade_crypt decrypt file input.txt.enc
    assert_success
    assert_file_exists input.txt
    assert_file_contains input.txt "test data"
}

@test "secrets store and retrieve" {
    # Store secret
    run bash -c 'echo "secret-value" | '"$ADE_CRYPT"' secrets store test-key'
    assert_success
    
    # Retrieve secret
    run run_ade_crypt secrets get test-key
    assert_success
    assert_output_contains "secret-value"
    
    # List secrets
    run run_ade_crypt secrets list
    assert_success
    assert_output_contains "test-key"
}

@test "key generation" {
    # Generate key
    run run_ade_crypt keys generate test-key
    assert_success
    assert_output_contains "Key generated"
    
    # List keys
    run run_ade_crypt keys list
    assert_success
    assert_output_contains "test-key"
}