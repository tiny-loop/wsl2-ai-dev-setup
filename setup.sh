#!/bin/bash

# WSL2 Development Environment Setup Script
# This script automates the setup of Node.js, Claude Code, Gemini CLI, Chrome, and MCP
# Supports: Ubuntu/Debian and Rocky Linux/RHEL

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/setup.log"

# Source common functions
if [ -f "$SCRIPT_DIR/scripts/common.sh" ]; then
    source "$SCRIPT_DIR/scripts/common.sh"
else
    echo "ERROR: common.sh not found in $SCRIPT_DIR/scripts/"
    exit 1
fi

# Override log function to include timestamp
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running in WSL2
check_wsl2() {
    log "Checking if running in WSL2..."
    if ! grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
        error "This script must be run in WSL2"
        exit 1
    fi
    log "✓ Running in WSL2"
}

# Update system packages
update_system() {
    log "Updating system packages..."

    # Detect OS if not already done
    if [ -z "$PKG_MANAGER" ]; then
        detect_os || {
            error "Failed to detect OS"
            exit 1
        }
    fi

    case "$PKG_MANAGER" in
        apt)
            sudo apt-get update
            sudo apt-get upgrade -y
            ;;
        dnf)
            sudo dnf upgrade -y
            ;;
        yum)
            sudo yum update -y
            ;;
        *)
            error "Unknown package manager: $PKG_MANAGER"
            exit 1
            ;;
    esac

    log "✓ System packages updated"
}

# Main setup flow
main() {
    log "=== WSL2 Development Environment Setup ==="
    log "Supports: Ubuntu/Debian and Rocky Linux/RHEL"
    log "Log file: $LOG_FILE"

    check_wsl2

    # Detect OS
    detect_os || {
        error "Failed to detect operating system"
        exit 1
    }

    show_os_info

    # Ask user what to install
    echo ""
    echo "What would you like to install?"
    echo "1) Full setup (all components)"
    echo "2) Node.js only"
    echo "3) Claude Code only"
    echo "4) Gemini CLI only"
    echo "5) Chrome + MCP setup"
    echo "6) SSH Key setup"
    echo "7) Custom selection"
    echo "8) Check installed versions"
    read -p "Enter your choice [1-8]: " choice

    case $choice in
        1)
            update_system
            bash "$SCRIPT_DIR/scripts/install-nodejs.sh"
            bash "$SCRIPT_DIR/scripts/install-claude-code.sh"
            bash "$SCRIPT_DIR/scripts/install-gemini.sh"
            bash "$SCRIPT_DIR/scripts/install-chrome.sh"
            bash "$SCRIPT_DIR/scripts/setup-ssh-key.sh"
            ;;
        2)
            bash "$SCRIPT_DIR/scripts/install-nodejs.sh"
            ;;
        3)
            bash "$SCRIPT_DIR/scripts/install-claude-code.sh"
            ;;
        4)
            bash "$SCRIPT_DIR/scripts/install-gemini.sh"
            ;;
        5)
            bash "$SCRIPT_DIR/scripts/install-chrome.sh"
            ;;
        6)
            bash "$SCRIPT_DIR/scripts/setup-ssh-key.sh"
            ;;
        7)
            echo ""
            read -p "Install Node.js? [y/N]: " install_node
            read -p "Install Claude Code? [y/N]: " install_claude
            read -p "Install Gemini CLI? [y/N]: " install_gemini
            read -p "Install Chrome? [y/N]: " install_chrome
            read -p "Setup SSH Key? [y/N]: " setup_ssh

            [[ "$install_node" =~ ^[Yy]$ ]] && bash "$SCRIPT_DIR/scripts/install-nodejs.sh"
            [[ "$install_claude" =~ ^[Yy]$ ]] && bash "$SCRIPT_DIR/scripts/install-claude-code.sh"
            [[ "$install_gemini" =~ ^[Yy]$ ]] && bash "$SCRIPT_DIR/scripts/install-gemini.sh"
            [[ "$install_chrome" =~ ^[Yy]$ ]] && bash "$SCRIPT_DIR/scripts/install-chrome.sh"
            [[ "$setup_ssh" =~ ^[Yy]$ ]] && bash "$SCRIPT_DIR/scripts/setup-ssh-key.sh"
            ;;
        8)
            bash "$SCRIPT_DIR/scripts/check-versions.sh"
            ;;
        *)
            error "Invalid choice"
            exit 1
            ;;
    esac

    log ""
    log "=== Setup Complete ==="
    log "Please run 'source ~/.bashrc' or restart your terminal to apply changes"
    log ""
    log "Next steps:"
    log "1. Configure MCP: Edit Claude Code config with settings from configs/mcp-config.json"
    log "2. Start Chrome for debugging: bash scripts/start-chrome-debug.sh"
    log "3. Check the README.md for more information"
}

# Run main function
main "$@"
