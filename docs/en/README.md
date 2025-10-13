# WSL2 Development Environment Setup

Complete setup scripts and configuration for a modern development environment on Windows with WSL2, including Claude Code, Gemini CLI, Chrome with MCP integration, and VSCode support.

## Overview

This repository provides automated setup scripts for configuring a complete development environment on WSL2 with:

- **Node.js** (via NVM) for JavaScript/TypeScript development
- **Claude Code CLI** from Anthropic
- **Gemini CLI** from Google
- **Google Chrome** with WSLg GUI support
- **MCP (Model Context Protocol)** integration with chrome-devtools-mcp
- **SSH key generation** for GitHub
- **VSCode Remote-WSL** integration

## Prerequisites

- Windows 10/11 with WSL2 enabled
- WSL2 distribution installed (Ubuntu 20.04+ recommended)
- WSLg for GUI support (included in recent WSL2 versions)
- Internet connection

### Check WSL2 Version

```bash
wsl --version  # Run in Windows PowerShell
```

Update WSL if needed:
```bash
wsl --update  # Run in Windows PowerShell
```

## Quick Start

1. Clone this repository in WSL2:
```bash
git clone <repository-url> ~/my_work/dev_setup
cd ~/my_work/dev_setup
```

2. Run the main setup script:
```bash
bash setup.sh
```

3. Follow the interactive prompts to select what to install

4. After installation, reload your shell:
```bash
source ~/.bashrc
```

## Project Structure

```
dev_setup/
├── setup.sh                      # Main setup orchestration script
├── scripts/
│   ├── install-nodejs.sh         # Node.js and NVM installation
│   ├── install-claude-code.sh    # Claude Code CLI installation
│   ├── install-gemini.sh         # Gemini CLI installation
│   ├── install-chrome.sh         # Chrome and MCP installation
│   ├── start-chrome-debug.sh     # Chrome remote debugging launcher
│   └── setup-ssh-key.sh          # SSH key generation and GitHub setup
├── configs/
│   ├── mcp-config.json           # MCP configuration example
│   └── bashrc-additions          # Environment variables and aliases
├── docs/
│   └── troubleshooting.md        # Comprehensive troubleshooting guide
├── README.md                     # This file
└── CLAUDE.md                     # Guide for Claude Code instances
```

## Installation Guide

### Option 1: Full Installation

Install everything at once:

```bash
bash setup.sh
# Select option 1 (Full setup)
```

### Option 2: Component Installation

Install components individually:

#### Node.js (Required First)

```bash
bash scripts/install-nodejs.sh
```

This installs:
- NVM (Node Version Manager)
- Latest Node.js LTS version
- npm with global package support

#### Claude Code

```bash
bash scripts/install-claude-code.sh
```

Requires an Anthropic API key from: https://console.anthropic.com/settings/keys

**Automatic setup:**
- Installs Claude CLI
- Adds chrome-devtools MCP server via `claude mcp add` command
- Automatically adds WSL2 workaround argument (`--browserUrl`) with jq
- Config file: `~/.config/claude/config.json`

#### Gemini CLI

```bash
bash scripts/install-gemini.sh
```

Uses Google Account OAuth authentication (no API key required):
- Run `gemini` command after installation
- Follow the login prompts to authenticate with your Google account
- Free tier: Gemini 2.5 Pro, 60 requests/min, 1,000 requests/day

**Automatic setup:**
- Installs Gemini CLI
- Adds chrome-devtools MCP server via `gemini mcp add` command
- Automatically adds WSL2 workaround argument (`--browserUrl`) with jq
- Config file: `~/.gemini/settings.json`

#### Chrome + MCP

```bash
bash scripts/install-chrome.sh
```

This installs:
- Google Chrome for WSL2
- Remote debugging setup scripts (`start-chrome-debug.sh`)

**Note:** chrome-devtools-mcp is not installed globally via npm. It's automatically downloaded via `npx` when run from each CLI's MCP configuration.

#### SSH Keys for GitHub

```bash
bash scripts/setup-ssh-key.sh
```

Generates SSH keys (ED25519 or RSA) and provides GitHub setup instructions.

## Chrome Remote Debugging & MCP

### Why This Setup?

The `chrome-devtools-mcp` package has **documented bugs** in WSL2 environments:

- **GitHub Issue #131**: Cannot detect Chrome in WSL2
  - https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131
- **GitHub Issue #225**: Protocol errors with `headless=false`
  - https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225

**Our Solution** (verified by the community):

1. Running Chrome separately with remote debugging enabled
2. Connecting MCP to the external Chrome instance via `--browserUrl` parameter
3. This completely avoids both bugs

### Starting Chrome for MCP

```bash
bash scripts/start-chrome-debug.sh
```

This starts Chrome with:
- Remote debugging on port 9222 (configurable)
- Separate profile directory
- GUI window via WSLg

### Verifying Chrome Debugging

```bash
curl http://localhost:9222/json/version
```

You should see JSON output with Chrome version information.

### MCP Configuration

**✅ Automatic Setup (Recommended)**

Installation scripts (`install-claude-code.sh`, `install-gemini.sh`) automatically configure MCP:
1. Add chrome-devtools server via CLI's `mcp add` command
2. Automatically add `--browserUrl=http://localhost:9222` argument with jq

No additional configuration needed after installation! Just start Chrome debugging:
```bash
bash scripts/start-chrome-debug.sh
```

---

**Manual Configuration (Reference)**

Configuration is already done, but if you want to change it manually:

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": [
        "-y",
        "chrome-devtools-mcp@latest",
        "--browserUrl=http://localhost:9222"
      ]
    }
  }
}
```

**Alternative Methods (Advanced):**

See `configs/mcp-config.json` for:
- Method 2: Using Windows Chrome directly with `--executable-path`
- Method 3: Using WSL Chrome with `--headless` mode
- Windows 11 network mirroring configuration
- Multiple Chrome instances setup

**Configuration File Locations:**
- Claude Code: `~/.config/claude/config.json`
- Gemini CLI: `~/.gemini/settings.json`

## Environment Configuration

### Automatic Setup

The installation scripts automatically add necessary configuration to `~/.bashrc`. Key additions:

- NVM initialization
- npm global path
- API keys (you'll need to add the actual keys)
- SSH agent auto-start
- Chrome debugging port
- Useful aliases and functions

### Manual Configuration

If you prefer manual setup, see `configs/bashrc-additions` for all the environment variables and functions you can add.

### API Keys

Edit your `~/.bashrc` and add your actual API keys:

```bash
export ANTHROPIC_API_KEY='your-anthropic-api-key-here'
```

**Note:** Gemini CLI uses OAuth authentication, so no API key is required.

## Usage

### Claude Code

```bash
claude --help                    # Show help
claude                          # Start interactive session
```

### Gemini CLI

```bash
gemini                          # Start interactive session (authenticate on first run)
gemini --help                   # Show help
```

### Chrome Debugging

```bash
chrome-debug                    # Start Chrome with debugging (alias)
chrome-stop                     # Stop Chrome debugging (alias)
check-chrome-debug              # Check if Chrome is running (function)
```

### Development Environment Check

```bash
check-dev-env                   # Show status of all components
```

## VSCode Integration

### Install VSCode Remote-WSL Extension

1. Install VSCode on Windows
2. Install the "Remote - WSL" extension
3. Open WSL2 terminal and run:
   ```bash
   code .
   ```

VSCode will automatically connect to your WSL2 environment.

### VSCode with Claude Code

Once everything is set up:
1. Claude Code will work in the integrated terminal
2. MCP servers will be accessible if configured
3. Chrome debugging can run in the background

## Troubleshooting

**For comprehensive troubleshooting, see [`docs/troubleshooting.md`](docs/troubleshooting.md)**

This guide includes verified solutions from:
- GitHub Issue #131: https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131
- GitHub Issue #225: https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225
- Cursor Forum: https://forum.cursor.com/t/complete-guide-setting-up-mcp-tools-with-browser-extensions-in-wsl2/109614

### Common Chrome MCP Issues

#### Issue #131: Chrome Not Detected in WSL2

**Problem:** MCP cannot find Chrome browser in WSL2

**Solution:** Use external Chrome with `--browserUrl`
```bash
bash scripts/start-chrome-debug.sh
curl http://localhost:9222/json/version  # Verify
```

**Alternative:** Point to Windows Chrome
```json
{
  "args": [
    "chrome-devtools-mcp@latest",
    "--executable-path=/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
  ]
}
```

#### Issue #225: Protocol Error with headless=false

**Problem:** `Protocol error (Target.setDiscoverTargets): Target closed`

**Solution:** Use external Chrome instance (Method 1) - this avoids the issue entirely

**Alternative:** Fix WSLg configuration
```bash
# Check WSLg
echo $DISPLAY        # Should show :0 or similar

# Update WSL (in PowerShell)
wsl --update
wsl --shutdown
```

### Chrome Won't Start

```bash
echo $DISPLAY        # Should show :0 or similar
xeyes               # Test X11 (install with: sudo apt install x11-apps)
```

**Fix:** Update WSL
```powershell
# In Windows PowerShell
wsl --update
wsl --version    # Should be 2.0.0+
wsl --shutdown
```

### MCP Connection Issues

1. Verify Chrome is running:
   ```bash
   lsof -i :9222
   ```

2. Test the connection:
   ```bash
   curl http://localhost:9222/json/version
   ```

3. Check Chrome process:
   ```bash
   ps aux | grep chrome | grep remote-debugging
   ```

4. Enable debug logging:
   ```json
   {
     "args": [
       "chrome-devtools-mcp@latest",
       "--browserUrl=http://localhost:9222",
       "--log-file=/tmp/chrome-mcp.log"
     ]
   }
   ```

### Node.js / npm Issues

Reload NVM:
```bash
source ~/.bashrc
nvm use --lts
```

Check global packages location:
```bash
npm config get prefix    # Should be ~/.npm-global
```

### SSH Key Issues

Test GitHub connection:
```bash
ssh -T git@github.com
```

Check SSH agent:
```bash
ssh-add -l              # List loaded keys
```

### PATH Issues

Check your PATH:
```bash
echo $PATH
```

Should include:
- `$HOME/.npm-global/bin`
- `$HOME/.nvm/versions/node/*/bin`

### Windows 11 Network Mirroring (Optional)

For better WSL2-Windows networking:

1. Edit `%USERPROFILE%\.wslconfig` in Windows:
   ```ini
   [wsl2]
   networkingMode=mirrored
   ```

2. Restart WSL:
   ```powershell
   wsl --shutdown
   ```

Benefits: Better localhost forwarding, improved MCP communication

## Customization

### Change Chrome Debug Port

```bash
export CHROME_DEBUG_PORT=9223
bash scripts/start-chrome-debug.sh
```

Update MCP config to match the new port.

### Multiple Chrome Instances

You can run multiple Chrome instances on different ports for different purposes. See `configs/mcp-config.json` for examples.

## Security Notes

- **Never commit API keys** to version control
- Keep `~/.bashrc` private
- SSH keys should remain in `~/.ssh/` with proper permissions (600 for private keys)
- Be cautious when running scripts from the internet

## Updating

### Update Node.js

```bash
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'
```

### Update npm Packages

```bash
npm-update-global              # Update all global packages (function)
# Or manually:
npm update -g
```

### Update Chrome

```bash
sudo apt-get update
sudo apt-get upgrade google-chrome-stable
```

### Update Claude Code

```bash
npm update -g @anthropic-ai/claude-code
```

## Additional Resources

### Official Documentation
- [WSL2 Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [Claude Code Documentation](https://docs.anthropic.com/)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [NVM Documentation](https://github.com/nvm-sh/nvm)
- [Chrome DevTools MCP](https://github.com/ChromeDevTools/chrome-devtools-mcp)

### Verified GitHub Issues
- [Issue #131 - WSL2 Chrome Detection](https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131)
- [Issue #225 - Headless Protocol Error](https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225)

### Community Guides
- [Cursor Forum - WSL2 MCP Setup](https://forum.cursor.com/t/complete-guide-setting-up-mcp-tools-with-browser-extensions-in-wsl2/109614)
- [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/)

## Contributing

Feel free to customize these scripts for your own use case. If you find bugs or have improvements, please update the scripts accordingly.

## License

These scripts are provided as-is for personal use. Modify and distribute as needed.
