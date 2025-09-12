#!/usr/bin/env bats
# Tests for encryption module

load ../test_helper

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "encrypt file with default key" {
    echo "test data" > input.txt
    
    run run_ade_crypt encrypt file input.txt
    assert_success
    assert_file_exists input.txt.enc
    
    # Encrypted file should be different from original
    ! cmp -s input.txt input.txt.enc
}

@test "encrypt with specific key" {
    # Generate test key
    run_ade_crypt keys generate test-key
    
    echo "test data" > input.txt
    run run_ade_crypt encrypt file input.txt -k "$ADE_CRYPT_HOME/keys/test-key.key"
    assert_success
    assert_file_exists input.txt.enc
}

@test "encrypt with compression" {
    # Create larger file for compression
    for i in {1..100}; do
        echo "Line $i: This is test data that should compress well" >> large.txt
    done
    
    run run_ade_crypt encrypt file large.txt -c gzip
    assert_success
    assert_file_exists large.txt.enc
}

@test "encrypt with output file" {
    echo "test data" > input.txt
    
    run run_ade_crypt encrypt file input.txt -o custom.encrypted
    assert_success
    assert_file_exists custom.encrypted
    ! assert_file_exists input.txt.enc
}

@test "encrypt directory" {
    mkdir test_dir
    echo "file1" > test_dir/file1.txt
    echo "file2" > test_dir/file2.txt
    
    run run_ade_crypt encrypt directory test_dir
    assert_success
    assert_file_exists test_dir.tar.enc
}

@test "encrypt handles missing file" {
    run run_ade_crypt encrypt file nonexistent.txt
    assert_failure
    assert_output_contains "not found" || assert_output_contains "does not exist"
}
