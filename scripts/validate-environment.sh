#!/bin/bash

# ============================================
# WSL2 환경 검증 스크립트
# ============================================
# 보고서 권장사항 기반 환경 설정 검증
# - PATH 오염 감지
# - 파일 시스템 위치 확인
# - Git 설정 검증
# - 네트워크 설정 확인
# - 성능 관련 설정 검증

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions if available
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    source "$SCRIPT_DIR/common.sh"
else
    # Fallback color definitions
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
fi

# Counters
PASS=0
WARN=0
FAIL=0

# Print header
print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     WSL2 환경 검증 스크립트 (Best Practices Validator)        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Result functions
pass() {
    echo -e "  ${GREEN}✓ PASS${NC}: $1"
    ((PASS++))
}

warn() {
    echo -e "  ${YELLOW}⚠ WARN${NC}: $1"
    ((WARN++))
}

fail() {
    echo -e "  ${RED}✗ FAIL${NC}: $1"
    ((FAIL++))
}

info() {
    echo -e "  ${BLUE}ℹ INFO${NC}: $1"
}

section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ============================================
# 1. WSL2 환경 확인
# ============================================
check_wsl2_environment() {
    section "1. WSL2 환경 확인"
    
    # Check if running in WSL2
    if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
        if grep -qi "WSL2" /proc/version 2>/dev/null || [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
            pass "WSL2 환경에서 실행 중"
        else
            warn "WSL1으로 보임 (WSL2 권장)"
        fi
    else
        fail "WSL 환경이 아님"
    fi
    
    # Check kernel version
    KERNEL=$(uname -r)
    info "커널 버전: $KERNEL"
}

# ============================================
# 2. PATH 오염 검사
# ============================================
check_path_pollution() {
    section "2. PATH 오염 검사 (Windows 바이너리 충돌)"
    
    # Check for Windows paths in PATH
    WIN_PATH_COUNT=$(echo "$PATH" | tr ':' '\n' | grep "/mnt/c" | grep -v "Microsoft VS Code" | wc -l)
    
    if [ "$WIN_PATH_COUNT" -gt 5 ]; then
        fail "Windows 경로가 지나치게 많이 ($WIN_PATH_COUNT 개) 포함됨. (appendWindowsPath=false 권장)"
        info "해결: 'setup.sh'에서 9번 최적화 실행"
    elif [ "$WIN_PATH_COUNT" -gt 0 ]; then
        warn "일부 Windows 경로가 남아 있음 ($WIN_PATH_COUNT 개)."
    else
        pass "PATH 오염 없음 (격리된 환경)"
    fi

    # Check for VS Code
    if command -v code >/dev/null 2>&1; then
        pass "VS Code ('code') 명령어 사용 가능"
    else
        warn "VS Code 명령어를 찾을 수 없음"
    fi
}
        
        # Check for specific problematic binaries
        if command -v node &>/dev/null; then
            NODE_PATH=$(which node)
            if echo "$NODE_PATH" | grep -q "/mnt/c"; then
                fail "node가 Windows 경로를 가리킴: $NODE_PATH"
                info "해결: appendWindowsPath=false 설정 후 Linux Node.js 설치"
            else
                pass "node가 Linux 경로 사용: $NODE_PATH"
            fi
        fi
        
        if command -v npm &>/dev/null; then
            NPM_PATH=$(which npm)
            if echo "$NPM_PATH" | grep -q "/mnt/c"; then
                fail "npm이 Windows 경로를 가리킴: $NPM_PATH"
            else
                pass "npm이 Linux 경로 사용: $NPM_PATH"
            fi
        fi
        
        if command -v python &>/dev/null || command -v python3 &>/dev/null; then
            PYTHON_PATH=$(which python3 2>/dev/null || which python 2>/dev/null)
            if echo "$PYTHON_PATH" | grep -q "/mnt/c"; then
                warn "python이 Windows 경로를 가리킴: $PYTHON_PATH"
            else
                pass "python이 Linux 경로 사용: $PYTHON_PATH"
            fi
        fi
    else
        pass "Windows 경로가 PATH에 없음 (권장 설정)"
    fi
    
    # Check wsl.conf for appendWindowsPath
    if [ -f /etc/wsl.conf ]; then
        if grep -qi "appendWindowsPath.*=.*false" /etc/wsl.conf; then
            pass "/etc/wsl.conf에 appendWindowsPath=false 설정됨"
        else
            warn "/etc/wsl.conf에 appendWindowsPath=false 설정 권장"
            info "설정 방법: sudo cp configs/wsl.conf /etc/wsl.conf"
        fi
    else
        warn "/etc/wsl.conf 파일 없음"
        info "생성 권장: sudo cp configs/wsl.conf /etc/wsl.conf"
    fi
}

# ============================================
# 3. 파일 시스템 위치 검사
# ============================================
check_filesystem_location() {
    section "3. 파일 시스템 위치 검사 (성능)"
    
    CURRENT_DIR=$(pwd)
    
    if echo "$CURRENT_DIR" | grep -q "^/mnt/"; then
        fail "현재 디렉토리가 Windows 파일시스템에 위치: $CURRENT_DIR"
        info "성능 저하: /mnt/c는 네이티브 Linux FS 대비 10~50배 느림"
        info "권장: 프로젝트를 ~/my_work/ 등 Linux 경로로 이동"
    else
        pass "현재 디렉토리가 Linux 파일시스템에 위치: $CURRENT_DIR"
    fi
    
    # Check if common project directories are in /mnt/
    if [ -d "/mnt/c/Users" ]; then
        info "/mnt/c/Users가 접근 가능 (Windows 파일 접근용)"
    fi
    
    # Check home directory
    if [ -d "$HOME" ] && ! echo "$HOME" | grep -q "^/mnt/"; then
        pass "홈 디렉토리가 Linux 파일시스템: $HOME"
    fi
}

# ============================================
# 4. Git 설정 검사
# ============================================
check_git_settings() {
    section "4. Git 설정 검사 (CRLF, filemode)"
    
    if ! command -v git &>/dev/null; then
        warn "Git이 설치되어 있지 않음"
        return
    fi
    
    # Check core.autocrlf
    AUTOCRLF=$(git config --global core.autocrlf 2>/dev/null || echo "not set")
    case "$AUTOCRLF" in
        input|false)
            pass "core.autocrlf = $AUTOCRLF (권장)"
            ;;
        true)
            warn "core.autocrlf = true (CRLF 변환 활성화)"
            info "WSL2에서는 'input' 또는 'false' 권장"
            info "설정: git config --global core.autocrlf input"
            ;;
        *)
            warn "core.autocrlf 미설정"
            info "권장: git config --global core.autocrlf input"
            ;;
    esac
    
    # Check core.filemode
    FILEMODE=$(git config --global core.filemode 2>/dev/null || echo "not set")
    case "$FILEMODE" in
        false)
            pass "core.filemode = false (권장)"
            ;;
        true|"not set")
            warn "core.filemode가 true 또는 미설정"
            info "Windows FS 사용 시 권한 변경 오탐지 방지를 위해 false 권장"
            info "설정: git config --global core.filemode false"
            ;;
    esac
    
    # Check credential helper
    CREDENTIAL=$(git config --global credential.helper 2>/dev/null || echo "not set")
    if [ "$CREDENTIAL" != "not set" ]; then
        pass "credential.helper 설정됨: $CREDENTIAL"
    else
        info "credential.helper 미설정 (선택사항)"
    fi
}

# ============================================
# 5. 네트워크 설정 검사
# ============================================
check_network_settings() {
    section "5. 네트워크 설정 검사"
    
    # Check localhost connectivity
    if curl -s --connect-timeout 2 http://localhost:9222/json/version &>/dev/null; then
        pass "Chrome 디버깅 포트(9222) 접근 가능"
    else
        info "Chrome 디버깅 포트(9222) 미응답 (Chrome이 실행 중이 아닐 수 있음)"
    fi
    
    # Check for Hyper-V reserved ports (common issue)
    if command -v ss &>/dev/null; then
        # Check if common dev ports are available
        for PORT in 3000 8080 8000 5173; do
            if ss -tuln | grep -q ":$PORT "; then
                info "포트 $PORT 사용 중"
            fi
        done
    fi
    
    # Note about networkingMode
    info "네트워크 미러링 모드 확인은 Windows에서 .wslconfig 확인 필요"
    info "Antigravity 사용 시 networkingMode=mirrored 권장"
}

# ============================================
# 6. 메모리/리소스 설정 검사
# ============================================
check_resource_settings() {
    section "6. 메모리/리소스 설정"
    
    # Check available memory
    TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
    USED_MEM=$(free -g | awk '/^Mem:/{print $3}')
    
    info "메모리: ${USED_MEM}GB / ${TOTAL_MEM}GB 사용 중"
    
    if [ "$TOTAL_MEM" -lt 4 ]; then
        warn "할당된 메모리가 4GB 미만 (AI IDE 사용 시 부족할 수 있음)"
        info ".wslconfig에서 memory=8GB 이상 권장"
    else
        pass "메모리 할당 적절: ${TOTAL_MEM}GB"
    fi
    
    # Check CPU
    CPU_COUNT=$(nproc)
    info "CPU 코어: $CPU_COUNT"
}

# ============================================
# 7. 개발 도구 설치 상태
# ============================================
check_dev_tools() {
    section "7. 개발 도구 설치 상태"
    
    # Node.js
    if command -v node &>/dev/null; then
        NODE_VER=$(node --version)
        pass "Node.js: $NODE_VER"
    else
        warn "Node.js 미설치"
    fi
    
    # npm
    if command -v npm &>/dev/null; then
        NPM_VER=$(npm --version)
        pass "npm: $NPM_VER"
    else
        warn "npm 미설치"
    fi
    
    # NVM
    if [ -d "$HOME/.nvm" ]; then
        pass "NVM 설치됨"
    else
        warn "NVM 미설치 (Node 버전 관리 권장)"
    fi
    
    # Chrome
    if command -v google-chrome &>/dev/null; then
        CHROME_VER=$(google-chrome --version 2>/dev/null || echo "unknown")
        pass "Chrome: $CHROME_VER"
    else
        info "Chrome 미설치 (MCP 사용 시 필요)"
    fi
    
    # Claude Code
    if command -v claude &>/dev/null; then
        pass "Claude Code CLI 설치됨"
    else
        info "Claude Code CLI 미설치"
    fi
    
    # Gemini CLI
    if command -v gemini &>/dev/null; then
        pass "Gemini CLI 설치됨"
    else
        info "Gemini CLI 미설치"
    fi
}

# ============================================
# 8. SSH 설정 검사
# ============================================
check_ssh_settings() {
    section "8. SSH 설정 검사"
    
    # Check for SSH keys
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
        # Check permissions
        PERMS=$(stat -c %a "$HOME/.ssh/id_ed25519" 2>/dev/null || echo "unknown")
        if [ "$PERMS" = "600" ]; then
            pass "SSH 키 (ED25519) 존재, 권한 올바름 (600)"
        else
            warn "SSH 키 권한: $PERMS (600 권장)"
            info "수정: chmod 600 ~/.ssh/id_ed25519"
        fi
    elif [ -f "$HOME/.ssh/id_rsa" ]; then
        PERMS=$(stat -c %a "$HOME/.ssh/id_rsa" 2>/dev/null || echo "unknown")
        if [ "$PERMS" = "600" ]; then
            pass "SSH 키 (RSA) 존재, 권한 올바름 (600)"
        else
            warn "SSH 키 권한: $PERMS (600 권장)"
        fi
    else
        info "SSH 키 미생성"
    fi
    
    # Check .ssh directory permissions
    if [ -d "$HOME/.ssh" ]; then
        SSH_DIR_PERMS=$(stat -c %a "$HOME/.ssh" 2>/dev/null || echo "unknown")
        if [ "$SSH_DIR_PERMS" = "700" ]; then
            pass ".ssh 디렉토리 권한 올바름 (700)"
        else
            warn ".ssh 디렉토리 권한: $SSH_DIR_PERMS (700 권장)"
        fi
    fi
}

# ============================================
# 9. WSLg (GUI) 설정 검사
# ============================================
check_wslg() {
    section "9. WSLg (GUI 지원) 검사"
    
    if [ -n "$DISPLAY" ]; then
        pass "DISPLAY 설정됨: $DISPLAY"
    else
        warn "DISPLAY 미설정 (GUI 앱 실행 불가)"
        info "설정: export DISPLAY=:0"
    fi
    
    if [ -n "$WAYLAND_DISPLAY" ]; then
        pass "WAYLAND_DISPLAY 설정됨: $WAYLAND_DISPLAY"
    else
        info "WAYLAND_DISPLAY 미설정 (X11 모드 사용 중일 수 있음)"
    fi
}

# ============================================
# 결과 요약
# ============================================
print_summary() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                         검사 결과 요약                          ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GREEN}✓ PASS${NC}: $PASS"
    echo -e "  ${YELLOW}⚠ WARN${NC}: $WARN"
    echo -e "  ${RED}✗ FAIL${NC}: $FAIL"
    echo ""
    
    if [ $FAIL -gt 0 ]; then
        echo -e "${RED}❌ 실패 항목이 있습니다. 위의 권장사항을 확인하세요.${NC}"
    elif [ $WARN -gt 0 ]; then
        echo -e "${YELLOW}⚠️  경고 항목이 있습니다. 개선을 권장합니다.${NC}"
    else
        echo -e "${GREEN}✅ 모든 검사를 통과했습니다!${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}권장 설정 파일:${NC}"
    echo "  - configs/wsl.conf         → /etc/wsl.conf"
    echo "  - configs/wslconfig-windows → %USERPROFILE%\\.wslconfig"
    echo "  - configs/vscode-settings.json → .vscode/settings.json"
    echo ""
}

# ============================================
# Main
# ============================================
main() {
    print_header
    
    check_wsl2_environment
    check_path_pollution
    check_filesystem_location
    check_git_settings
    check_network_settings
    check_resource_settings
    check_dev_tools
    check_ssh_settings
    check_wslg
    
    print_summary
}

main "$@"
