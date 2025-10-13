#!/bin/bash

# Gemini CLI Installation Script
# This script installs Google's Gemini CLI

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[Gemini Setup]${NC} $1"
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

# Check if Gemini CLI is already installed
check_existing() {
    if command -v gemini &> /dev/null || command -v google-genai &> /dev/null; then
        warning "Gemini CLI might already be installed"
        read -p "Do you want to reinstall/update? [y/N]: " reinstall
        if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
            log "Skipping Gemini CLI installation"
            exit 0
        fi
    fi
}

# Install Gemini CLI
install_gemini() {
    log "Installing Gemini CLI..."

    # Install Google Generative AI CLI
    npm install -g @google/generative-ai-cli

    log "✓ Gemini CLI installed successfully"
}

# Verify installation
verify_installation() {
    log "Verifying Gemini CLI installation..."

    if command -v google-genai &> /dev/null; then
        log "✓ Gemini CLI is available"
    else
        warning "Gemini CLI installation verification failed"
        warning "You may need to run: source ~/.bashrc"
    fi
}

# Setup API key
setup_api_key() {
    log ""
    log "Gemini CLI requires an API key from Google AI Studio"
    log "You can get your API key from: https://aistudio.google.com/app/apikey"
    log ""
    read -p "Do you want to set up your API key now? [y/N]: " setup_key

    if [[ "$setup_key" =~ ^[Yy]$ ]]; then
        read -p "Enter your Google AI API key: " api_key
        if [ -n "$api_key" ]; then
            # Add API key to bashrc if not already present
            if ! grep -q 'GOOGLE_API_KEY' "$HOME/.bashrc"; then
                echo '' >> "$HOME/.bashrc"
                echo '# Google AI API Key' >> "$HOME/.bashrc"
                echo "export GOOGLE_API_KEY='$api_key'" >> "$HOME/.bashrc"
                log "✓ API key added to ~/.bashrc"
            else
                # Update existing API key
                sed -i "s/export GOOGLE_API_KEY=.*/export GOOGLE_API_KEY='$api_key'/" "$HOME/.bashrc"
                log "✓ API key updated in ~/.bashrc"
            fi
            export GOOGLE_API_KEY="$api_key"
        fi
    else
        log "You can set your API key later by adding to ~/.bashrc:"
        log "export GOOGLE_API_KEY='your-api-key-here'"
    fi
}

# Main execution
main() {
    log "=== Gemini CLI Installation ==="

    check_nodejs
    check_existing
    install_gemini
    verify_installation
    setup_api_key

    log ""
    log "=== Gemini CLI Installation Complete ==="
    log ""
    log "Next steps:"
    log "1. Run 'source ~/.bashrc' to apply environment changes"
    log "2. Run 'google-genai --help' to see available commands"
}

main "$@"
