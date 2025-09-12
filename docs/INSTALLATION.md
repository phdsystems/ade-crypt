# Installation Guide

## Quick Install

### Standard Installation
```bash
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/install.sh | bash
```

### Library Installation
```bash
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/lib/install.sh | bash
```

## Installation Methods

### 1. Automated Installation (Recommended)

#### System-wide Installation
```bash
# Download and run installer
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/install.sh | bash

# Or with wget
wget -O- https://raw.githubusercontent.com/phdsystems/ade-crypt/main/install.sh | bash
```

#### User Installation
```bash
# Install to user directory
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/install.sh | bash -s -- --user
```

### 2. Manual Installation

#### From Source
```bash
# Clone repository
git clone https://github.com/phdsystems/ade-crypt.git
cd ade-crypt

# Make executable
chmod +x ade-crypt

# Option 1: Install system-wide
sudo cp ade-crypt /usr/local/bin/
sudo cp -r src /usr/local/lib/ade-crypt/

# Option 2: Install for current user
mkdir -p ~/.local/bin
cp ade-crypt ~/.local/bin/
cp -r src ~/.local/lib/ade-crypt/

# Add to PATH if needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### Direct Download
```bash
# Download main script
wget https://raw.githubusercontent.com/phdsystems/ade-crypt/main/ade-crypt
chmod +x ade-crypt

# Download source files
mkdir -p ade-crypt-src
cd ade-crypt-src
wget -r -np -nH --cut-dirs=1 https://raw.githubusercontent.com/phdsystems/ade-crypt/main/src/
```

### 3. Package Managers

#### Homebrew (macOS/Linux)
```bash
# Coming soon
brew tap phdsystems/ade-crypt
brew install ade-crypt
```

#### APT (Debian/Ubuntu)
```bash
# Coming soon
sudo add-apt-repository ppa:phdsystems/ade-crypt
sudo apt update
sudo apt install ade-crypt
```

### 4. Docker Installation

#### Run with Docker
```bash
# Pull and run
docker run -it --rm \
  -v ~/.ade:/root/.ade \
  -v $(pwd):/workspace \
  phdsystems/ade-crypt:latest
```

#### Build Docker Image
```bash
# Clone and build
git clone https://github.com/phdsystems/ade-crypt.git
cd ade-crypt
docker build -t ade-crypt .
```

### 5. Development Installation

#### Full Development Setup
```bash
# Clone repository
git clone https://github.com/phdsystems/ade-crypt.git
cd ade-crypt

# Install development dependencies
./scripts/install-dev-deps.sh

# Set up development environment
make setup

# Verify installation
make test
```

## Dependencies

### Required Dependencies
These must be installed for basic functionality:

| Dependency | Version | Purpose | Installation |
|------------|---------|---------|--------------|
| Bash | 4.0+ | Shell interpreter | Pre-installed on most systems |
| OpenSSL | 1.1.1+ | Encryption operations | `apt install openssl` |
| tar | Any | Archive operations | Pre-installed |
| gzip | Any | Compression | Pre-installed |
| sha256sum | Any | Checksums | Part of coreutils |

### Optional Dependencies
These enable additional features:

| Dependency | Purpose | Installation |
|------------|---------|--------------|
| GPG | Password-based encryption | `apt install gnupg` |
| bzip2 | Additional compression | `apt install bzip2` |
| xz | Additional compression | `apt install xz-utils` |
| AWS CLI | S3 cloud sync | `pip install awscli` |
| gsutil | Google Cloud sync | Install from Google |
| Azure CLI | Azure sync | Install from Microsoft |

### Development Dependencies
Required for development and testing:

| Dependency | Purpose | Installation |
|------------|---------|--------------|
| ShellCheck | Code linting | `apt install shellcheck` |
| BATS | Testing framework | `apt install bats` |
| Git | Version control | `apt install git` |
| Make | Build automation | `apt install make` |

## Installation Verification

### Check Installation
```bash
# Verify installation
ade-crypt --version

# Check dependencies
ade-crypt check-deps

# Run help
ade-crypt --help
```

### Test Installation
```bash
# Create test file
echo "test data" > test.txt

# Test encryption
ade-crypt encrypt file test.txt

# Test decryption
ade-crypt decrypt file test.txt.enc

# Clean up
rm test.txt test.txt.enc
```

## Platform-Specific Instructions

### Ubuntu/Debian
```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y openssl tar gzip gnupg bzip2 xz-utils

# Install ADE crypt
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/install.sh | bash
```

### RHEL/CentOS/Fedora
```bash
# Install dependencies
sudo yum install -y openssl tar gzip gnupg2 bzip2 xz

# Install ADE crypt
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/install.sh | bash
```

### macOS
```bash
# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install openssl gnu-tar gzip gnupg bzip2 xz

# Install ADE crypt
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/install.sh | bash
```

### Windows (WSL)
```bash
# Install WSL2 first
wsl --install

# In WSL terminal, follow Ubuntu instructions
sudo apt-get update
sudo apt-get install -y openssl tar gzip gnupg

# Install ADE crypt
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/install.sh | bash
```

### Arch Linux
```bash
# Install dependencies
sudo pacman -S openssl tar gzip gnupg bzip2 xz

# Install ADE crypt
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/install.sh | bash
```

## Configuration

### Environment Variables
```bash
# Set custom home directory
export ADE_CRYPT_HOME="$HOME/.ade"

# Set custom installation directory
export ADE_INSTALL_DIR="/opt/ade-crypt"

# Add to shell configuration
echo 'export ADE_CRYPT_HOME="$HOME/.ade"' >> ~/.bashrc
```

### Initial Setup
```bash
# Generate default key
ade-crypt keys generate

# Configure settings
ade-crypt config

# Set up cloud sync (optional)
ade-crypt backup config
```

## Troubleshooting

### Common Issues

#### Permission Denied
```bash
# Fix permissions
chmod +x /usr/local/bin/ade-crypt
chmod -R 755 /usr/local/lib/ade-crypt
```

#### Command Not Found
```bash
# Add to PATH
export PATH="/usr/local/bin:$PATH"
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### Missing Dependencies
```bash
# Check what's missing
./scripts/check-deps.sh

# Install missing dependencies
sudo apt-get install openssl gnupg
```

#### OpenSSL Issues
```bash
# Update OpenSSL
sudo apt-get update
sudo apt-get upgrade openssl

# On macOS
brew upgrade openssl
```

## Uninstallation

### Automated Uninstall
```bash
# Run uninstaller
ade-crypt uninstall

# Or manually
sudo rm -f /usr/local/bin/ade-crypt
sudo rm -rf /usr/local/lib/ade-crypt
```

### Clean User Data
```bash
# Backup first!
tar czf ade-backup.tar.gz ~/.ade

# Remove user data
rm -rf ~/.ade
```

## Upgrading

### Upgrade to Latest Version
```bash
# Backup current installation
ade-crypt backup create

# Reinstall latest version
curl -sSL https://raw.githubusercontent.com/phdsystems/ade-crypt/main/install.sh | bash

# Verify upgrade
ade-crypt --version
```

### Migrate Data
```bash
# Export data before upgrade
ade-crypt export json > ade-data.json

# After upgrade, import
ade-crypt import json < ade-data.json
```

## Support

If you encounter installation issues:

1. Check [GitHub Issues](https://github.com/phdsystems/ade-crypt/issues)
2. Run diagnostics: `ade-crypt check-deps`
3. Review system logs: `journalctl -xe`
4. Create an issue with details

## Next Steps

After installation:

1. Read the [User Guide](USER_GUIDE.md)
2. Generate your first key: `ade-crypt keys generate`
3. Try the examples: `ade-crypt help`
4. Explore advanced features