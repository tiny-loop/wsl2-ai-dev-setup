#!/bin/bash

# ============================================
# Step 3: 개발 도구 선택 설치
# ============================================
# Node.js, Chrome, Claude Code, Gemini CLI 등을 선택적으로 설치합니다.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log() { echo -e "${GREEN}[SETUP]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Print header
print_header() {
    clear
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                ║${NC}"
    echo -e "${CYAN}║          ${BOLD}WSL2 AI 개발 환경 설정 - Step 3/3${NC}${CYAN}                 ║${NC}"
    echo -e "${CYAN}║          ${BOLD}개발 도구 선택 설치${NC}${CYAN}                                ║${NC}"
    echo -e "${CYAN}║                                                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}필요한 개발 도구를 선택하여 설치합니다.${NC}"
    echo ""
}

# ============================================
# 설치 가능한 도구 목록
# ============================================
show_menu() {
    echo -e "${BOLD}설치할 도구를 선택하세요:${NC}"
    echo ""
    echo "1) Node.js + npm (필수 - 대부분의 AI IDE에 필요)"
    echo "2) Chrome (디버깅용 - MCP Chrome DevTools)"
    echo "3) Claude Code / Cursor CLI"
    echo "4) Gemini CLI"
    echo "5) SSH Key 설정"
    echo ""
    echo "0) 전체 설치 (1~5 모두)"
    echo "s) 현재 설치된 도구 확인"
    echo "q) 종료"
    echo ""
}

# ============================================
# 설치 상태 확인
# ============================================
check_installed_tools() {
    echo ""
    log "=== 현재 설치된 도구 ==="
    echo ""
    
    # Node.js
    if command -v node &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Node.js: $(node --version)"
        echo -e "  ${GREEN}✓${NC} npm:     $(npm --version)"
    else
        echo -e "  ${RED}✗${NC} Node.js: 미설치"
    fi
    
    # Chrome
    if command -v google-chrome &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Chrome:  $(google-chrome --version 2>/dev/null | head -1)"
    else
        echo -e "  ${RED}✗${NC} Chrome:  미설치"
    fi
    
    # Claude Code / Cursor
    if command -v claude &>/dev/null || command -v cursor &>/dev/null; then
        [ command -v claude &>/dev/null ] && echo -e "  ${GREEN}✓${NC} Claude Code: 설치됨"
        [ command -v cursor &>/dev/null ] && echo -e "  ${GREEN}✓${NC} Cursor: 설치됨"
    else
        echo -e "  ${RED}✗${NC} Claude Code / Cursor: 미설치"
    fi
    
    # Gemini
    if command -v gemini &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Gemini CLI: 설치됨"
    else
        echo -e "  ${RED}✗${NC} Gemini CLI: 미설치"
    fi
    
    # SSH Key
    if [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
        echo -e "  ${GREEN}✓${NC} SSH Key: 설정됨"
    else
        echo -e "  ${RED}✗${NC} SSH Key: 미설정"
    fi
    
    # Git
    if command -v git &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Git:     $(git --version)"
    else
        echo -e "  ${RED}✗${NC} Git:     미설치"
    fi
    
    echo ""
}

# ============================================
# 개별 설치 함수들
# ============================================

install_nodejs() {
    echo ""
    log "=== Node.js 설치 ==="
    
    if command -v node &>/dev/null; then
        warn "Node.js가 이미 설치되어 있습니다: $(node --version)"
        read -p "다시 설치하시겠습니까? [y/N]: " reinstall
        [[ ! "$reinstall" =~ ^[Yy]$ ]] && return 0
    fi
    
    if [ -f "$SCRIPT_DIR/install-nodejs.sh" ]; then
        bash "$SCRIPT_DIR/install-nodejs.sh"
    else
        error "install-nodejs.sh를 찾을 수 없습니다."
        return 1
    fi
}

install_chrome() {
    echo ""
    log "=== Chrome 설치 ==="
    
    if command -v google-chrome &>/dev/null; then
        warn "Chrome이 이미 설치되어 있습니다."
        read -p "다시 설치하시겠습니까? [y/N]: " reinstall
        [[ ! "$reinstall" =~ ^[Yy]$ ]] && return 0
    fi
    
    if [ -f "$SCRIPT_DIR/install-chrome.sh" ]; then
        bash "$SCRIPT_DIR/install-chrome.sh"
    else
        error "install-chrome.sh를 찾을 수 없습니다."
        return 1
    fi
}

install_claude() {
    echo ""
    log "=== Claude Code / Cursor 설치 ==="
    
    if [ -f "$SCRIPT_DIR/install-claude-code.sh" ]; then
        bash "$SCRIPT_DIR/install-claude-code.sh"
    else
        error "install-claude-code.sh를 찾을 수 없습니다."
        return 1
    fi
}

install_gemini() {
    echo ""
    log "=== Gemini CLI 설치 ==="
    
    if [ -f "$SCRIPT_DIR/install-gemini.sh" ]; then
        bash "$SCRIPT_DIR/install-gemini.sh"
    else
        error "install-gemini.sh를 찾을 수 없습니다."
        return 1
    fi
}

setup_ssh() {
    echo ""
    log "=== SSH Key 설정 ==="
    
    if [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
        warn "SSH 키가 이미 존재합니다."
        read -p "새로 생성하시겠습니까? [y/N]: " recreate
        [[ ! "$recreate" =~ ^[Yy]$ ]] && return 0
    fi
    
    if [ -f "$SCRIPT_DIR/setup-ssh-key.sh" ]; then
        bash "$SCRIPT_DIR/setup-ssh-key.sh"
    else
        error "setup-ssh-key.sh를 찾을 수 없습니다."
        return 1
    fi
}

# ============================================
# 메인 로직
# ============================================
main() {
    print_header
    
    # 기본 환경 확인
    if ! grep -q "appendWindowsPath=false" /etc/wsl.conf 2>/dev/null; then
        warn "Step 2가 완료되지 않은 것 같습니다."
        read -p "계속 진행하시겠습니까? [y/N]: " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            error "먼저 Step 2를 완료해주세요: bash scripts/setup-2-wsl-base.sh"
            exit 1
        fi
    fi
    
    # 인터랙티브 메뉴
    while true; do
        show_menu
        read -p "선택: " choice
        
        case $choice in
            0)
                log "전체 설치를 시작합니다..."
                install_nodejs
                install_chrome
                install_claude
                install_gemini
                setup_ssh
                break
                ;;
            1)
                install_nodejs
                ;;
            2)
                install_chrome
                ;;
            3)
                install_claude
                ;;
            4)
                install_gemini
                ;;
            5)
                setup_ssh
                ;;
            s|S)
                check_installed_tools
                ;;
            q|Q)
                log "설치를 종료합니다."
                exit 0
                ;;
            *)
                error "잘못된 선택입니다."
                ;;
        esac
        
        echo ""
        read -p "계속 다른 도구를 설치하시겠습니까? [Y/n]: " continue_install
        if [[ "$continue_install" =~ ^[Nn]$ ]]; then
            break
        fi
    done
    
    # 최종 상태 확인
    check_installed_tools
    
    # 완료 메시지
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║               🎉 모든 설정이 완료되었습니다! 🎉                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}다음 단계:${NC}"
    echo ""
    echo "  ${CYAN}1. 환경 검증:${NC}"
    echo "     ${BOLD}bash scripts/validate-environment.sh${NC}"
    echo ""
    echo "  ${CYAN}2. Chrome 디버그 모드 시작 (MCP 사용 시):${NC}"
    echo "     ${BOLD}bash scripts/start-chrome-debug.sh${NC}"
    echo ""
    echo "  ${CYAN}3. 버전 확인:${NC}"
    echo "     ${BOLD}bash scripts/check-versions.sh${NC}"
    echo "     또는 ${BOLD}check-wsl-env${NC}"
    echo ""
    echo "  ${CYAN}4. AI IDE에서 MCP 설정:${NC}"
    echo "     • Claude Desktop / Cursor 등에서"
    echo "     • configs/mcp-config.json 참고"
    echo ""
    echo -e "${BLUE}💡 문제가 발생하면:${NC}"
    echo "   • docs/troubleshooting.md 참고"
    echo "   • bash scripts/validate-environment.sh로 진단"
    echo ""
}

# Run
main "$@"
