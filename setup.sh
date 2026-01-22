#!/bin/bash

# ============================================
# WSL2 AI Development Environment Setup
# ============================================
# 3단계 설치 프로세스:
#   Step 1: Windows 호스트 설정 (.wslconfig)
#   Step 2: WSL 기본 환경 (wsl.conf, Git, bashrc)
#   Step 3: 개발 도구 선택 설치 (Node.js, Chrome 등)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    echo -e "${CYAN}║            ${BOLD}WSL2 AI Development Environment Setup${NC}${CYAN}            ║${NC}"
    echo -e "${CYAN}║                                                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Check if running in WSL2
check_wsl2() {
    if ! grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
        error "이 스크립트는 WSL2 환경에서만 실행할 수 있습니다."
        exit 1
    fi
}

# Show main menu
show_menu() {
    echo -e "${BOLD}설치 방법을 선택하세요:${NC}"
    echo ""
    echo "  ${CYAN}[권장] 단계별 설치${NC}"
    echo "  1) Step 1: Windows 호스트 설정 (.wslconfig)"
    echo "  2) Step 2: WSL 기본 환경 설정 (wsl.conf, Git, bashrc)"
    echo "  3) Step 3: 개발 도구 선택 설치 (Node.js, Chrome 등)"
    echo ""
    echo "  ${CYAN}[빠른 설치] 자동화${NC}"
    echo "  0) 전체 자동 설치 (Step 1-3 순차 실행)"
    echo ""
    echo "  ${CYAN}[유틸리티]${NC}"
    echo "  v) 현재 설치 버전 확인"
    echo "  t) 환경 검증 및 문제 진단"
    echo "  h) 도움말"
    echo "  q) 종료"
    echo ""
}

# Step-by-step installation
run_step_1() {
    if [ -f "$SCRIPT_DIR/scripts/setup-1-windows.sh" ]; then
        bash "$SCRIPT_DIR/scripts/setup-1-windows.sh"
    else
        error "setup-1-windows.sh를 찾을 수 없습니다."
        exit 1
    fi
}

run_step_2() {
    if [ -f "$SCRIPT_DIR/scripts/setup-2-wsl-base.sh" ]; then
        bash "$SCRIPT_DIR/scripts/setup-2-wsl-base.sh"
    else
        error "setup-2-wsl-base.sh를 찾을 수 없습니다."
        exit 1
    fi
}

run_step_3() {
    if [ -f "$SCRIPT_DIR/scripts/setup-3-dev-tools.sh" ]; then
        bash "$SCRIPT_DIR/scripts/setup-3-dev-tools.sh"
    else
        error "setup-3-dev-tools.sh를 찾을 수 없습니다."
        exit 1
    fi
}

# Full automatic installation
run_full_install() {
    log "전체 자동 설치를 시작합니다..."
    echo ""
    
    warn "이 모드는 다음 단계를 자동으로 실행합니다:"
    echo "  1. Windows .wslconfig 설정"
    echo "  2. WSL 재시작 필요 (수동)"
    echo "  3. WSL 기본 환경 설정"
    echo "  4. WSL 재시작 필요 (수동)"
    echo "  5. 개발 도구 설치"
    echo ""
    read -p "계속하시겠습니까? [y/N]: " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "취소되었습니다."
        return 0
    fi
    
    # Step 1
    log "=== Step 1/3: Windows 호스트 설정 ==="
    run_step_1
    
    echo ""
    warn "⚠️  지금 PowerShell에서 'wsl --shutdown'을 실행하세요!"
    read -p "WSL을 재시작한 후 Enter를 누르세요..." wait_for_restart
    
    # Step 2
    log "=== Step 2/3: WSL 기본 환경 설정 ==="
    run_step_2
    
    echo ""
    warn "⚠️  다시 PowerShell에서 'wsl --shutdown'을 실행하세요!"
    read -p "WSL을 재시작한 후 Enter를 누르세요..." wait_for_restart
    
    # Reload bashrc
    source ~/.bashrc 2>/dev/null || true
    
    # Step 3
    log "=== Step 3/3: 개발 도구 설치 ==="
    run_step_3
    
    echo ""
    log "전체 설치가 완료되었습니다!"
}

# Check versions
check_versions() {
    if [ -f "$SCRIPT_DIR/scripts/check-versions.sh" ]; then
        bash "$SCRIPT_DIR/scripts/check-versions.sh"
    else
        error "check-versions.sh를 찾을 수 없습니다."
    fi
}

# Validate environment
validate_environment() {
    if [ -f "$SCRIPT_DIR/scripts/validate-environment.sh" ]; then
        bash "$SCRIPT_DIR/scripts/validate-environment.sh"
    else
        error "validate-environment.sh를 찾을 수 없습니다."
    fi
}

# Show help
show_help() {
    echo ""
    echo -e "${BOLD}WSL2 AI 개발 환경 설치 가이드${NC}"
    echo ""
    echo -e "${CYAN}설치 순서:${NC}"
    echo "  1. Step 1: Windows 측 WSL2 가상머신 설정"
    echo "     - 메모리, CPU, 네트워킹 모드 등"
    echo "     - .wslconfig 파일을 Windows 홈에 자동 복사"
    echo "     - 완료 후: PowerShell에서 'wsl --shutdown' 실행"
    echo ""
    echo "  2. Step 2: WSL 내부 기본 환경 구성"
    echo "     - /etc/wsl.conf (appendWindowsPath=false)"
    echo "     - Git 전역 설정 (CRLF, filemode)"
    echo "     - ~/.bashrc (VS Code 경로만 추가)"
    echo "     - 완료 후: 다시 'wsl --shutdown' 실행"
    echo ""
    echo "  3. Step 3: 개발 도구 선택 설치"
    echo "     - Node.js, Chrome, Claude Code, Gemini CLI 등"
    echo "     - 필요한 것만 선택 가능"
    echo ""
    echo -e "${CYAN}주요 특징:${NC}"
    echo "  • Windows PATH 오염 방지 (appendWindowsPath=false)"
    echo "  • VS Code 경로만 선택적으로 추가"
    echo "  • Mirrored Networking (Windows 11 - AI IDE 필수)"
    echo "  • 자동 메모리 회수 (gradual)"
    echo ""
    echo -e "${CYAN}문제 해결:${NC}"
    echo "  • 't' 키로 환경 검증 및 진단"
    echo "  • docs/troubleshooting.md 참고"
    echo ""
    read -p "Enter를 눌러 메뉴로 돌아가기..." wait
}

# Main menu loop
main() {
    print_header
    check_wsl2
    
    log "✓ WSL2 환경 확인 완료"
    echo ""
    
    while true; do
        show_menu
        read -p "선택: " choice
        
        case $choice in
            0)
                run_full_install
                ;;
            1)
                run_step_1
                ;;
            2)
                run_step_2
                ;;
            3)
                run_step_3
                ;;
            v|V)
                check_versions
                ;;
            t|T)
                validate_environment
                ;;
            h|H)
                show_help
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
        read -p "메뉴로 돌아가려면 Enter를 누르세요..." wait_continue
        print_header
    done
}

# Run
main "$@"
