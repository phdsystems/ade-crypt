#!/usr/bin/env bats
# Encryption module tests

load ../test_helper

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "encrypt file with compression" {
    echo "test data for compression" > large.txt
    
    # Encrypt with gzip
    run run_ade_crypt encrypt file -c gzip large.txt
    assert_success
    assert_file_exists large.txt.enc
}

@test "encrypt with password" {
    require_command gpg
    
    echo "password data" > pwd.txt
    
    # This would require interactive input in real scenario
    # For testing, we'll skip actual GPG encryption
    skip "Interactive password encryption test"
}

@test "stream encryption" {
    # Test stream encryption
    run bash -c 'echo "stream data" | '"$ADE_CRYPT"' encrypt stream > stream.enc'
    assert_success
    assert_file_exists stream.enc
    
    # Test stream decryption
    run bash -c 'cat stream.enc | '"$ADE_CRYPT"' decrypt stream > stream.out'
    assert_success
    assert_file_contains stream.out "stream data"
}

@test "directory encryption" {
    # Create test directory
    mkdir testdir
    echo "file1" > testdir/file1.txt
    echo "file2" > testdir/file2.txt
    
    # Encrypt directory
    run run_ade_crypt encrypt directory testdir
    assert_success
    assert_file_exists testdir.tar.enc
}

@test "file splitting" {
    # Create large file (simulate)
    dd if=/dev/zero of=largefile.txt bs=1M count=1 2>/dev/null
    
    # Encrypt first
    run run_ade_crypt encrypt file largefile.txt
    assert_success
    
    # Split encrypted file
    run run_ade_crypt split largefile.txt.enc 500K
    assert_success
    
    # Check parts exist
    assert_file_exists largefile.txt.enc.part.aa
}