#!/bin/bash

# Node.js Installation Script using NVM
# This script installs NVM (Node Version Manager) and the latest LTS version of Node.js

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    source "$SCRIPT_DIR/common.sh"
else
    echo "ERROR: common.sh not found in $SCRIPT_DIR"
    exit 1
fi

# Override log function to add Node.js Setup prefix
log() {
    echo -e "${GREEN}[Node.js Setup]${NC} $1"
}

# Check if Node.js is already installed
check_existing() {
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        warning "Node.js is already installed: $NODE_VERSION"
        read -p "Do you want to reinstall/update? [y/N]: " reinstall
        if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
            log "Skipping Node.js installation"
            exit 0
        fi
    fi
}

# Install NVM
install_nvm() {
    log "Installing NVM (Node Version Manager)..."

    if [ -d "$HOME/.nvm" ]; then
        warning "NVM is already installed"
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        # Download and install NVM
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

        # Load NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

        log "✓ NVM installed successfully"
    fi
}

# Install Node.js LTS
install_nodejs() {
    log "Installing Node.js LTS version..."

    # Install latest LTS version
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'

    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)

    log "✓ Node.js installed: $NODE_VERSION"
    log "✓ npm installed: $NPM_VERSION"
}

# Configure npm global directory
configure_npm() {
    log "Configuring npm global directory..."

    # Create a directory for global packages
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global"

    # Add to PATH in bashrc if not already present
    if ! grep -q '.npm-global/bin' "$HOME/.bashrc"; then
        echo '' >> "$HOME/.bashrc"
        echo '# npm global packages' >> "$HOME/.bashrc"
        echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
        log "✓ Added npm global path to ~/.bashrc"
    fi

    # Also add NVM initialization if not present
    if ! grep -q 'NVM_DIR' "$HOME/.bashrc"; then
        echo '' >> "$HOME/.bashrc"
        echo '# NVM initialization' >> "$HOME/.bashrc"
        echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.bashrc"
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$HOME/.bashrc"
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "$HOME/.bashrc"
        log "✓ Added NVM initialization to ~/.bashrc"
    fi
}

# Install common global packages
install_common_packages() {
    log "Installing common npm packages..."

    # Update npm itself
    npm install -g npm@latest

    log "✓ npm updated to latest version"
}

# Main execution
main() {
    log "=== Node.js Installation ==="

    check_existing
    install_nvm
    install_nodejs
    configure_npm
    install_common_packages

    log ""
    log "=== Node.js Installation Complete ==="
    log "Node.js version: $(node --version)"
    log "npm version: $(npm --version)"
    log "Global packages location: $HOME/.npm-global"
    log ""
    log "Please run 'source ~/.bashrc' or restart your terminal"
}

main "$@"
