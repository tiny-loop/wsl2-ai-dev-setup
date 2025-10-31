# Troubleshooting Guide

Common issues and solutions for WSL2 development environment setup, with verified solutions from GitHub issues and community forums.

## Table of Contents

1. [Chrome DevTools MCP Issues](#chrome-devtools-mcp-issues)
2. [WSLg (GUI) Issues](#wslg-gui-issues)
3. [Node.js and npm Issues](#nodejs-and-npm-issues)
4. [SSH Key Issues](#ssh-key-issues)
5. [Network and Port Issues](#network-and-port-issues)
6. [General WSL2 Issues](#general-wsl2-issues)

---

## Chrome DevTools MCP Issues

### Issue #131: Chrome Not Detected in WSL2 (✅ CLOSED)

**Status:** Issue closed - Workaround methods officially documented

**Problem:**
- MCP cannot find Chrome browser in WSL2
- Error: "Chrome executable not found"
- MCP only searches inside WSL, ignores Windows Chrome

**Official Issue:** https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131 (CLOSED)

**Solutions:**

#### Method 1: Use --browserUrl (RECOMMENDED)
Start Chrome externally and connect via port forwarding:

```bash
# 1. Start Chrome with remote debugging
bash scripts/start-chrome-debug.sh

# 2. Verify connection
curl http://localhost:9222/json/version

# 3. Configure MCP
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

#### Method 2: Use Windows Chrome directly
Point to Windows Chrome installation:

```json
{
  "args": [
    "-y",
    "chrome-devtools-mcp@latest",
    "--executable-path=/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
  ]
}
```

**Note:** Adjust path if Chrome installed in different location.

#### Method 3: Install Chrome in WSL
Install Linux Chrome within WSL2:

```bash
bash scripts/install-chrome.sh
```

---

### Issue #225: Protocol Error with headless=false (✅ CLOSED)

**Status:** Issue closed (Oct 2025) - Fixed in v0.7.0

**Problem:**
- Error: `Protocol error (Target.setDiscoverTargets): Target closed`
- Occurs when `headless: false` in WSL2 Ubuntu
- Works with `headless: true`

**Official Issue:** https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225 (CLOSED)

**Resolution Status:**
- **chrome-devtools-mcp v0.7.0+** improved stability through Puppeteer enhancements
- Enhanced Chrome detection logic and Windows environment variable recognition
- **Current Latest**: v0.9.0 (October 2025) - WebSocket endpoint support
- v0.9.0 or higher recommended
- Detailed history: [CHANGELOG](chrome-devtools-mcp-CHANGELOG.md)

**Root Cause:**
WSLg (GUI support) not properly configured or Chrome cannot create GUI windows.

**Solutions:**

1. **Use --browserUrl method** (avoids the issue entirely)
   ```bash
   bash scripts/start-chrome-debug.sh
   ```

2. **Fix WSLg configuration**
   ```bash
   # Check WSLg status
   echo $DISPLAY        # Should show :0 or similar
   echo $WAYLAND_DISPLAY

   # Update WSL (in Windows PowerShell)
   wsl --update
   wsl --shutdown

   # Restart your WSL distribution
   ```

3. **Use headless mode** (workaround)
   ```json
   {
     "args": [
       "-y",
       "chrome-devtools-mcp@latest",
       "--headless=true"
     ]
   }
   ```

---

### WebSocket Endpoint Method (v0.9.0+)

chrome-devtools-mcp v0.9.0 onwards supports direct WebSocket endpoint specification. This is an alternative to `--browserUrl`.

**When to use:**
- Custom authentication headers needed
- Direct control over WebSocket URL required
- Advanced scenarios (proxies, custom network configuration, etc.)

**How to use:**

**Step 1: Start Chrome**
```bash
bash scripts/start-chrome-debug.sh
```

**Step 2: Get WebSocket URL**
```bash
curl http://localhost:9222/json/version
```

Example output:
```json
{
  "Browser": "Chrome/141.0.7390.76",
  "Protocol-Version": "1.3",
  "User-Agent": "Mozilla/5.0...",
  "V8-Version": "14.1.201.23",
  "WebKit-Version": "537.36",
  "webSocketDebuggerUrl": "ws://127.0.0.1:9222/devtools/browser/abc123..."
}
```

**Step 3: Configure MCP**

**Basic usage:**
```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": [
        "-y",
        "chrome-devtools-mcp@latest",
        "--wsEndpoint=ws://127.0.0.1:9222/devtools/browser/abc123..."
      ]
    }
  }
}
```

**With authentication headers:**
```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": [
        "-y",
        "chrome-devtools-mcp@latest",
        "--wsEndpoint=ws://127.0.0.1:9222/devtools/browser/abc123...",
        "--wsHeaders={\"Authorization\":\"Bearer YOUR_TOKEN\"}"
      ]
    }
  }
}
```

**browserUrl vs wsEndpoint comparison:**

| Feature | --browserUrl | --wsEndpoint |
|---------|-------------|--------------|
| Ease of use | ⭐ Easy | ⭐⭐ Moderate |
| Auto WebSocket detection | ✅ Automatic | ❌ Manual input required |
| Custom headers support | ❌ Not available | ✅ Use --wsHeaders |
| Recommended for | General users | Advanced users, special requirements |

**Advantages:**
- Custom authentication support
- More granular control
- Useful for proxy/tunneling scenarios

**Disadvantages:**
- Must manually find/copy WebSocket URL
- URL may change on Chrome restart

**Tip**: `--browserUrl` is sufficient for most cases. Only use `--wsEndpoint` for special requirements.

---

### SSH Tunneling Method (VM-to-Host)

**v0.9.0 Official Documentation Added**: Official method for connecting from WSL2/VM to Host Chrome

**Problem:**
Direct connection from WSL2/VM to Host Chrome (Windows) fails due to domain header validation

**Solution:**
Use SSH tunneling to port forward through localhost

```bash
# Run in WSL2/VM
ssh -N -L 127.0.0.1:9222:127.0.0.1:9222 user@host-ip
```

**Explanation:**
- `-N`: Don't execute commands (tunneling only)
- `-L`: Forward local port to remote port
- `127.0.0.1:9222`: WSL2's port 9222
- `user@host-ip`: Windows Host user and IP

**Then configure MCP:**
```json
{
  "args": [
    "chrome-devtools-mcp@latest",
    "--browserUrl=http://127.0.0.1:9222"
  ]
}
```

**Requirements:**
- Chrome on Host must be started with `--remote-debugging-port=9222`
- SSH server must be running on Host (Windows OpenSSH or SSH within WSL2)
- Related to GitHub Issues #131, #225, #328, #139 official workaround

---

## WSLg (GUI) Issues

### WSLg Not Working

**Symptoms:**
- `$DISPLAY` is empty or not set
- GUI apps fail to start
- Chrome window doesn't appear

**Diagnosis:**
```bash
echo $DISPLAY              # Should show :0 or :1
echo $WAYLAND_DISPLAY      # Should show wayland-0 or similar
xeyes                      # Test X11 (install: sudo apt install x11-apps)
```

**Solutions:**

1. **Update WSL** (Windows PowerShell as Administrator)
   ```powershell
   wsl --update
   wsl --version    # Check version (should be 2.0.0+)
   wsl --shutdown
   ```

2. **Check Windows version**
   - WSLg requires Windows 11 or Windows 10 22H2+
   - Check: Settings > System > About

3. **Reinstall WSL distribution** (if update doesn't help)
   ```powershell
   # Backup your data first!
   wsl --unregister Ubuntu
   wsl --install Ubuntu
   ```

4. **Manual DISPLAY setup** (temporary workaround)
   ```bash
   export DISPLAY=:0
   # Add to ~/.bashrc for persistence
   echo 'export DISPLAY=:0' >> ~/.bashrc
   ```

---

## Node.js and npm Issues

### Node/npm Command Not Found After Installation

**Problem:**
```bash
$ node --version
bash: node: command not found
```

**Solutions:**

1. **Reload shell configuration**
   ```bash
   source ~/.bashrc
   # or restart your terminal
   ```

2. **Manually load NVM**
   ```bash
   export NVM_DIR="$HOME/.nvm"
   [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
   ```

3. **Check NVM installation**
   ```bash
   # Verify NVM is installed
   ls -la ~/.nvm

   # Reinstall if needed
   bash scripts/install-nodejs.sh
   ```

### npm Global Package Not Found

**Problem:**
```bash
$ claude
bash: claude: command not found
```

**Solutions:**

1. **Check npm global path**
   ```bash
   npm config get prefix
   # Should be /home/user/.npm-global
   ```

2. **Fix PATH**
   ```bash
   echo $PATH | grep npm-global
   # If not found, add to ~/.bashrc:
   echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

3. **Reinstall the package**
   ```bash
   npm install -g @anthropic-ai/claude-code
   npm install -g chrome-devtools-mcp@latest
   ```

---

## SSH Key Issues

### SSH Key Not Working with GitHub

**Problem:**
- `git push` fails with authentication error
- `ssh -T git@github.com` fails

**Solutions:**

1. **Check SSH key is added to agent**
   ```bash
   ssh-add -l
   # If empty, add your key:
   ssh-add ~/.ssh/id_ed25519
   # or
   ssh-add ~/.ssh/id_rsa
   ```

2. **Verify key on GitHub**
   ```bash
   # Get your public key
   cat ~/.ssh/id_ed25519.pub
   # Copy and add to: https://github.com/settings/keys
   ```

3. **Test GitHub connection**
   ```bash
   ssh -T git@github.com
   # Should see: "Hi username! You've successfully authenticated..."
   ```

4. **Fix SSH permissions**
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_*
   chmod 644 ~/.ssh/id_*.pub
   ```

### MD5 vs SHA256 Fingerprints

**Note:** GitHub now uses SHA256 fingerprints by default, not MD5.

```bash
# View SHA256 fingerprint (GitHub default)
ssh-keygen -lf ~/.ssh/id_ed25519

# View MD5 fingerprint (legacy)
ssh-keygen -E md5 -lf ~/.ssh/id_ed25519
```

---

## Network and Port Issues

### Port Already in Use

**Problem:**
```
Error: Port 9222 is already in use
```

**Solutions:**

1. **Check what's using the port**
   ```bash
   lsof -i :9222
   netstat -tuln | grep 9222
   ```

2. **Kill existing Chrome process**
   ```bash
   pkill -f 'chrome.*remote-debugging-port=9222'
   ```

3. **Use a different port**
   ```bash
   export CHROME_DEBUG_PORT=9223
   bash scripts/start-chrome-debug.sh
   # Update MCP config to match
   ```

### Localhost Connection Refused

**Problem:**
- `curl http://localhost:9222` fails
- MCP cannot connect to Chrome

**Solutions:**

1. **Verify Chrome is running**
   ```bash
   ps aux | grep chrome | grep remote-debugging
   ```

2. **Wait for Chrome to start**
   ```bash
   # Chrome may take 5-10 seconds to initialize
   sleep 5
   curl http://localhost:9222/json/version
   ```

3. **Enable network mirroring** (Windows 11)
   ```ini
   # Edit %USERPROFILE%\.wslconfig
   [wsl2]
   networkingMode=mirrored
   ```
   ```powershell
   # In PowerShell
   wsl --shutdown
   # Restart WSL
   ```

4. **Check firewall**
   ```bash
   # WSL2 uses a virtual network adapter
   # Ensure Windows Firewall allows localhost connections
   ```

---

## General WSL2 Issues

### WSL2 Slow or Unresponsive

**Solutions:**

1. **Increase WSL2 memory** (in `%USERPROFILE%\.wslconfig`)
   ```ini
   [wsl2]
   memory=8GB
   processors=4
   ```

2. **Restart WSL**
   ```powershell
   wsl --shutdown
   ```

3. **Check Windows updates**
   - Ensure Windows is up to date
   - Install latest WSL updates

### File System Performance

**Best Practices:**

1. **Use Linux filesystem for development**
   ```bash
   # Work in /home/user/ (fast)
   # NOT in /mnt/c/ (slow)
   ```

2. **Access Windows files when needed**
   ```bash
   # Windows C: drive
   cd /mnt/c/Users/YourName/

   # But clone repos to Linux filesystem
   cd ~
   git clone git@github.com:user/repo.git
   ```

---

## Diagnostic Commands

### Quick Environment Check

```bash
# Use the check-dev-env function
check-dev-env

# Or manually:
node --version
npm --version
google-chrome --version
echo $DISPLAY
curl http://localhost:9222/json/version
ssh -T git@github.com
```

### Chrome MCP Debugging

```bash
# Add log file to MCP config
{
  "args": [
    "chrome-devtools-mcp@latest",
    "--browserUrl=http://localhost:9222",
    "--log-file=/tmp/chrome-mcp.log"
  ]
}

# Check the log
tail -f /tmp/chrome-mcp.log
```

### System Information

```bash
# WSL version
wsl --version      # (in PowerShell)

# WSL distribution version
cat /etc/os-release

# Kernel version
uname -r

# Check WSL2
grep -i microsoft /proc/version
```

---

## Getting Help

### Useful Resources

- **Chrome DevTools MCP GitHub**: https://github.com/ChromeDevTools/chrome-devtools-mcp
  - Issue #131 (WSL2): https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131
  - Issue #225 (Headless): https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225

- **Cursor Forum WSL2 Guide**: https://forum.cursor.com/t/complete-guide-setting-up-mcp-tools-with-browser-extensions-in-wsl2/109614

- **WSL Documentation**: https://docs.microsoft.com/en-us/windows/wsl/

- **MCP Documentation**: https://modelcontextprotocol.io/

### Reporting Issues

When reporting issues, include:

1. **System information**
   ```bash
   wsl --version
   cat /etc/os-release
   node --version
   google-chrome --version
   echo $DISPLAY
   ```

2. **Error messages** (full output)

3. **Steps to reproduce**

4. **What you've tried** (from this guide)

---

## Known Limitations

1. **Chrome detection in WSL2** - Use --browserUrl workaround
2. **Headless mode issues** - Use external Chrome instance
3. **Network isolation** - Enable network mirroring on Windows 11
4. **GUI performance** - WSLg may be slower than native Linux
5. **File system speed** - Use Linux filesystem, not /mnt/c/

---

## Quick Fixes Checklist

When something doesn't work:

- [ ] Reload shell: `source ~/.bashrc`
- [ ] Check WSLg: `echo $DISPLAY`
- [ ] Verify Chrome running: `ps aux | grep chrome`
- [ ] Test port: `curl http://localhost:9222/json/version`
- [ ] Check PATH: `echo $PATH`
- [ ] Update WSL: `wsl --update` (PowerShell)
- [ ] Restart WSL: `wsl --shutdown` (PowerShell)
- [ ] Check logs: `tail -f /tmp/chrome-mcp.log`
- [ ] Run diagnostics: `check-dev-env`

---

*Last updated: Based on GitHub Issues #131, #225, and community solutions as of 2025*
