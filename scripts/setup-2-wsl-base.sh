#!/bin/bash

# ============================================
# Step 2: WSL 기본 환경 설정
# ============================================
# WSL 내부 설정(/etc/wsl.conf), Git, bashrc를 구성합니다.
# - Windows PATH 오염 방지 (appendWindowsPath=false)
# - VS Code 경로만 선택적으로 추가
# - Git 전역 설정 (CRLF, filemode 등)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$REPO_DIR/configs"

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
    echo -e "${CYAN}║          ${BOLD}WSL2 AI 개발 환경 설정 - Step 2/3${NC}${CYAN}                 ║${NC}"
    echo -e "${CYAN}║          ${BOLD}WSL 기본 환경 설정${NC}${CYAN}                                ║${NC}"
    echo -e "${CYAN}║                                                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}이 단계에서는 WSL 내부 환경을 구성합니다:${NC}"
    echo -e "  • /etc/wsl.conf (PATH 오염 방지, systemd)"
    echo -e "  • Git 전역 설정 (CRLF, filemode)"
    echo -e "  • ~/.bashrc (VS Code 경로만 추가)"
    echo ""
}

# ============================================
# Windows 사용자명 가져오기
# ============================================
get_windows_username() {
    local win_user
    
    # cmd.exe로 USERNAME 가져오기
    win_user=$(/mnt/c/Windows/System32/cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
    
    if [ -n "$win_user" ]; then
        echo "$win_user"
        return 0
    fi
    
    # 실패 시 현재 WSL 사용자명 반환
    whoami
}

# ============================================
# VS Code 경로 찾기
# ============================================
find_vscode_path() {
    local win_user=$(get_windows_username)
    local possible_paths=(
        "/mnt/c/Users/${win_user}/AppData/Local/Programs/Microsoft VS Code/bin"
        "/mnt/c/Program Files/Microsoft VS Code/bin"
        "/mnt/c/Program Files (x86)/Microsoft VS Code/bin"
    )
    
    for path in "${possible_paths[@]}"; do
        if [ -f "$path/code" ]; then
            echo "$path"
            return 0
        fi
    done
    
    # which로 찾기 시도 (Windows PATH가 아직 연결된 경우)
    local code_path=$(which code 2>/dev/null)
    if [ -n "$code_path" ] && [[ "$code_path" == /mnt/c/* ]]; then
        dirname "$code_path"
        return 0
    fi
    
    return 1
}

# ============================================
# 1. /etc/wsl.conf 설정
# ============================================
setup_wsl_conf() {
    echo ""
    log "=== /etc/wsl.conf 설정 ==="
    echo ""
    
    local WSL_CONF="/etc/wsl.conf"
    local TEMPLATE="$CONFIGS_DIR/wsl.conf"
    
    if [ ! -f "$TEMPLATE" ]; then
        error "템플릿 파일을 찾을 수 없음: $TEMPLATE"
        return 1
    fi
    
    # 기존 파일 확인
    if [ -f "$WSL_CONF" ]; then
        warn "기존 /etc/wsl.conf 발견"
        
        # appendWindowsPath 값 확인
        local current_append=$(grep "appendWindowsPath" "$WSL_CONF" 2>/dev/null | grep -oP '(true|false)' | head -1)
        
        if [ "$current_append" = "false" ]; then
            info "✓ 이미 올바르게 설정됨 (appendWindowsPath=false)"
            return 0
        fi
        
        echo ""
        echo "현재 설정:"
        cat "$WSL_CONF"
        echo ""
        read -p "덮어쓰시겠습니까? (백업됨) [y/N]: " overwrite
        
        if [[ "$overwrite" =~ ^[Yy]$ ]]; then
            sudo cp "$WSL_CONF" "${WSL_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
            log "백업 생성 완료"
        else
            info "기존 설정 유지"
            return 0
        fi
    fi
    
    # 템플릿 복사
    if sudo cp "$TEMPLATE" "$WSL_CONF"; then
        log "✓ /etc/wsl.conf 설정 완료"
        echo ""
        echo "주요 설정:"
        echo "  • systemd: 활성화"
        echo "  • appendWindowsPath: false (PATH 오염 방지)"
        echo "  • interop: enabled (Windows 바이너리 실행 가능)"
        echo ""
        warn "⚠️  이 설정을 적용하려면 WSL을 다시 재시작해야 합니다!"
        info "   (이 스크립트 완료 후 안내됩니다)"
        return 0
    else
        error "/etc/wsl.conf 복사 실패"
        return 1
    fi
}

# ============================================
# 2. Git 전역 설정
# ============================================
setup_git_config() {
    echo ""
    log "=== Git 전역 설정 ==="
    echo ""
    
    if ! command -v git &>/dev/null; then
        warn "Git이 설치되어 있지 않습니다."
        read -p "지금 설치하시겠습니까? [Y/n]: " install_git
        
        if [[ ! "$install_git" =~ ^[Nn]$ ]]; then
            if command -v apt-get &>/dev/null; then
                sudo apt-get update && sudo apt-get install -y git
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y git
            elif command -v yum &>/dev/null; then
                sudo yum install -y git
            else
                error "패키지 관리자를 찾을 수 없습니다."
                return 1
            fi
            log "✓ Git 설치 완료"
        else
            warn "Git 설정을 건너뜁니다."
            return 0
        fi
    fi
    
    echo -e "${BOLD}권장 Git 설정을 적용하시겠습니까?${NC}"
    echo ""
    echo "  • core.autocrlf = input (Windows CRLF → Linux LF 자동 변환)"
    echo "  • core.filemode = false (파일 권한 변경 무시)"
    echo "  • core.eol = lf (줄바꿈 기본값 LF)"
    echo ""
    read -p "적용 [Y/n]: " apply_git
    
    if [[ "$apply_git" =~ ^[Nn]$ ]]; then
        info "Git 설정 건너뜀"
        return 0
    fi
    
    # 설정 적용
    git config --global core.autocrlf input
    git config --global core.filemode false
    git config --global core.eol lf
    
    log "✓ Git 전역 설정 완료"
    echo ""
    echo "현재 설정:"
    git config --global --list | grep -E "^core\." | sed 's/^/  /'
    echo ""
}

# ============================================
# 3. ~/.bashrc 설정
# ============================================
setup_bashrc() {
    echo ""
    log "=== ~/.bashrc 설정 ==="
    echo ""
    
    local BASHRC="$HOME/.bashrc"
    local MARKER="# === WSL2-AI-DEV-SETUP ==="
    
    # 이미 설정된 경우
    if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
        warn "이미 bashrc에 설정이 추가되어 있습니다."
        read -p "다시 추가하시겠습니까? [y/N]: " readd
        if [[ ! "$readd" =~ ^[Yy]$ ]]; then
            info "bashrc 설정 건너뜀"
            return 0
        fi
        # 기존 블록 제거
        sed -i "/$MARKER/,/# === END WSL2-AI-DEV-SETUP ===/d" "$BASHRC"
    fi
    
    # VS Code 경로 찾기
    echo "VS Code 경로를 찾는 중..."
    local VSCODE_PATH=$(find_vscode_path)
    
    if [ -z "$VSCODE_PATH" ]; then
        warn "VS Code 경로를 자동으로 찾을 수 없습니다."
        echo ""
        echo "일반적인 경로:"
        echo "  /mnt/c/Users/<사용자명>/AppData/Local/Programs/Microsoft VS Code/bin"
        echo ""
        read -p "경로를 직접 입력하거나 Enter로 건너뛰기: " manual_path
        
        if [ -n "$manual_path" ] && [ -d "$manual_path" ]; then
            VSCODE_PATH="$manual_path"
        fi
    else
        info "✓ VS Code 경로 발견: $VSCODE_PATH"
    fi
    
    # bashrc 블록 생성
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

BASHRC_BLOCK

    # VS Code 경로 추가
    if [ -n "$VSCODE_PATH" ]; then
        echo "" >> "$BASHRC"
        echo "# VS Code (Windows) - appendWindowsPath=false 대응" >> "$BASHRC"
        echo "export PATH=\"\$PATH:$VSCODE_PATH\"" >> "$BASHRC"
    fi
    
    # 유틸리티 함수 및 별칭 추가
    cat >> "$BASHRC" << 'BASHRC_UTILS'

# 유용한 별칭
alias ll='ls -alF'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'

# WSL2 개발 환경 상태 확인
check-wsl-env() {
    echo "=== WSL2 개발 환경 상태 ==="
    echo ""
    echo "Node.js: $(command -v node &>/dev/null && node --version || echo 'Not installed')"
    echo "npm:     $(command -v npm &>/dev/null && npm --version || echo 'Not installed')"
    echo "Python:  $(command -v python3 &>/dev/null && python3 --version || echo 'Not installed')"
    echo "Git:     $(command -v git &>/dev/null && git --version || echo 'Not installed')"
    echo "VS Code: $(command -v code &>/dev/null && echo 'Available' || echo 'Not available')"
    echo ""
    echo "현재 경로: $(pwd)"
    if echo "$(pwd)" | grep -q "^/mnt/"; then
        echo "⚠️  경고: /mnt/ 경로에서 작업 중 (성능 저하 가능)"
        echo "   권장: Linux 홈(~/)에서 작업하세요."
    fi
}

# === END WSL2-AI-DEV-SETUP ===
BASHRC_UTILS

    log "✓ ~/.bashrc 설정 완료"
    echo ""
    info "추가된 내용:"
    echo "  • Linux 경로 우선순위 설정"
    echo "  • NVM 자동 초기화"
    [ -n "$VSCODE_PATH" ] && echo "  • VS Code 경로: $VSCODE_PATH"
    echo "  • 유틸리티 함수: check-wsl-env"
    echo ""
}

# ============================================
# 메인 로직
# ============================================
main() {
    print_header
    
    # Step 1 완료 확인
    read -p "Step 1을 완료하고 'wsl --shutdown'을 실행했습니까? [y/N]: " step1_done
    if [[ ! "$step1_done" =~ ^[Yy]$ ]]; then
        error "먼저 Step 1을 완료하고 WSL을 재시작해주세요."
        echo ""
        echo "  1. bash scripts/setup-1-windows.sh"
        echo "  2. PowerShell: wsl --shutdown"
        echo "  3. WSL 재시작 후 이 스크립트 다시 실행"
        exit 1
    fi
    
    echo ""
    log "Step 2 시작..."
    
    # 설정 단계 실행
    setup_wsl_conf || error "wsl.conf 설정 실패"
    setup_git_config || error "Git 설정 실패"
    setup_bashrc || error "bashrc 설정 실패"
    
    # 완료 메시지
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    Step 2 완료!                                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}설정된 내용:${NC}"
    echo "  ✓ /etc/wsl.conf (appendWindowsPath=false)"
    echo "  ✓ Git 전역 설정"
    echo "  ✓ ~/.bashrc 환경 변수"
    echo ""
    echo -e "${YELLOW}⚠️  중요: 변경사항을 적용하려면 다시 재시작이 필요합니다!${NC}"
    echo ""
    echo -e "${BOLD}다음 단계:${NC}"
    echo ""
    echo "  ${CYAN}1. 현재 터미널에서 bashrc 적용:${NC}"
    echo "     ${BOLD}source ~/.bashrc${NC}"
    echo ""
    echo "  ${CYAN}2. Windows PowerShell에서 WSL 재시작:${NC}"
    echo "     ${BOLD}wsl --shutdown${NC}"
    echo "     (그 후 WSL 다시 시작)"
    echo ""
    echo "  ${CYAN}3. 환경 확인:${NC}"
    echo "     ${BOLD}check-wsl-env${NC}"
    echo "     ${BOLD}code .${NC}  (VS Code 실행 테스트)"
    echo ""
    echo "  ${CYAN}4. (선택) 개발 도구 설치:${NC}"
    echo "     ${BOLD}bash scripts/setup-3-dev-tools.sh${NC}"
    echo ""
    echo -e "${BLUE}💡 Tip: 'code .' 명령어가 작동하지 않으면 WSL 재시작이 필요합니다.${NC}"
    echo ""
}

# Run
main "$@"
