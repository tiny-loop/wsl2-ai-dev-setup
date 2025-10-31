# chrome-devtools-mcp Change Log

This document summarizes major version changes of the `chrome-devtools-mcp` package from a WSL2 user perspective.

> **Official Repository**: https://github.com/ChromeDevTools/chrome-devtools-mcp

---

## Table of Contents

- [Current Recommended Version](#current-recommended-version)
- [Key Information for WSL2 Users](#key-information-for-wsl2-users)
- [Version History](#version-history)
  - [v0.9.0 (Latest)](#v090-october-22-2025---current-latest)
  - [v0.8.1](#v081-october-13-2025)
  - [v0.8.0](#v080-october-10-2025)
  - [v0.7.1](#v071-october-10-2025)
  - [v0.7.0](#v070-october-10-2025)
- [Upcoming (v0.10.0)](#upcoming-v0100)
- [WSL2-Related Improvements Summary](#wsl2-related-improvements-summary)

---

## Current Recommended Version

**Latest Stable Version**: `v0.9.0` (October 22, 2025)

**Recommended for WSL2 Users**: `v0.9.0+`
- Enhanced stability
- WebSocket endpoint support
- Official VM/WSL2 documentation included
- Dependency bundling for improved reliability

**Installation**:
```bash
# Using npx (recommended - always latest version)
npx chrome-devtools-mcp@latest

# Or global installation
npm install -g chrome-devtools-mcp@latest
```

---

## Key Information for WSL2 Users

### ⚠️ Important: Actual Status of Issues #131 and #225

**Issue #131: Chrome Not Detected in WSL2**
- Status: ✅ CLOSED (Workaround officially documented)
- **Resolved?**: ❌ Not fundamentally resolved (architectural limitation)
- **Current Status**: `--browserUrl` or `--wsEndpoint` required

**Issue #225: Protocol Error with headless=false**
- Status: ✅ CLOSED (Stability improved in v0.7.0+)
- **Resolved?**: ⚠️ Workaround available via external Chrome
- **Current Status**: Connection stability improved through Puppeteer enhancements

### Official Recommended Methods

Recommended WSL2 usage as of v0.9.0:

**Method 1: browserUrl (Simple, Recommended)**
```bash
# Start Chrome
google-chrome --remote-debugging-port=9222 &

# Configure MCP
npx chrome-devtools-mcp@latest --browserUrl=http://127.0.0.1:9222
```

**Method 2: WebSocket Endpoint (v0.9.0+, Advanced)**
```bash
# Get WebSocket URL
curl http://localhost:9222/json/version

# Configure MCP
npx chrome-devtools-mcp@latest --wsEndpoint=ws://127.0.0.1:9222/devtools/browser/<id>
```

**Method 3: SSH Tunneling (VM-to-Host)**
```bash
# Tunnel from WSL2/VM to Host
ssh -N -L 127.0.0.1:9222:127.0.0.1:9222 user@host-ip

# Then use browserUrl
npx chrome-devtools-mcp@latest --browserUrl=http://127.0.0.1:9222
```

---

## Version History

### v0.9.0 (October 22, 2025) - **Current Latest**

**Major WSL2/VM Features** ⭐

#### 1. WebSocket Endpoint Support (#404)
- New `--wsEndpoint` parameter
- Direct WebSocket connection support
- Custom headers support (authentication tokens, etc.)
- Alternative to `--browserUrl`

**Usage Example**:
```bash
npx chrome-devtools-mcp@latest \
  --wsEndpoint=ws://127.0.0.1:9222/devtools/browser/<id> \
  --wsHeaders='{"Authorization":"Bearer YOUR_TOKEN"}'
```

#### 2. Official VM-to-Host Documentation (#399)
- WSL2/VM scenarios officially acknowledged
- SSH tunneling method documented
- References issues #131, #225, #328, #139

#### 3. Dependency Bundling (#450, #417, #414, #409)
- All dependencies bundled together
- Reduced installation issues
- Resolved npm cache problems

#### 4. Other Major Features

**Tool Category Configuration** (#454)
```bash
# Enable only specific categories
--categoryEmulation=false  # Disable emulation
--categoryPerformance=false  # Disable performance tools
--categoryNetwork=false  # Disable network tools
```

**Enhanced Data Persistence** (#419, #452, #411)
- Store last 3 navigations
- Console message support for previous navigations
- Better history tracking

**Network Request Improvements**
- Stable Request IDs (#375, #382)
- Improved Request/Response body handling (#446)

**Other Enhancements**
- Console message filtering and pagination (#387)
- Verbose snapshots (#388)
- Frame evaluation support (#443)

#### Breaking Changes
None - fully compatible with previous versions

---

### v0.8.1 (October 13, 2025)

**Puppeteer Update** ⭐

#### Puppeteer Updated to v24.24.1 (#370)
- Resolved Issue #322 (puppeteer/puppeteer#14304)
- Resolved Issue #292 (puppeteer/puppeteer#14307, #14306)
- Overall stability improvements
- **WSL2 Impact**: Improved connection stability and error handling

#### Other Improvements
- Enhanced dialog handling (#366, #362)
- Improved navigation error messages (#321)

#### Breaking Changes
None

---

### v0.8.0 (October 10, 2025)

**Chrome Customization**

#### Custom Chrome Arguments Support (#338)
- Pass additional flags to Chrome
- **WSL2 Impact**: Use WSL2-specific Chrome flags

**Usage Example**:
```bash
npx chrome-devtools-mcp@latest \
  --chromeArgs='["--disable-gpu","--no-sandbox"]'
```

#### Breaking Changes
None

---

### v0.7.1 (October 10, 2025)

**Documentation Improvements** 📝

#### Documentation Updates (#335)
- Clarified that console messages and network requests are tracked since last navigation

#### Breaking Changes
None

---

### v0.7.0 (October 10, 2025)

**Major Features**

#### 1. Offline Network Emulation (#326)
- Added offline mode to `emulate_network` command
- Test network disconnection scenarios

#### 2. Request/Response Body Capture (#267)
- Capture HTTP request and response bodies
- Significantly enhanced debugging capabilities

#### 3. Stability Improvements
- Fixed performance trace summary ordering (#334)
- Fixed MCP registry publishing (#313)
- Improved default ProtocolTimeout (#315)

#### Breaking Changes
None

---

## Upcoming (v0.10.0)

**Note**: v0.10.0 is under development and not yet released.

### Planned Features

1. **Enhanced DevTools Integration**
   - Fetch DOM node selected in DevTools Elements panel (#486)
   - Inspect network requests from DevTools UI (#477)

2. **Performance and Control Improvements**
   - Issue filtering and aggregation
   - Page reload with cache control options (#485)
   - Save snapshots to file (#463)

3. **Additional Tools**
   - Press key tool (#458)

---

## WSL2-Related Improvements Summary

### Timeline

| Version | Date | WSL2/VM Related Changes |
|---------|------|------------------------|
| v0.7.0 | 2025-10-10 | Stability improvements (ProtocolTimeout) |
| v0.8.0 | 2025-10-10 | Custom Chrome arguments support |
| v0.8.1 | 2025-10-13 | Puppeteer v24.24.1 stability |
| **v0.9.0** | **2025-10-22** | **WebSocket endpoint**, **Official VM docs**, Dependency bundling |

### Key Improvements

✅ **Major WSL2 Improvements in v0.9.0**:
1. WebSocket endpoint support for diverse connection methods
2. VM-to-host SSH tunneling officially documented
3. Dependency bundling for installation stability
4. Tool category selection for resource optimization

⚠️ **Still Required**:
- Manually start Chrome (auto-detection impossible)
- `--browserUrl` or `--wsEndpoint` required
- WSLg GUI support needed (for headful mode)

---

## Additional Information

### Official Documentation
- **GitHub Repository**: https://github.com/ChromeDevTools/chrome-devtools-mcp
- **Releases**: https://github.com/ChromeDevTools/chrome-devtools-mcp/releases
- **Issues**: https://github.com/ChromeDevTools/chrome-devtools-mcp/issues

### Major WSL2-Related Issues
- **Issue #131**: WSL2 Chrome Detection - https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131
- **Issue #225**: Headless Protocol Error - https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225
- **Issue #328**: VM Environment Support - https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/328
- **Issue #139**: Remote Debugging - https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/139

### Related Documentation in This Repository
- [README.md](../README.md) - Complete installation guide
- [troubleshooting.md](troubleshooting.md) - Troubleshooting
- [mcp-config.json](../../configs/mcp-config.json) - MCP configuration examples

---

**Last Updated**: January 2025
**Author**: WSL2 AI Dev Setup Repository
