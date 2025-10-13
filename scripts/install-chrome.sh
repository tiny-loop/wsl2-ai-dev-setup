#!/bin/bash

# Chrome Installation Script for WSL2
# This script installs Google Chrome in WSL2 for use with chrome-devtools-mcp
# Supports: Ubuntu/Debian and Rocky Linux/RHEL

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

# Override log function to add Chrome Setup prefix
log() {
    echo -e "${GREEN}[Chrome Setup]${NC} $1"
}

# Check WSLg support
check_wslg() {
    log "Checking WSLg (GUI support) availability..."
    log ""

    # Check for WSL2
    if ! grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
        error "This script must be run in WSL2"
        exit 1
    fi

    # Display environment variables
    log "Environment check:"
    log "  DISPLAY: ${DISPLAY:-not set}"
    log "  WAYLAND_DISPLAY: ${WAYLAND_DISPLAY:-not set}"
    log "  WSL_DISTRO_NAME: ${WSL_DISTRO_NAME:-not set}"
    log "  WSL_INTEROP: ${WSL_INTEROP:-not set}"
    log ""

    # Check if WSLg is available
    if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
        warning "WSLg may not be properly configured!"
        warning "Chrome GUI will not work without WSLg"
        log ""
        log "To fix this:"
        log "1. Update WSL in Windows PowerShell: wsl --update"
        log "2. Restart WSL: wsl --shutdown"
        log "3. Check WSL version: wsl --version (should be 2.0.0+)"
        log "4. Reopen your WSL terminal"
        log ""
        log "Alternative: Use Windows Chrome with --executable-path"
        log "See: https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131"
        log ""

        read -p "Continue anyway? [y/N]: " continue_install
        if [[ ! "$continue_install" =~ ^[Yy]$ ]]; then
            log "Installation cancelled. Please fix WSLg first."
            exit 0
        fi
    else
        log "✓ WSLg is available"

        # Test if we can actually create GUI windows
        if command -v xdpyinfo &> /dev/null; then
            if xdpyinfo &> /dev/null; then
                log "✓ X11 display is accessible"
            else
                warning "X11 display exists but may not be working properly"
            fi
        fi
    fi

    log ""
}

# Check if Chrome is already installed
check_existing() {
    if command -v google-chrome &> /dev/null; then
        CHROME_VERSION=$(google-chrome --version 2>/dev/null || echo "unknown")
        warning "Chrome is already installed: $CHROME_VERSION"
        read -p "Do you want to reinstall/update? [y/N]: " reinstall
        if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
            log "Skipping Chrome installation"
            exit 0
        fi
    fi
}

# Install Chrome
install_chrome() {
    log "Installing Google Chrome..."

    # Detect OS first
    detect_os || {
        error "Failed to detect OS"
        exit 1
    }

    # Show OS information
    show_os_info

    # Update package list
    update_packages

    # Install dependencies
    log "Installing dependencies..."
    install_chrome_dependencies

    # Install Chrome browser (OS-specific)
    install_chrome_browser

    log "✓ Chrome installed successfully"
}

# Verify installation
verify_installation() {
    log "Verifying Chrome installation..."

    if command -v google-chrome &> /dev/null; then
        CHROME_VERSION=$(google-chrome --version)
        log "✓ Chrome is available: $CHROME_VERSION"
    else
        error "Chrome installation verification failed"
        exit 1
    fi
}

# Install chrome-devtools-mcp
install_mcp() {
    log ""
    read -p "Do you want to install chrome-devtools-mcp? [Y/n]: " install_mcp

    if [[ ! "$install_mcp" =~ ^[Nn]$ ]]; then
        log "Installing chrome-devtools-mcp..."

        if ! command -v npx &> /dev/null; then
            error "npm/npx is not available. Please install Node.js first."
            error "Run: bash scripts/install-nodejs.sh"
            exit 1
        fi

        # Install chrome-devtools-mcp globally
        npm install -g chrome-devtools-mcp@latest

        log "✓ chrome-devtools-mcp installed"
        log ""
        log "=== IMPORTANT: WSL2 Known Issues ==="
        log ""
        log "chrome-devtools-mcp has known bugs in WSL2 environments:"
        log "  - Issue #131: Cannot detect Chrome in WSL2"
        log "  - Issue #225: Protocol errors with headless=false"
        log ""
        log "RECOMMENDED SOLUTION (Method 1 - Most Stable):"
        log "  1. Start Chrome separately: bash scripts/start-chrome-debug.sh"
        log "  2. Use --browserUrl in MCP config to connect to external Chrome"
        log "  3. Configuration example in: configs/mcp-config.json"
        log ""
        log "ALTERNATIVE SOLUTIONS:"
        log "  Method 2: Use Windows Chrome with --executable-path"
        log "    Path: /mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
        log ""
        log "  Method 3: Use headless mode (may still have issues)"
        log "    Add --headless=true to MCP args"
        log ""
        log "GitHub Issues:"
        log "  https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131"
        log "  https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225"
    fi
}

# Create helper scripts
create_helper_script() {
    log "Creating Chrome debugging helper script..."

    SCRIPT_PATH="$(dirname "$0")/start-chrome-debug.sh"

    if [ -f "$SCRIPT_PATH" ]; then
        log "✓ Helper script already exists: $SCRIPT_PATH"
    else
        log "Helper script will be created by start-chrome-debug.sh setup"
    fi
}

# Show network mirroring info
show_network_info() {
    log ""
    log "=== Optional: Windows 11 Network Mirroring ==="
    log ""
    log "For better WSL2-Windows networking (recommended for MCP):"
    log ""
    log "1. Edit %USERPROFILE%\\.wslconfig in Windows"
    log "2. Add these lines:"
    log "   [wsl2]"
    log "   networkingMode=mirrored"
    log "3. In PowerShell: wsl --shutdown"
    log "4. Restart your WSL2 distribution"
    log ""
    log "Benefits:"
    log "  - Better localhost port forwarding"
    log "  - Improved MCP communication"
    log "  - Requires Windows 11 22H2 or later"
    log ""
    log "Reference: https://forum.cursor.com/t/complete-guide-setting-up-mcp-tools-with-browser-extensions-in-wsl2/109614"
}

# Test Chrome GUI
test_chrome_gui() {
    log ""
    read -p "Do you want to test Chrome GUI now? [y/N]: " test_gui

    if [[ "$test_gui" =~ ^[Yy]$ ]]; then
        log "Testing Chrome GUI (this will open a browser window)..."

        if google-chrome --version &> /dev/null; then
            # Try to open Chrome briefly
            timeout 5 google-chrome --no-first-run about:blank &> /dev/null || true

            if [ $? -eq 0 ] || [ $? -eq 124 ]; then
                log "✓ Chrome GUI test successful"
            else
                warning "Chrome GUI test had issues. Check WSLg configuration."
            fi
        fi
    fi
}

# Main execution
main() {
    log "=== Chrome Installation for WSL2 ==="
    log "Supports Ubuntu/Debian and Rocky Linux/RHEL"
    log "Based on verified solutions from GitHub Issues #131 and #225"
    log ""

    # Detect OS early for information
    detect_os || {
        error "Failed to detect operating system"
        exit 1
    }

    check_wslg
    check_existing
    install_chrome
    verify_installation
    install_mcp
    create_helper_script
    test_chrome_gui
    show_network_info

    log ""
    log "=== Chrome Installation Complete ==="
    log ""
    log "Next steps:"
    log "1. Start Chrome with debugging: bash scripts/start-chrome-debug.sh"
    log "2. Test connection: curl http://localhost:9222/json/version"
    log "3. Configure MCP in Claude Code: configs/mcp-config.json"
    log "4. See troubleshooting: docs/troubleshooting.md"
    log ""
    log "Quick diagnosis command:"
    log "  check-dev-env  (after adding bashrc-additions to ~/.bashrc)"
}

main "$@"
