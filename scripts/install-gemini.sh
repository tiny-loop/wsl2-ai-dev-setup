#!/bin/bash

# Gemini CLI Installation Script
# This script installs Google's Gemini CLI

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
# common.sh is needed for OS detection and package installation (for jq)
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    source "$SCRIPT_DIR/common.sh"
else
    echo "ERROR: common.sh not found. This script requires it for installing dependencies." >&2
    exit 1
fi

# Override log function for context
log() {
    echo -e "${GREEN}[Gemini Setup]${NC} $1"
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

# Check for and install jq if not present, using functions from common.sh
check_and_install_jq() {
    log "Checking for jq..."
    if ! is_package_installed "jq"; then
        warning "jq not found. Attempting to install..."
        install_package "jq"
        log "✓ jq installed."
    else
        log "✓ jq is already installed."
    fi
}

# Check if Gemini CLI is already installed
check_existing() {
    if command -v gemini &> /dev/null; then
        GEMINI_VERSION=$(gemini --version 2>/dev/null || echo "unknown")
        warning "Gemini CLI is already installed: $GEMINI_VERSION"
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

    # Install official Google Gemini CLI
    npm install -g @google/gemini-cli

    log "✓ Gemini CLI installed successfully"
}

# Verify installation
verify_installation() {
    log "Verifying Gemini CLI installation..."

    if command -v gemini &> /dev/null; then
        GEMINI_VERSION=$(gemini --version 2>/dev/null || echo "unknown")
        log "✓ Gemini CLI is available: $GEMINI_VERSION"
    else
        error "Gemini CLI installation verification failed"
        error "Try running: source ~/.bashrc"
        exit 1
    fi
}

# Apply WSL2 workaround config using gemini mcp add + jq
apply_wsl2_workaround_config() {
    log "Configuring chrome-devtools-mcp for WSL2..."
    local GEMINI_CONFIG_DIR="$HOME/.gemini"
    local GEMINI_CONFIG_FILE="$GEMINI_CONFIG_DIR/settings.json"

    # Step 1: Use gemini mcp add command to create base configuration
    log "Adding chrome-devtools MCP server..."
    if gemini mcp add chrome-devtools npx chrome-devtools-mcp@latest 2>/dev/null; then
        log "✓ MCP server added via 'gemini mcp add'"
    else
        warning "'gemini mcp add' failed, falling back to manual config creation"
        mkdir -p "$GEMINI_CONFIG_DIR"
        if [ ! -f "$GEMINI_CONFIG_FILE" ] || [ ! -s "$GEMINI_CONFIG_FILE" ]; then
            echo '{"mcpServers":{}}' > "$GEMINI_CONFIG_FILE"
        fi
        jq '.mcpServers."chrome-devtools" = {"command": "npx", "args": ["chrome-devtools-mcp@latest"]}' \
            "$GEMINI_CONFIG_FILE" > "${GEMINI_CONFIG_FILE}.tmp" && mv "${GEMINI_CONFIG_FILE}.tmp" "$GEMINI_CONFIG_FILE"
    fi

    # Step 2: Verify config file exists
    if [ ! -f "$GEMINI_CONFIG_FILE" ]; then
        error "Config file not created at $GEMINI_CONFIG_FILE"
        return 1
    fi

    # Step 3: Add --browserUrl argument using jq (avoid duplicates)
    log "Adding WSL2 workaround argument..."
    local BROWSER_URL="--browserUrl=http://localhost:9222"

    jq ".mcpServers.\"chrome-devtools\".args |= if contains([\"$BROWSER_URL\"]) then . else . + [\"$BROWSER_URL\"] end" \
        "$GEMINI_CONFIG_FILE" > "${GEMINI_CONFIG_FILE}.tmp" && mv "${GEMINI_CONFIG_FILE}.tmp" "$GEMINI_CONFIG_FILE"

    log "✓ Chrome-devtools MCP configured with WSL2 workaround"
    log "  Config file: $GEMINI_CONFIG_FILE"
}

# Setup authentication
setup_authentication() {
    log ""
    log "Gemini CLI uses Google Account authentication (OAuth)"
    log ""
    log "To authenticate:"
    log "1. Run 'gemini' command in your terminal"
    log "2. Follow the login prompts to sign in with your Google account"
    log "3. Free tier includes:"
    log "   - Gemini 2.5 Pro with 1M token context window"
    log "   - 60 requests/minute, 1,000 requests/day"
    log ""
}

# Main execution
main() {
    log "=== Gemini CLI Installation ==="

    detect_os # Needed for package manager functions from common.sh
    check_nodejs
    check_and_install_jq
    check_existing
    install_gemini
    verify_installation
    apply_wsl2_workaround_config
    setup_authentication

    log ""
    log "=== Gemini CLI Installation Complete ==="
    log "Configuration directory: $HOME/.gemini"
    log ""
    log "Next steps:"
    log "1. Run 'source ~/.bashrc' to apply environment changes"
    log "2. Run 'gemini' to authenticate and start using Gemini CLI"
    log "3. The MCP server configuration for WSL2 has been automatically applied."
}

main "$@"
