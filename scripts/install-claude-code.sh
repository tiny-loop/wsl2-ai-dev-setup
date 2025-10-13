#!/bin/bash

# Claude Code Installation Script
# This script installs Claude Code CLI from Anthropic

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
    echo -e "${GREEN}[Claude Code Setup]${NC} $1"
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

# Apply WSL2 workaround config using claude mcp add + jq
apply_wsl2_workaround_config() {
    log "Configuring chrome-devtools-mcp for WSL2..."
    local CLAUDE_CONFIG_DIR="$HOME/.config/claude"
    local CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/config.json"

    # Step 1: Use claude mcp add command to create base configuration
    log "Adding chrome-devtools MCP server..."
    if claude mcp add chrome-devtools npx chrome-devtools-mcp@latest 2>/dev/null; then
        log "✓ MCP server added via 'claude mcp add'"
    else
        warning "'claude mcp add' failed, falling back to manual config creation"
        mkdir -p "$CLAUDE_CONFIG_DIR"
        if [ ! -f "$CLAUDE_CONFIG_FILE" ] || [ ! -s "$CLAUDE_CONFIG_FILE" ]; then
            echo '{"mcpServers":{}}' > "$CLAUDE_CONFIG_FILE"
        fi
        jq '.mcpServers."chrome-devtools" = {"command": "npx", "args": ["chrome-devtools-mcp@latest"]}' \
            "$CLAUDE_CONFIG_FILE" > "${CLAUDE_CONFIG_FILE}.tmp" && mv "${CLAUDE_CONFIG_FILE}.tmp" "$CLAUDE_CONFIG_FILE"
    fi

    # Step 2: Verify config file exists
    if [ ! -f "$CLAUDE_CONFIG_FILE" ]; then
        error "Config file not created at $CLAUDE_CONFIG_FILE"
        return 1
    fi

    # Step 3: Add --browserUrl argument using jq (avoid duplicates)
    log "Adding WSL2 workaround argument..."
    local BROWSER_URL="--browserUrl=http://localhost:9222"

    jq ".mcpServers.\"chrome-devtools\".args |= if contains([\"$BROWSER_URL\"]) then . else . + [\"$BROWSER_URL\"] end" \
        "$CLAUDE_CONFIG_FILE" > "${CLAUDE_CONFIG_FILE}.tmp" && mv "${CLAUDE_CONFIG_FILE}.tmp" "$CLAUDE_CONFIG_FILE"

    log "✓ Chrome-devtools MCP configured with WSL2 workaround"
    log "  Config file: $CLAUDE_CONFIG_FILE"
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
            if ! grep -q 'ANTHROPIC_API_KEY' "$HOME/.bashrc"; then
                echo '' >> "$HOME/.bashrc"
                echo '# Anthropic API Key' >> "$HOME/.bashrc"
                echo "export ANTHROPIC_API_KEY='$api_key'" >> "$HOME/.bashrc"
                log "✓ API key added to ~/.bashrc"
            else
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

# Main execution
main() {
    log "=== Claude Code Installation ==="

    detect_os # Needed for package manager functions from common.sh
    check_nodejs
    check_and_install_jq
    check_existing
    install_claude_code
    verify_installation
    apply_wsl2_workaround_config
    setup_api_key

    log ""
    log "=== Claude Code Installation Complete ==="
    log "Configuration directory: $HOME/.config/claude"
    log ""
    log "Next steps:"
    log "1. Run 'source ~/.bashrc' to apply environment changes"
    log "2. Run 'claude --help' to see available commands"
    log "3. The MCP server configuration for WSL2 has been automatically applied."
}

main "$@"