#!/bin/bash

# ============================================
# WSL2 최적화 설정 적용 스크립트
# ============================================
# 보고서 권장사항 기반 시스템 설정 자동 적용
# - /etc/wsl.conf 설정
# - Git 전역 설정
# - bashrc 필수 설정 추가
# - 선택적 Windows 도구 PATH 추가

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$REPO_DIR/configs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[SETUP]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Print header
print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          WSL2 최적화 설정 적용 스크립트                         ║${NC}"
    echo -e "${BLUE}║   PATH 오염 방지 / Git 설정 / 성능 최적화                       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================
# 1. /etc/wsl.conf 설정
# ============================================
setup_wsl_conf() {
    log "=== /etc/wsl.conf 설정 ==="
    
    local WSL_CONF="/etc/wsl.conf"
    local TEMPLATE="$CONFIGS_DIR/wsl.conf"
    
    if [ ! -f "$TEMPLATE" ]; then
        error "템플릿 파일을 찾을 수 없음: $TEMPLATE"
        return 1
    fi
    
    if [ -f "$WSL_CONF" ]; then
        warn "기존 $WSL_CONF 발견"
        echo ""
        echo "현재 내용:"
        cat "$WSL_CONF"
        echo ""
        read -p "덮어쓰시겠습니까? (기존 파일은 백업됩니다) [y/N]: " overwrite
        if [[ "$overwrite" =~ ^[Yy]$ ]]; then
            sudo cp "$WSL_CONF" "${WSL_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
            log "백업 생성 완료"
        else
            log "기존 설정 유지"
            return 0
        fi
    fi
    
    sudo cp "$TEMPLATE" "$WSL_CONF"
    log "✓ $WSL_CONF 설정 완료"
    
    echo ""
    warn "⚠️  변경사항을 적용하려면 WSL을 재시작해야 합니다:"
    echo "   PowerShell에서: wsl --shutdown"
    echo ""
}

# ============================================
# 2. Git 전역 설정
# ============================================
setup_git_config() {
    log "=== Git 전역 설정 ==="
    
    if ! command -v git &>/dev/null; then
        warn "Git이 설치되어 있지 않음. 건너뜁니다."
        return 0
    fi
    
    # core.autocrlf
    local CURRENT_AUTOCRLF=$(git config --global core.autocrlf 2>/dev/null || echo "")
    if [ "$CURRENT_AUTOCRLF" != "input" ]; then
        read -p "core.autocrlf를 'input'으로 설정하시겠습니까? (CRLF→LF 변환) [Y/n]: " set_autocrlf
        if [[ ! "$set_autocrlf" =~ ^[Nn]$ ]]; then
            git config --global core.autocrlf input
            log "✓ core.autocrlf = input"
        fi
    else
        log "✓ core.autocrlf = input (이미 설정됨)"
    fi
    
    # core.filemode
    local CURRENT_FILEMODE=$(git config --global core.filemode 2>/dev/null || echo "")
    if [ "$CURRENT_FILEMODE" != "false" ]; then
        read -p "core.filemode를 'false'로 설정하시겠습니까? (권한 변경 무시) [Y/n]: " set_filemode
        if [[ ! "$set_filemode" =~ ^[Nn]$ ]]; then
            git config --global core.filemode false
            log "✓ core.filemode = false"
        fi
    else
        log "✓ core.filemode = false (이미 설정됨)"
    fi
    
    # core.eol
    local CURRENT_EOL=$(git config --global core.eol 2>/dev/null || echo "")
    if [ "$CURRENT_EOL" != "lf" ]; then
        read -p "core.eol을 'lf'로 설정하시겠습니까? (줄바꿈 기본값 LF) [Y/n]: " set_eol
        if [[ ! "$set_eol" =~ ^[Nn]$ ]]; then
            git config --global core.eol lf
            log "✓ core.eol = lf"
        fi
    else
        log "✓ core.eol = lf (이미 설정됨)"
    fi
    
    echo ""
    log "현재 Git 전역 설정:"
    git config --global --list | grep -E "^core\." | sed 's/^/  /'
    echo ""
}

# ============================================
# 3. bashrc 추가 설정
# ============================================
setup_bashrc_additions() {
    log "=== ~/.bashrc 추가 설정 ==="
    
    local BASHRC="$HOME/.bashrc"
    local MARKER="# === WSL2-AI-DEV-SETUP ==="
    
    # Check if already configured
    if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
        log "이미 bashrc에 설정이 추가되어 있음"
        read -p "다시 추가하시겠습니까? [y/N]: " readd
        if [[ ! "$readd" =~ ^[Yy]$ ]]; then
            return 0
        fi
        # Remove existing block
        sed -i "/$MARKER/,/# === END WSL2-AI-DEV-SETUP ===/d" "$BASHRC"
    fi
    
    # Add configuration block
    cat >> "$BASHRC" << 'BASHRC_BLOCK'

# === WSL2-AI-DEV-SETUP ===
# WSL2 환경 최적화 설정 (자동 생성됨)

# PATH 우선순위 보장: Linux 경로가 항상 앞에 오도록
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

# NVM 초기화 (설치된 경우)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# WSLg 디스플레이 설정
export DISPLAY="${DISPLAY:-:0}"

# 선택적 Windows 도구 경로 추가 (appendWindowsPath=false 사용 시)
# 필요한 Windows 도구만 명시적으로 추가
add_windows_tool() {
    local tool_path="$1"
    if [ -f "$tool_path" ] || [ -d "$tool_path" ]; then
        export PATH="$PATH:$(dirname "$tool_path")"
    fi
}

# VS Code (Windows)
add_windows_tool "/mnt/c/Users/$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')/AppData/Local/Programs/Microsoft VS Code/bin/code"

# 유용한 별칭
alias ll='ls -alF'
alias la='ls -A'
alias chrome-debug='bash ~/my_work/wsl2-ai-dev-setup/scripts/start-chrome-debug.sh 2>/dev/null || bash ~/my_work/dev_setup/scripts/start-chrome-debug.sh 2>/dev/null'
alias validate-env='bash ~/my_work/wsl2-ai-dev-setup/scripts/validate-environment.sh 2>/dev/null || bash ~/my_work/dev_setup/scripts/validate-environment.sh 2>/dev/null'

# 개발 환경 상태 확인 함수
check-wsl-env() {
    echo "=== WSL2 개발 환경 상태 ==="
    echo ""
    echo "Node.js: $(command -v node &>/dev/null && node --version || echo 'Not installed')"
    echo "npm:     $(command -v npm &>/dev/null && npm --version || echo 'Not installed')"
    echo "Python:  $(command -v python3 &>/dev/null && python3 --version || echo 'Not installed')"
    echo "Git:     $(command -v git &>/dev/null && git --version || echo 'Not installed')"
    echo "Chrome:  $(command -v google-chrome &>/dev/null && echo 'Installed' || echo 'Not installed')"
    echo ""
    echo "DISPLAY: ${DISPLAY:-'(not set)'}"
    echo "현재 경로: $(pwd)"
    echo ""
    if echo "$(pwd)" | grep -q "^/mnt/"; then
        echo "⚠️  경고: /mnt/ 경로에서 작업 중 (성능 저하 가능)"
    fi
}

# === END WSL2-AI-DEV-SETUP ===
BASHRC_BLOCK

    log "✓ ~/.bashrc에 설정 추가 완료"
    info "변경사항 적용: source ~/.bashrc"
    echo ""
}

# ============================================
# 4. Windows 설정 안내
# ============================================
print_windows_instructions() {
    log "=== Windows 측 설정 안내 ==="
    echo ""
    echo -e "${YELLOW}다음 파일을 Windows에 복사해야 합니다:${NC}"
    echo ""
    echo "1. .wslconfig 파일:"
    echo "   원본: $CONFIGS_DIR/wslconfig-windows"
    echo "   대상: C:\\Users\\<사용자명>\\.wslconfig"
    echo ""
    echo "   PowerShell에서 복사:"
    echo "   \$ cp \\\\wsl.localhost\\Ubuntu\\$(echo $CONFIGS_DIR | sed 's|^/|/|')\\wslconfig-windows \$env:USERPROFILE\\.wslconfig"
    echo ""
    echo "2. VS Code 설정 (선택사항):"
    echo "   원본: $CONFIGS_DIR/vscode-settings.json"
    echo "   대상: 프로젝트의 .vscode/settings.json에 병합"
    echo ""
    echo "3. 설정 적용:"
    echo "   PowerShell에서: wsl --shutdown"
    echo "   그 후 WSL 다시 시작"
    echo ""
}

# ============================================
# 5. 검증 실행
# ============================================
run_validation() {
    log "=== 환경 검증 실행 ==="
    
    local VALIDATOR="$SCRIPT_DIR/validate-environment.sh"
    
    if [ -f "$VALIDATOR" ]; then
        read -p "환경 검증을 실행하시겠습니까? [Y/n]: " run_val
        if [[ ! "$run_val" =~ ^[Nn]$ ]]; then
            bash "$VALIDATOR"
        fi
    else
        warn "검증 스크립트를 찾을 수 없음: $VALIDATOR"
    fi
}

# ============================================
# Main Menu
# ============================================
main_menu() {
    print_header
    
    echo "설정할 항목을 선택하세요:"
    echo ""
    echo "1) 전체 설정 (권장)"
    echo "2) /etc/wsl.conf만 설정"
    echo "3) Git 전역 설정만"
    echo "4) ~/.bashrc 추가만"
    echo "5) 환경 검증만 실행"
    echo "6) Windows 설정 안내 보기"
    echo "0) 취소"
    echo ""
    read -p "선택 [1-6, 0]: " choice
    
    case $choice in
        1)
            setup_wsl_conf
            setup_git_config
            setup_bashrc_additions
            print_windows_instructions
            run_validation
            ;;
        2)
            setup_wsl_conf
            ;;
        3)
            setup_git_config
            ;;
        4)
            setup_bashrc_additions
            ;;
        5)
            bash "$SCRIPT_DIR/validate-environment.sh"
            ;;
        6)
            print_windows_instructions
            ;;
        0)
            log "취소됨"
            exit 0
            ;;
        *)
            error "잘못된 선택"
            exit 1
            ;;
    esac
    
    echo ""
    log "=== 설정 완료 ==="
    echo ""
    echo "다음 단계:"
    echo "1. source ~/.bashrc  (또는 터미널 재시작)"
    echo "2. PowerShell에서: wsl --shutdown"
    echo "3. WSL 다시 시작"
    echo "4. validate-env 명령으로 설정 확인"
    echo ""
}

# Run
main_menu "$@"
