#!/bin/bash

# Claude Code Installation Script
# This script installs Claude Code CLI from Anthropic

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[Claude Code Setup]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Node.js is installed
check_nodejs() {
    if ! command -v node &> /dev/null; then
        error "Node.js is not installed. Please install Node.js first."
        error "Run: bash scripts/install-nodejs.sh"
        exit 1
    fi
    log "✓ Node.js found: $(node --version)"
}

# Check if Claude Code is already installed
check_existing() {
    if command -v claude &> /dev/null; then
        CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
        warning "Claude Code is already installed: $CLAUDE_VERSION"
        read -p "Do you want to reinstall/update? [y/N]: " reinstall
        if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
            log "Skipping Claude Code installation"
            exit 0
        fi
    fi
}

# Install Claude Code
install_claude_code() {
    log "Installing Claude Code..."

    # Install Claude Code globally using npm
    npm install -g @anthropic-ai/claude-code

    log "✓ Claude Code installed successfully"
}

# Verify installation
verify_installation() {
    log "Verifying Claude Code installation..."

    if command -v claude &> /dev/null; then
        CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
        log "✓ Claude Code is available: $CLAUDE_VERSION"
    else
        error "Claude Code installation verification failed"
        error "Try running: source ~/.bashrc"
        exit 1
    fi
}

# Setup API key
setup_api_key() {
    log ""
    log "Claude Code requires an API key from Anthropic"
    log "You can get your API key from: https://console.anthropic.com/settings/keys"
    log ""
    read -p "Do you want to set up your API key now? [y/N]: " setup_key

    if [[ "$setup_key" =~ ^[Yy]$ ]]; then
        read -p "Enter your Anthropic API key: " api_key
        if [ -n "$api_key" ]; then
            # Add API key to bashrc if not already present
            if ! grep -q 'ANTHROPIC_API_KEY' "$HOME/.bashrc"; then
                echo '' >> "$HOME/.bashrc"
                echo '# Anthropic API Key' >> "$HOME/.bashrc"
                echo "export ANTHROPIC_API_KEY='$api_key'" >> "$HOME/.bashrc"
                log "✓ API key added to ~/.bashrc"
            else
                # Update existing API key
                sed -i "s/export ANTHROPIC_API_KEY=.*/export ANTHROPIC_API_KEY='$api_key'/" "$HOME/.bashrc"
                log "✓ API key updated in ~/.bashrc"
            fi
            export ANTHROPIC_API_KEY="$api_key"
        fi
    else
        log "You can set your API key later by adding to ~/.bashrc:"
        log "export ANTHROPIC_API_KEY='your-api-key-here'"
    fi
}

# Create config directory
setup_config() {
    log "Setting up Claude Code configuration directory..."

    CLAUDE_CONFIG_DIR="$HOME/.config/claude"
    mkdir -p "$CLAUDE_CONFIG_DIR"

    log "✓ Configuration directory created: $CLAUDE_CONFIG_DIR"
}

# Main execution
main() {
    log "=== Claude Code Installation ==="

    check_nodejs
    check_existing
    install_claude_code
    verify_installation
    setup_config
    setup_api_key

    log ""
    log "=== Claude Code Installation Complete ==="
    log "Configuration directory: $HOME/.config/claude"
    log ""
    log "Next steps:"
    log "1. Run 'source ~/.bashrc' to apply environment changes"
    log "2. Run 'claude --help' to see available commands"
    log "3. Configure MCP servers (see configs/mcp-config.json)"
}

main "$@"
