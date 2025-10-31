# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a WSL2 development environment setup repository containing automated installation and configuration scripts for:
- Node.js development environment (via NVM)
- Claude Code CLI and Gemini CLI
- Chrome with MCP (Model Context Protocol) integration
- SSH key setup for GitHub
- VSCode Remote-WSL integration

## Architecture Overview

### Component Dependencies

```
Windows Host
  └─> WSL2 (Ubuntu/Debian Linux)
       ├─> Node.js (installed via NVM)
       │    ├─> Claude Code CLI (npm global package)
       │    ├─> Gemini CLI (npm global package)
       │    └─> chrome-devtools-mcp (npm global package)
       ├─> Google Chrome (native Linux application via WSLg)
       │    └─> Remote debugging on localhost:9222
       └─> VSCode Server (via Remote-WSL extension)
```

### Key Technical Points

**MCP Chrome Integration Workaround**
- chrome-devtools-mcp had known limitations in WSL2 environments
- **GitHub Issue #131** (✅ CLOSED): Cannot detect Chrome in WSL2 (https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131)
  - **Status**: Workaround methods officially documented
- **GitHub Issue #225** (✅ CLOSED, Oct 2025): Protocol errors with headless=false (https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225)
  - **Status**: Fixed in v0.7.0 with Puppeteer improvements
- **Verified Solution**: Run Chrome externally with `--remote-debugging-port=9222`
- MCP connects to external Chrome via `--browserUrl=http://localhost:9222` parameter
- Script: `scripts/start-chrome-debug.sh` implements this workaround
- Alternative methods documented in `configs/mcp-config.json`
- **Recommended**: Use chrome-devtools-mcp v0.7.0 or higher

**PATH Configuration**
- npm global packages: `~/.npm-global/bin`
- NVM managed Node.js: `~/.nvm/versions/node/*/bin`
- These paths are added to `~/.bashrc` by installation scripts

**WSLg Requirement**
- Chrome GUI requires WSLg (WSL2's GUI support)
- Environment variable: `$DISPLAY` should be set (typically `:0`)
- Update WSL if GUI apps don't work: `wsl --update` (in PowerShell)
- Network mirroring mode (Windows 11 22H2+) improves MCP connectivity

## Project Structure

```
dev_setup/
├── setup.sh                   # Main orchestration script (interactive menu)
├── scripts/                   # Individual installation scripts
│   ├── install-nodejs.sh      # NVM + Node.js LTS
│   ├── install-claude-code.sh # Claude Code + API key setup + MCP configuration
│   ├── install-gemini.sh      # Gemini CLI + OAuth authentication + MCP configuration
│   ├── install-chrome.sh      # Chrome + chrome-devtools-mcp
│   ├── start-chrome-debug.sh  # Chrome remote debugging launcher
│   ├── setup-ssh-key.sh       # SSH key generation (ED25519/RSA)
│   └── check-versions.sh      # Version checker for installed tools
├── configs/
│   ├── mcp-config.json        # MCP configuration template
│   └── bashrc-additions       # Environment variables and helper functions
├── docs/
│   └── troubleshooting.md     # Comprehensive troubleshooting guide
├── README.md                  # User-facing documentation
└── CLAUDE.md                  # This file
```

## Common Development Commands

### Running Installation Scripts

Each script is idempotent and checks for existing installations:

```bash
# Full setup (interactive)
bash setup.sh

# Individual components
bash scripts/install-nodejs.sh
bash scripts/install-claude-code.sh
bash scripts/install-gemini.sh
bash scripts/install-chrome.sh
bash scripts/setup-ssh-key.sh
```

### Testing Components

```bash
# Check Node.js
node --version
npm --version
nvm --version

# Check CLI tools
claude --version
gemini --version

# Check Chrome
google-chrome --version

# Check Chrome debugging
curl http://localhost:9222/json/version

# Check SSH
ssh -T git@github.com

# Comprehensive check (uses function from bashrc-additions)
check-dev-env

# Check versions and updates (NEW)
check-versions           # Detailed version check with update recommendations
bash scripts/check-versions.sh  # Or run script directly
```

### Chrome Remote Debugging

```bash
# Start Chrome with debugging
bash scripts/start-chrome-debug.sh

# Check if running (uses bashrc function)
check-chrome-debug

# Stop Chrome debugging
pkill -f 'chrome.*remote-debugging-port=9222'
```

## ⚠️ IMPORTANT: Chrome Debugging Requirement for MCP

**BEFORE using Chrome MCP features with Claude Code or Gemini CLI:**

1. **ALWAYS ensure Chrome is running in debug mode** on port 9222:
   ```bash
   bash scripts/start-chrome-debug.sh
   ```

2. **Verify Chrome debugging is active:**
   ```bash
   curl http://localhost:9222/json/version
   ```
   - Should return JSON with Chrome version info
   - If connection refused: Chrome debug mode is NOT running

3. **If MCP connection fails:**
   ```bash
   # Check if Chrome debug port is active
   lsof -i :9222

   # If nothing found, start Chrome debugging
   bash scripts/start-chrome-debug.sh
   ```

**Why this is critical:**
- MCP configuration uses `--browserUrl=http://localhost:9222`
- Without Chrome running in debug mode, all MCP chrome-devtools commands will fail
- Installation scripts configure MCP automatically, but Chrome must be started manually each time

**Auto-start Chrome debugging (optional):**
Add to `~/.bashrc`:
```bash
# Auto-start Chrome debugging if not running
if ! lsof -i :9222 &>/dev/null; then
    bash ~/my_work/wsl2-ai-dev-setup/scripts/start-chrome-debug.sh &
fi
```

## Modifying Scripts

### Script Structure Pattern

All installation scripts follow this pattern:

1. **Color definitions** - For terminal output formatting
2. **Helper functions** - `log()`, `error()`, `warning()`
3. **Check existing installation** - Avoid duplicate installs
4. **Dependency checks** - Verify prerequisites
5. **Installation logic** - Core installation steps
6. **Configuration** - Setup config files, environment variables
7. **Verification** - Test that installation succeeded
8. **User guidance** - Next steps instructions

### When Modifying Installation Scripts

- Always check for existing installations first
- Use `set -e` to exit on errors
- Provide clear log messages at each step
- Add configuration to `~/.bashrc` only if not already present
- Make scripts executable: `chmod +x scripts/*.sh`
- Test both fresh installation and re-run scenarios

### Testing Script Changes

```bash
# Dry-run approach: Review what would be added to bashrc
grep -A 5 "npm global packages" ~/.bashrc

# Test individual script
bash scripts/install-nodejs.sh

# Verify no duplicates in bashrc
sort ~/.bashrc | uniq -d
```

## Configuration Files

### configs/mcp-config.json

Template for Claude Code MCP configuration based on verified GitHub solutions.

**Key points:**
- Uses `--browserUrl=http://localhost:9222` (explicit flag syntax)
- This requires Chrome to be started separately via `start-chrome-debug.sh`
- Includes references to GitHub Issues #131 and #225
- Documents three alternative methods:
  1. **Method 1 (Recommended)**: External Chrome with --browserUrl
  2. **Method 2**: Windows Chrome with --executable-path
  3. **Method 3**: WSL Chrome with --headless (not recommended)
- Includes Windows 11 network mirroring configuration
- Copy to actual Claude Code config location (varies by installation)

### configs/bashrc-additions

Reference for all environment variables and functions that get added to `~/.bashrc`:
- NVM initialization
- npm global path
- Anthropic API key (placeholder - user must fill in)
- Gemini CLI authentication (OAuth - no API key needed)
- SSH agent auto-start
- Useful aliases and functions
- Chrome debugging helpers

## Troubleshooting Guide

**IMPORTANT**: For comprehensive troubleshooting, see `docs/troubleshooting.md`

This guide is based on verified solutions from:
- GitHub Issue #131: https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131
- GitHub Issue #225: https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225
- Cursor Forum: https://forum.cursor.com/t/complete-guide-setting-up-mcp-tools-with-browser-extensions-in-wsl2/109614

### Common Chrome MCP Issues

**Issue #131: Chrome Not Detected in WSL2**
- **Problem**: MCP cannot find Chrome browser, only searches inside WSL
- **Solution**: Use `--browserUrl=http://localhost:9222` to connect to external Chrome
- **Script**: `bash scripts/start-chrome-debug.sh`
- **Config**: See `configs/mcp-config.json` method 1

**Issue #225: Protocol Error with headless=false**
- **Problem**: `Protocol error (Target.setDiscoverTargets): Target closed`
- **Cause**: WSLg not properly configured or GUI mode issues
- **Solution**: Use external Chrome instance (avoids the issue entirely)
- **Alternative**: Use `--headless=true` or fix WSLg configuration

### Quick Fixes

**"Node.js not found" after installation**
- Cause: Shell hasn't loaded new PATH
- Fix: `source ~/.bashrc` or restart terminal

**"Chrome won't start" or "No display"**
- Cause: WSLg not properly configured
- Check: `echo $DISPLAY` should show `:0` or similar
- Fix: Update WSL in PowerShell: `wsl --update` then `wsl --shutdown`

**"MCP can't connect to Chrome"**
- Cause: Chrome not running with remote debugging
- Check: `curl http://localhost:9222/json/version`
- Fix: Run `bash scripts/start-chrome-debug.sh`

**"Port 9222 already in use"**
- Cause: Another Chrome instance is running
- Check: `lsof -i :9222`
- Fix: Kill it: `pkill -f 'chrome.*remote-debugging-port'`
- Alternative: Use different port: `export CHROME_DEBUG_PORT=9223`

**"Permission denied" for scripts**
- Cause: Scripts not executable
- Fix: `chmod +x setup.sh scripts/*.sh`

### Debugging Approach

When issues occur:

1. Check environment: `check-dev-env` (function from bashrc-additions)
2. Verify PATH: `echo $PATH`
3. Check Chrome: `curl http://localhost:9222/json/version`
4. Check processes: `ps aux | grep -E 'chrome.*remote-debugging'`
5. Check WSLg: `echo $DISPLAY`
6. Check ports: `lsof -i :9222`
7. Review logs: `setup.log` created by main script
8. MCP debug: Add `--log-file=/tmp/chrome-mcp.log` to config

### Comprehensive Troubleshooting

See `docs/troubleshooting.md` for:
- Detailed problem diagnosis
- Step-by-step solutions
- Network mirroring configuration
- WSLg setup and testing
- All known workarounds

## Important Constraints

### Security

- **Never include actual API keys** in repository files
- Scripts prompt for API keys and add to `~/.bashrc` locally
- `~/.bashrc` should not be committed to git
- SSH private keys stay in `~/.ssh/` with 600 permissions

### WSL2 Specific

- All paths use Linux format: `/home/user/...` not `C:\Users\...`
- Windows filesystem accessible at `/mnt/c/` but use Linux filesystem for performance
- Chrome requires WSLg - won't work in older WSL versions

### Script Safety

- All scripts check for existing installations
- User prompted before overwriting
- `set -e` ensures scripts fail fast on errors
- Idempotent design: safe to run multiple times

## Extension Points

### Adding New Tools

To add a new tool installation:

1. Create `scripts/install-<tool>.sh` following the existing pattern
2. Add option to `setup.sh` menu
3. Update `README.md` with usage instructions
4. Add any necessary environment variables to `configs/bashrc-additions`
5. Test fresh install and re-run scenarios

### Adding MCP Servers

To add additional MCP servers:

1. Install the server package: `npm install -g <mcp-package>`
2. Add configuration to `configs/mcp-config.json`
3. Document any special setup requirements
4. Test integration with Claude Code

### Custom Chrome Profiles

For multiple Chrome debugging instances:

1. Use different ports: `export CHROME_DEBUG_PORT=9223`
2. Use different user-data-dir in start script
3. Create separate MCP config entries
4. Document in README.md

## Version Information

These scripts are designed for:
- WSL2 (Windows 10/11 with recent updates)
- Ubuntu 20.04+ or Debian-based distributions
- Rocky Linux 9+ / RHEL-based distributions
- Node.js LTS versions (via NVM)
- Latest stable versions of CLI tools
- **chrome-devtools-mcp v0.9.0+** (current latest: v0.9.0, October 2025)

**chrome-devtools-mcp Version Status:**
- **Current Latest**: v0.9.0 (October 22, 2025)
- **Recommended**: v0.9.0+ for WSL2 users
- **Key Features in v0.9.0**: WebSocket endpoint support, official VM documentation, dependency bundling
- **Detailed Version History**: See `chrome-devtools-mcp-CHANGELOG.md`

**Known Issues Tracking:**
- **Chrome detection in WSL2**: GitHub Issue #131 (✅ CLOSED)
  - **Status**: ❌ Not fundamentally resolved (architectural limitation)
  - **Solution**: Use `--browserUrl` or `--wsEndpoint` (official workaround)
- **Headless protocol errors**: GitHub Issue #225 (✅ CLOSED)
  - **Status**: ⚠️ Stability improved in v0.7.0+, workaround is official method
  - **Solution**: External Chrome with `--browserUrl` or `--wsEndpoint`
- **Repository's approach**: Implements official recommended workarounds

When updating for new versions:
- Test on clean WSL2 installation
- Check chrome-devtools-mcp version (use `check-versions` script)
- Review CHANGELOG for breaking changes
- Note that Issues #131 and #225 workarounds remain necessary
- Update version numbers in documentation
- Check for breaking changes in dependencies
- Update NVM install URL if needed (in install-nodejs.sh)

## References

### Official Documentation
- Chrome DevTools MCP: https://github.com/ChromeDevTools/chrome-devtools-mcp
- Model Context Protocol: https://modelcontextprotocol.io/
- WSL Documentation: https://docs.microsoft.com/en-us/windows/wsl/

### GitHub Issues (Verified Solutions)
- Issue #131 - WSL2 Chrome Detection: https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131
- Issue #225 - Headless Protocol Error: https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225

### Community Guides
- Cursor Forum WSL2 Guide: https://forum.cursor.com/t/complete-guide-setting-up-mcp-tools-with-browser-extensions-in-wsl2/109614
- Chrome DevTools Protocol: https://chromedevtools.github.io/devtools-protocol/
