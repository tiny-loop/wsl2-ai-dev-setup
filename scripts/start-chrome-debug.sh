#!/bin/bash

# Start Chrome with Remote Debugging
# This script starts Google Chrome with remote debugging enabled on port 9222
# Required for chrome-devtools-mcp to work properly

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    source "$SCRIPT_DIR/common.sh"
else
    echo "ERROR: common.sh not found in $SCRIPT_DIR"
    exit 1
fi

# Override log function to add Chrome Debug prefix
log() {
    echo -e "${GREEN}[Chrome Debug]${NC} $1"
}

# Configuration
DEBUG_PORT=${CHROME_DEBUG_PORT:-9222}
USER_DATA_DIR="$HOME/.chrome-debug-profile"

# Check WSLg
check_wslg() {
    log "Checking WSLg environment..."

    if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
        warning "WSLg may not be configured properly!"
        log "DISPLAY: ${DISPLAY:-not set}"
        log "WAYLAND_DISPLAY: ${WAYLAND_DISPLAY:-not set}"
        log ""
        log "Chrome GUI may not work. To fix:"
        log "1. Update WSL: wsl --update (in PowerShell)"
        log "2. Restart WSL: wsl --shutdown"
        log "3. Reopen your terminal"
        log ""

        read -p "Continue anyway? [y/N]: " continue_run
        if [[ ! "$continue_run" =~ ^[Yy]$ ]]; then
            exit 0
        fi
    else
        log "✓ WSLg environment detected"
    fi
}

# Check if Chrome is installed
check_chrome() {
    if ! command -v google-chrome &> /dev/null; then
        error "Google Chrome is not installed"
        error "Run: bash scripts/install-chrome.sh"
        exit 1
    fi

    CHROME_VERSION=$(google-chrome --version 2>/dev/null || echo "unknown")
    log "✓ Chrome found: $CHROME_VERSION"
}

# Check if Chrome is already running on the debug port
check_running() {
    if lsof -i :$DEBUG_PORT &> /dev/null || netstat -tuln 2>/dev/null | grep -q ":$DEBUG_PORT "; then
        warning "Port $DEBUG_PORT is already in use"
        log "Chrome might already be running with remote debugging"
        log ""
        read -p "Kill existing process and restart? [y/N]: " kill_existing

        if [[ "$kill_existing" =~ ^[Yy]$ ]]; then
            log "Stopping existing Chrome process..."
            pkill -f "chrome.*remote-debugging-port=$DEBUG_PORT" || true
            sleep 2
        else
            log "Exiting. Use a different port by setting CHROME_DEBUG_PORT environment variable"
            exit 0
        fi
    fi
}

# Create or verify user data directory
setup_profile() {
    if [ ! -d "$USER_DATA_DIR" ]; then
        log "Creating Chrome debug profile directory: $USER_DATA_DIR"
        mkdir -p "$USER_DATA_DIR"
    fi
}

# Start Chrome with remote debugging
start_chrome() {
    log "Starting Chrome with remote debugging on port $DEBUG_PORT..."
    log "User data directory: $USER_DATA_DIR"
    log ""

    # Chrome flags for remote debugging
    CHROME_FLAGS=(
        --remote-debugging-port=$DEBUG_PORT
        --user-data-dir="$USER_DATA_DIR"
        --no-first-run
        --no-default-browser-check
    )

    # Optional: run in background
    read -p "Run Chrome in background? [Y/n]: " run_bg

    if [[ "$run_bg" =~ ^[Nn]$ ]]; then
        log "Starting Chrome in foreground (Ctrl+C to stop)..."
        google-chrome "${CHROME_FLAGS[@]}"
    else
        log "Starting Chrome in background..."
        google-chrome "${CHROME_FLAGS[@]}" > /dev/null 2>&1 &
        CHROME_PID=$!

        # Wait a moment and verify it started
        sleep 2

        if ps -p $CHROME_PID > /dev/null 2>&1; then
            log "✓ Chrome started successfully (PID: $CHROME_PID)"
            log ""
            log "Chrome is running with remote debugging on http://localhost:$DEBUG_PORT"
            log "To stop: pkill -f 'chrome.*remote-debugging-port=$DEBUG_PORT'"
            log ""
            log "You can now configure chrome-devtools-mcp with:"
            log "  \"browserUrl\": \"http://localhost:$DEBUG_PORT\""
        else
            error "Failed to start Chrome"
            exit 1
        fi
    fi
}

# Test connection
test_connection() {
    log "Testing remote debugging connection..."
    sleep 1

    if curl -s http://localhost:$DEBUG_PORT/json/version > /dev/null 2>&1; then
        log "✓ Remote debugging is accessible at http://localhost:$DEBUG_PORT"
        log ""
        log "Chrome DevTools Protocol endpoint:"
        curl -s http://localhost:$DEBUG_PORT/json/version | grep -o '"webSocketDebuggerUrl":"[^"]*"' || echo "Connected"
    else
        warning "Could not connect to Chrome debugging port"
        warning "This is normal if Chrome is starting up. Wait a few seconds and try:"
        warning "  curl http://localhost:$DEBUG_PORT/json/version"
    fi
}

# Diagnostic information
show_diagnostics() {
    log ""
    log "=== Diagnostic Information ==="
    log ""
    log "Chrome Debug Port: $DEBUG_PORT"
    log "User Data Directory: $USER_DATA_DIR"
    log "DISPLAY: ${DISPLAY:-not set}"
    log "WAYLAND_DISPLAY: ${WAYLAND_DISPLAY:-not set}"
    log ""

    # Check if port is listening
    if lsof -i :$DEBUG_PORT &> /dev/null 2>&1; then
        log "✓ Port $DEBUG_PORT is listening"

        # Show process info
        CHROME_PROC=$(ps aux | grep -v grep | grep "chrome.*remote-debugging-port=$DEBUG_PORT" | head -1)
        if [ -n "$CHROME_PROC" ]; then
            log "Process: $(echo $CHROME_PROC | awk '{print $2, $11, $12, $13}')"
        fi
    else
        warning "Port $DEBUG_PORT is not listening"
    fi

    log ""
}

# Display usage information
show_usage() {
    cat << EOF

=== Chrome Remote Debugging Started ===

This setup is based on verified solutions for WSL2:
  GitHub Issue #131: https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131
  GitHub Issue #225: https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225

Configuration for MCP (chrome-devtools-mcp):
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": [
        "-y",
        "chrome-devtools-mcp@latest",
        "--browserUrl=http://localhost:$DEBUG_PORT"
      ]
    }
  }
}

Copy full configuration from:
  configs/mcp-config.json

Add to your Claude Code config at:
  ~/.config/claude/config.json

=== Verification Commands ===

Test connection:
  curl http://localhost:$DEBUG_PORT/json/version

Check Chrome process:
  ps aux | grep chrome | grep remote-debugging

Check port status:
  lsof -i :$DEBUG_PORT
  netstat -tuln | grep $DEBUG_PORT

Stop Chrome:
  pkill -f 'chrome.*remote-debugging-port=$DEBUG_PORT'

=== Troubleshooting ===

If connection fails:
  1. Wait 5-10 seconds for Chrome to start
  2. Check WSLg: echo \$DISPLAY
  3. Check firewall/port availability
  4. See: docs/troubleshooting.md

EOF
}

# Main execution
main() {
    log "=== Chrome Remote Debugging Setup ==="
    log "Workaround for chrome-devtools-mcp WSL2 issues"
    log ""

    check_wslg
    check_chrome
    check_running
    setup_profile
    start_chrome

    if [[ ! "$run_bg" =~ ^[Nn]$ ]]; then
        sleep 3  # Give Chrome more time to start
        test_connection
        show_diagnostics
        show_usage
    fi
}

main "$@"
