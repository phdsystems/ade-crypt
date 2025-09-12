#!/usr/bin/env bats
# Tests for decryption module

load ../test_helper

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "decrypt file with default key" {
    echo "test data" > input.txt
    run_ade_crypt encrypt file input.txt
    rm input.txt
    
    run run_ade_crypt decrypt file input.txt.enc
    assert_success
    assert_file_exists input.txt
    assert_file_contains input.txt "test data"
}

@test "decrypt with specific key" {
    run_ade_crypt keys generate test-key
    echo "test data" > input.txt
    run_ade_crypt encrypt file input.txt -k "$ADE_CRYPT_HOME/keys/test-key.key"
    rm input.txt
    
    run run_ade_crypt decrypt file input.txt.enc -k "$ADE_CRYPT_HOME/keys/test-key.key"
    assert_success
    assert_file_exists input.txt
}

@test "decrypt with output file" {
    echo "test data" > input.txt
    run_ade_crypt encrypt file input.txt
    
    run run_ade_crypt decrypt file input.txt.enc -o decrypted.txt
    assert_success
    assert_file_exists decrypted.txt
    assert_file_contains decrypted.txt "test data"
}

@test "decrypt directory" {
    mkdir test_dir
    echo "file1" > test_dir/file1.txt
    echo "file2" > test_dir/file2.txt
    run_ade_crypt encrypt directory test_dir
    rm -rf test_dir
    
    run run_ade_crypt decrypt directory test_dir.tar.enc
    assert_success
    assert_file_exists test_dir/file1.txt
    assert_file_exists test_dir/file2.txt
}

@test "decrypt handles corrupted file" {
    echo "test data" > input.txt
    run_ade_crypt encrypt file input.txt
    
    # Corrupt the encrypted file
    echo "corrupted" > input.txt.enc
    
    run run_ade_crypt decrypt file input.txt.enc
    assert_failure
    assert_output_contains "decrypt" || assert_output_contains "failed"
}

@test "decrypt handles wrong key" {
    run_ade_crypt keys generate key1
    run_ade_crypt keys generate key2
    
    echo "test data" > input.txt
    run_ade_crypt encrypt file input.txt -k "$ADE_CRYPT_HOME/keys/key1.key"
    
    run run_ade_crypt decrypt file input.txt.enc -k "$ADE_CRYPT_HOME/keys/key2.key"
    assert_failure
}
