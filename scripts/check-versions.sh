#!/bin/bash

# Version Check Script for WSL2 AI Development Environment
# Checks installed versions of all development tools

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "${SCRIPT_DIR}/common.sh"

# Print header
echo -e "\n${BLUE}============================================${NC}"
echo -e "${BLUE}  WSL2 AI Dev Environment - Version Check${NC}"
echo -e "${BLUE}============================================${NC}\n"

# Function to compare versions (simple numeric comparison)
version_compare() {
    local current="$1"
    local latest="$2"

    if [[ "$current" == "$latest" ]]; then
        echo "latest"
    else
        echo "outdated"
    fi
}

# Function to check command existence
command_exists() {
    command -v "$1" &> /dev/null
}

# Check NVM
echo -e "${BLUE}[NVM (Node Version Manager)]${NC}"
if command_exists nvm; then
    NVM_VERSION=$(nvm --version 2>/dev/null || echo "unknown")
    echo -e "  Installed: ${GREEN}${NVM_VERSION}${NC}"
    echo -e "  Latest: v0.40.1 (as of Jan 2025)"
    if [[ "$NVM_VERSION" < "0.40.0" ]]; then
        echo -e "  Status: ${YELLOW}⚠ Update recommended${NC}"
        echo -e "  Update: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"
    else
        echo -e "  Status: ${GREEN}✓ Up to date${NC}"
    fi
else
    echo -e "  Status: ${RED}✗ Not installed${NC}"
fi
echo ""

# Check Node.js
echo -e "${BLUE}[Node.js]${NC}"
if command_exists node; then
    NODE_VERSION=$(node --version | sed 's/v//')
    echo -e "  Installed: ${GREEN}v${NODE_VERSION}${NC}"

    # Get current LTS version from nvm if available
    if command_exists nvm; then
        LTS_VERSION=$(nvm version-remote --lts 2>/dev/null | sed 's/v//' || echo "unknown")
        if [[ "$LTS_VERSION" != "unknown" ]]; then
            echo -e "  Latest LTS: v${LTS_VERSION}"
            if [[ "$NODE_VERSION" < "$LTS_VERSION" ]]; then
                echo -e "  Status: ${YELLOW}⚠ LTS update available${NC}"
                echo -e "  Update: nvm install --lts && nvm use --lts"
            else
                echo -e "  Status: ${GREEN}✓ Using current LTS or newer${NC}"
            fi
        else
            echo -e "  Status: ${GREEN}✓ Installed${NC}"
        fi
    else
        echo -e "  Status: ${GREEN}✓ Installed${NC}"
    fi
else
    echo -e "  Status: ${RED}✗ Not installed${NC}"
fi
echo ""

# Check npm
echo -e "${BLUE}[npm (Node Package Manager)]${NC}"
if command_exists npm; then
    NPM_VERSION=$(npm --version)
    echo -e "  Installed: ${GREEN}${NPM_VERSION}${NC}"

    # Try to get latest npm version
    NPM_LATEST=$(npm view npm version 2>/dev/null || echo "unknown")
    if [[ "$NPM_LATEST" != "unknown" ]]; then
        echo -e "  Latest: ${NPM_LATEST}"
        if [[ "$NPM_VERSION" < "$NPM_LATEST" ]]; then
            echo -e "  Status: ${YELLOW}⚠ Update available${NC}"
            echo -e "  Update: npm install -g npm@latest"
        else
            echo -e "  Status: ${GREEN}✓ Up to date${NC}"
        fi
    else
        echo -e "  Status: ${GREEN}✓ Installed${NC}"
    fi
else
    echo -e "  Status: ${RED}✗ Not installed${NC}"
fi
echo ""

# Check Claude Code CLI
echo -e "${BLUE}[Claude Code CLI]${NC}"
if command_exists claude; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
    echo -e "  Installed: ${GREEN}${CLAUDE_VERSION}${NC}"

    # Try to get latest version
    CLAUDE_LATEST=$(npm view @anthropic/claude-code version 2>/dev/null || echo "unknown")
    if [[ "$CLAUDE_LATEST" != "unknown" ]] && [[ "$CLAUDE_VERSION" != "unknown" ]]; then
        echo -e "  Latest: ${CLAUDE_LATEST}"
        if [[ "$CLAUDE_VERSION" < "$CLAUDE_LATEST" ]]; then
            echo -e "  Status: ${YELLOW}⚠ Update available${NC}"
            echo -e "  Update: npm install -g @anthropic/claude-code@latest"
        else
            echo -e "  Status: ${GREEN}✓ Up to date${NC}"
        fi
    else
        echo -e "  Status: ${GREEN}✓ Installed${NC}"
    fi
else
    echo -e "  Status: ${RED}✗ Not installed${NC}"
fi
echo ""

# Check Gemini CLI
echo -e "${BLUE}[Gemini CLI]${NC}"
if command_exists gemini; then
    GEMINI_VERSION=$(gemini --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
    echo -e "  Installed: ${GREEN}${GEMINI_VERSION}${NC}"

    # Try to get latest version
    GEMINI_LATEST=$(npm view @google/generative-ai-cli version 2>/dev/null || echo "unknown")
    if [[ "$GEMINI_LATEST" != "unknown" ]] && [[ "$GEMINI_VERSION" != "unknown" ]]; then
        echo -e "  Latest: ${GEMINI_LATEST}"
        if [[ "$GEMINI_VERSION" < "$GEMINI_LATEST" ]]; then
            echo -e "  Status: ${YELLOW}⚠ Update available${NC}"
            echo -e "  Update: npm install -g @google/generative-ai-cli@latest"
        else
            echo -e "  Status: ${GREEN}✓ Up to date${NC}"
        fi
    else
        echo -e "  Status: ${GREEN}✓ Installed${NC}"
    fi
else
    echo -e "  Status: ${RED}✗ Not installed${NC}"
fi
echo ""

# Check Google Chrome
echo -e "${BLUE}[Google Chrome]${NC}"
if command_exists google-chrome; then
    CHROME_VERSION=$(google-chrome --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "unknown")
    echo -e "  Installed: ${GREEN}${CHROME_VERSION}${NC}"
    echo -e "  Status: ${GREEN}✓ Installed${NC}"
    echo -e "  Note: Chrome updates automatically"
else
    echo -e "  Status: ${RED}✗ Not installed${NC}"
fi
echo ""

# Check chrome-devtools-mcp
echo -e "${BLUE}[chrome-devtools-mcp]${NC}"
MCP_INSTALLED=false

# Check if installed globally
if npm list -g chrome-devtools-mcp &>/dev/null; then
    MCP_VERSION=$(npm list -g chrome-devtools-mcp 2>/dev/null | grep chrome-devtools-mcp | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    echo -e "  Installed (global): ${GREEN}${MCP_VERSION}${NC}"
    MCP_INSTALLED=true
fi

# Check latest version
MCP_LATEST=$(npm view chrome-devtools-mcp version 2>/dev/null || echo "unknown")
if [[ "$MCP_LATEST" != "unknown" ]]; then
    echo -e "  Latest: ${MCP_LATEST}"

    # Check if version is 0.9.0 or higher (recommended for WSL2)
    if [[ "$MCP_INSTALLED" == "true" ]] && [[ "$MCP_VERSION" != "unknown" ]]; then
        if [[ "$MCP_VERSION" < "0.7.0" ]]; then
            echo -e "  Status: ${YELLOW}⚠ Critical update needed (v0.7.0+ required)${NC}"
            echo -e "  Update: npm install -g chrome-devtools-mcp@latest"
            echo -e "  Note: v0.7.0+ includes stability improvements for WSL2"
        elif [[ "$MCP_VERSION" < "0.9.0" ]]; then
            echo -e "  Status: ${YELLOW}⚠ Update recommended (v0.9.0+ adds WebSocket endpoint)${NC}"
            echo -e "  Update: npm install -g chrome-devtools-mcp@latest"
            echo -e "  Note: v0.9.0 adds WebSocket endpoint support and VM documentation"
        elif [[ "$MCP_VERSION" < "$MCP_LATEST" ]]; then
            echo -e "  Status: ${YELLOW}⚠ Update available${NC}"
            echo -e "  Update: npm install -g chrome-devtools-mcp@latest"
        else
            echo -e "  Status: ${GREEN}✓ Up to date (v0.9.0+)${NC}"
        fi
    else
        echo -e "  Status: ${YELLOW}⚠ Using npx (not globally installed)${NC}"
        echo -e "  Note: Latest version will be used automatically with npx"
        echo -e "  Current latest: v${MCP_LATEST}"
    fi
else
    if [[ "$MCP_INSTALLED" == "true" ]]; then
        echo -e "  Status: ${GREEN}✓ Installed${NC}"
    else
        echo -e "  Status: ${YELLOW}⚠ Not globally installed (using npx)${NC}"
    fi
fi
echo ""

# Check Chrome Remote Debugging
echo -e "${BLUE}[Chrome Remote Debugging]${NC}"
if curl -s http://localhost:9222/json/version &>/dev/null; then
    CHROME_DEBUG_VERSION=$(curl -s http://localhost:9222/json/version | grep -oP '"Browser":\s*"[^"]*"' | cut -d'"' -f4)
    echo -e "  Status: ${GREEN}✓ Running${NC}"
    echo -e "  Version: ${CHROME_DEBUG_VERSION}"
    echo -e "  Port: 9222"
else
    echo -e "  Status: ${YELLOW}⚠ Not running${NC}"
    echo -e "  Start: bash ${SCRIPT_DIR}/start-chrome-debug.sh"
fi
echo ""

# Summary
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}============================================${NC}\n"

NEEDS_UPDATE=0

if command_exists nvm; then
    NVM_VERSION=$(nvm --version 2>/dev/null || echo "0")
    if [[ "$NVM_VERSION" < "0.40.0" ]]; then
        echo -e "${YELLOW}⚠ NVM update recommended${NC}"
        NEEDS_UPDATE=1
    fi
fi

if command_exists claude; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "0")
    CLAUDE_LATEST=$(npm view @anthropic/claude-code version 2>/dev/null || echo "0")
    if [[ "$CLAUDE_VERSION" != "0" ]] && [[ "$CLAUDE_LATEST" != "0" ]] && [[ "$CLAUDE_VERSION" < "$CLAUDE_LATEST" ]]; then
        echo -e "${YELLOW}⚠ Claude Code CLI update available${NC}"
        NEEDS_UPDATE=1
    fi
fi

if command_exists gemini; then
    GEMINI_VERSION=$(gemini --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "0")
    GEMINI_LATEST=$(npm view @google/generative-ai-cli version 2>/dev/null || echo "0")
    if [[ "$GEMINI_VERSION" != "0" ]] && [[ "$GEMINI_LATEST" != "0" ]] && [[ "$GEMINI_VERSION" < "$GEMINI_LATEST" ]]; then
        echo -e "${YELLOW}⚠ Gemini CLI update available${NC}"
        NEEDS_UPDATE=1
    fi
fi

if npm list -g chrome-devtools-mcp &>/dev/null; then
    MCP_VERSION=$(npm list -g chrome-devtools-mcp 2>/dev/null | grep chrome-devtools-mcp | grep -oP '\d+\.\d+\.\d+' || echo "0")
    if [[ "$MCP_VERSION" != "0" ]]; then
        if [[ "$MCP_VERSION" < "0.7.0" ]]; then
            echo -e "${YELLOW}⚠ chrome-devtools-mcp v0.7.0+ required (critical stability improvements)${NC}"
            NEEDS_UPDATE=1
        elif [[ "$MCP_VERSION" < "0.9.0" ]]; then
            echo -e "${YELLOW}⚠ chrome-devtools-mcp v0.9.0+ recommended (WebSocket endpoint support)${NC}"
            NEEDS_UPDATE=1
        fi
    fi
fi

if [[ $NEEDS_UPDATE -eq 0 ]]; then
    echo -e "${GREEN}✓ All tools are up to date!${NC}"
else
    echo -e "\n${BLUE}Run the installation scripts again to update, or use the update commands shown above.${NC}"
fi

echo ""
