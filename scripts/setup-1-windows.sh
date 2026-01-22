#!/bin/bash

# ============================================
# Step 1: Windows 호스트 설정 (.wslconfig)
# ============================================
# WSL2 가상머신의 메모리, CPU, 네트워킹 등을 설정합니다.
# 이 설정은 WSL 내부가 아닌 Windows 측에서 관리됩니다.

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
    echo -e "${CYAN}║          ${BOLD}WSL2 AI 개발 환경 설정 - Step 1/3${NC}${CYAN}                 ║${NC}"
    echo -e "${CYAN}║          ${BOLD}Windows 호스트 설정 (.wslconfig)${NC}${CYAN}                  ║${NC}"
    echo -e "${CYAN}║                                                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}이 단계에서는 Windows 측 WSL2 가상머신 설정을 구성합니다:${NC}"
    echo -e "  • 메모리 할당 (RAM)"
    echo -e "  • CPU 코어 수"
    echo -e "  • 네트워킹 모드 (mirrored - Win11 전용)"
    echo -e "  • 자동 메모리 회수, Sparse VHD 등"
    echo ""
}

# ============================================
# Windows 사용자 홈 자동 탐지
# ============================================
get_windows_home() {
    local win_home
    
    # 방법 1: cmd.exe로 USERPROFILE 가져오기 (가장 확실)
    win_home=$(/mnt/c/Windows/System32/cmd.exe /C "echo %USERPROFILE%" 2>/dev/null | tr -d '\r\n')
    
    if [ -n "$win_home" ]; then
        # C:\Users\Tiny -> /mnt/c/Users/Tiny
        win_home=$(echo "$win_home" | sed 's/\\/\//g' | sed 's/C:/\/mnt\/c/')
        
        # 경로가 실제로 존재하는지 확인
        if [ -d "$win_home" ]; then
            echo "$win_home"
            return 0
        fi
    fi
    
    # 방법 2: /mnt/c/Users에서 쓰기 권한이 있는 디렉토리 찾기
    for dir in /mnt/c/Users/*/; do
        if [ -w "$dir" ] && [ "$(basename "$dir")" != "Public" ] && [ "$(basename "$dir")" != "Default" ]; then
            echo "${dir%/}"
            return 0
        fi
    done
    
    return 1
}

# ============================================
# Windows 버전 확인
# ============================================
check_windows_version() {
    local win_build=$(/mnt/c/Windows/System32/cmd.exe /C "ver" 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | cut -d. -f3 | tr -d '\r\n')
    
    if [ -z "$win_build" ]; then
        warn "Windows 버전을 자동으로 확인할 수 없습니다."
        return 1
    fi
    
    if [ "$win_build" -ge 22000 ]; then
        echo "11"
        return 0
    else
        echo "10"
        return 0
    fi
}

# ============================================
# 시스템 메모리 확인
# ============================================
get_system_memory() {
    # PowerShell로 메모리 정보 가져오기 시도
    local total_mem_kb=$(/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command "(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB" 2>/dev/null | tr -d '\r\n')
    
    if [ -n "$total_mem_kb" ] && [[ "$total_mem_kb" =~ ^[0-9.]+$ ]]; then
        # 소수점 반올림
        printf "%.0f" "$total_mem_kb"
    else
        # 실패 시 기본값
        echo "16"
    fi
}

# ============================================
# 메인 로직
# ============================================
main() {
    print_header
    
    # Windows 홈 디렉토리 찾기
    log "Windows 사용자 홈 디렉토리 탐색 중..."
    WIN_HOME=$(get_windows_home)
    
    if [ -z "$WIN_HOME" ]; then
        error "Windows 사용자 홈 디렉토리를 찾을 수 없습니다."
        echo ""
        echo "수동으로 입력하시겠습니까?"
        read -p "경로 입력 (예: /mnt/c/Users/사용자명) 또는 Enter로 취소: " manual_home
        
        if [ -n "$manual_home" ] && [ -d "$manual_home" ]; then
            WIN_HOME="$manual_home"
        else
            error "설정을 중단합니다."
            exit 1
        fi
    fi
    
    info "✓ Windows 홈: $WIN_HOME"
    echo ""
    
    # Windows 버전 확인
    log "Windows 버전 확인 중..."
    WIN_VERSION=$(check_windows_version)
    
    if [ "$WIN_VERSION" = "11" ]; then
        info "✓ Windows 11 감지 (고급 기능 사용 가능)"
        HAS_WIN11_FEATURES=true
    elif [ "$WIN_VERSION" = "10" ]; then
        warn "✓ Windows 10 감지 (일부 기능 제한됨)"
        HAS_WIN11_FEATURES=false
    else
        warn "Windows 버전 확인 실패 - Windows 11로 가정합니다."
        read -p "Windows 11을 사용 중이신가요? [Y/n]: " is_win11
        if [[ "$is_win11" =~ ^[Nn]$ ]]; then
            HAS_WIN11_FEATURES=false
        else
            HAS_WIN11_FEATURES=true
        fi
    fi
    echo ""
    
    # 시스템 메모리 확인
    log "시스템 메모리 확인 중..."
    TOTAL_RAM=$(get_system_memory)
    info "✓ 전체 메모리: ${TOTAL_RAM}GB"
    echo ""
    
    # 메모리 할당 선택
    echo -e "${BOLD}WSL2에 할당할 메모리를 선택하세요:${NC}"
    echo ""
    echo "1) 25%  ($(( TOTAL_RAM / 4 ))GB)  - 가벼운 웹 개발"
    echo "2) 50%  ($(( TOTAL_RAM / 2 ))GB)  - 일반 개발 환경 (권장)"
    echo "3) 75%  ($(( TOTAL_RAM * 3 / 4 ))GB)  - AI/ML, 대규모 프로젝트"
    echo "4) 직접 입력"
    echo ""
    read -p "선택 [1-4]: " mem_choice
    
    case $mem_choice in
        1) WSL_MEM=$(( TOTAL_RAM / 4 )) ;;
        2) WSL_MEM=$(( TOTAL_RAM / 2 )) ;;
        3) WSL_MEM=$(( TOTAL_RAM * 3 / 4 )) ;;
        4)
            read -p "메모리 크기 입력 (GB): " WSL_MEM
            if ! [[ "$WSL_MEM" =~ ^[0-9]+$ ]] || [ "$WSL_MEM" -lt 2 ] || [ "$WSL_MEM" -gt "$TOTAL_RAM" ]; then
                error "잘못된 값입니다. 기본값(50%)을 사용합니다."
                WSL_MEM=$(( TOTAL_RAM / 2 ))
            fi
            ;;
        *)
            warn "잘못된 선택. 기본값(50%)을 사용합니다."
            WSL_MEM=$(( TOTAL_RAM / 2 ))
            ;;
    esac
    
    info "✓ WSL2 메모리 할당: ${WSL_MEM}GB"
    echo ""
    
    # CPU 코어 수
    echo -e "${BOLD}CPU 코어 할당:${NC}"
    read -p "사용할 CPU 코어 수 [기본값: 4, Enter로 건너뛰기]: " cpu_cores
    cpu_cores=${cpu_cores:-4}
    
    if ! [[ "$cpu_cores" =~ ^[0-9]+$ ]] || [ "$cpu_cores" -lt 1 ]; then
        warn "잘못된 값입니다. 기본값(4)을 사용합니다."
        cpu_cores=4
    fi
    
    info "✓ CPU 코어: ${cpu_cores}"
    echo ""
    
    # 고급 옵션 (Windows 11 전용)
    ENABLE_MIRRORED=false
    ENABLE_SPARSE=false
    ENABLE_RECLAIM=true  # 기본 활성화
    ENABLE_DNS_TUNNEL=true  # 기본 활성화
    
    if [ "$HAS_WIN11_FEATURES" = true ]; then
        echo -e "${BOLD}고급 옵션 (Windows 11 전용):${NC}"
        echo ""
        
        echo -e "${CYAN}1. Mirrored Networking${NC} (강력 권장)"
        echo "   Windows와 WSL이 동일한 IP를 사용합니다."
        echo "   AI IDE(Cursor, Claude Desktop)의 Browser Subagent 필수 기능"
        read -p "   활성화하시겠습니까? [Y/n]: " enable_mirror
        [[ ! "$enable_mirror" =~ ^[Nn]$ ]] && ENABLE_MIRRORED=true
        echo ""
        
        echo -e "${CYAN}2. Sparse VHD${NC}"
        echo "   WSL에서 파일 삭제 시 Windows 디스크 공간 즉시 반환"
        read -p "   활성화하시겠습니까? [Y/n]: " enable_sparse
        [[ ! "$enable_sparse" =~ ^[Nn]$ ]] && ENABLE_SPARSE=true
        echo ""
    fi
    
    # .wslconfig 파일 생성
    log ".wslconfig 파일 생성 중..."
    
    # configs/generated 디렉토리 생성
    GENERATED_DIR="$CONFIGS_DIR/generated"
    mkdir -p "$GENERATED_DIR"
    
    # 생성할 파일 경로
    GENERATED_WSLCONFIG="$GENERATED_DIR/.wslconfig"
    
    WSLCONFIG_CONTENT="# WSL2 Configuration - Auto-generated by wsl2-ai-dev-setup
# Generated: $(date +'%Y-%m-%d %H:%M:%S')
# 이 파일은 자동 생성되었습니다. configs/wslconfig-windows를 직접 편집하세요.

[wsl2]
memory=${WSL_MEM}GB
processors=${cpu_cores}
swap=4GB
"

    if [ "$ENABLE_MIRRORED" = true ]; then
        WSLCONFIG_CONTENT+="
# Networking (Windows 11 only)
networkingMode=mirrored
dnsTunneling=$( [ "$ENABLE_DNS_TUNNEL" = true ] && echo "true" || echo "false" )
autoProxy=true
localhostForwarding=true
hostAddressLoopback=true
"
    else
        WSLCONFIG_CONTENT+="
# Networking (NAT mode)
localhostForwarding=true
"
    fi

    WSLCONFIG_CONTENT+="
# GUI Applications
guiApplications=true
"

    if [ "$HAS_WIN11_FEATURES" = true ]; then
        WSLCONFIG_CONTENT+="
# Experimental Features (Windows 11 only)
[experimental]
autoMemoryReclaim=$( [ "$ENABLE_RECLAIM" = true ] && echo "gradual" || echo "disabled" )
sparseVhd=$( [ "$ENABLE_SPARSE" = true ] && echo "true" || echo "false" )
"
    fi

    # configs/generated/.wslconfig에 저장
    echo "$WSLCONFIG_CONTENT" > "$GENERATED_WSLCONFIG"
    info "✓ 생성된 파일: $GENERATED_WSLCONFIG"
    
    # configs/generated/.wslconfig에 저장
    echo "$WSLCONFIG_CONTENT" > "$GENERATED_WSLCONFIG"
    info "✓ 생성된 파일: $GENERATED_WSLCONFIG"
    
    echo ""
    echo "생성된 설정 미리보기:"
    echo "----------------------------------------"
    head -20 "$GENERATED_WSLCONFIG"
    echo "----------------------------------------"
    echo ""
    
    # Windows 홈으로 복사
    TARGET_PATH="$WIN_HOME/.wslconfig"
    
    # 기존 파일 백업
    if [ -f "$TARGET_PATH" ]; then
        BACKUP_PATH="$WIN_HOME/.wslconfig.backup.$(date +'%Y%m%d_%H%M%S')"
        warn "기존 .wslconfig 파일 발견. 백업 생성 중..."
        cp "$TARGET_PATH" "$BACKUP_PATH"
        info "✓ 백업: $BACKUP_PATH"
    fi
    
    # 파일 복사
    if cp "$GENERATED_WSLCONFIG" "$TARGET_PATH" 2>/dev/null; then
        log "✓ .wslconfig 파일이 Windows 홈에 복사되었습니다!"
        info "위치: $TARGET_PATH"
    else
        error ".wslconfig 복사 실패"
        echo ""
        echo "수동으로 복사해주세요:"
        echo "  원본: $GENERATED_WSLCONFIG"
        echo "  대상: $TARGET_PATH"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    Step 1 완료!                                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}생성된 파일:${NC}"
    echo "  📄 $GENERATED_WSLCONFIG"
    echo "  📋 $TARGET_PATH (복사 완료)"
    echo ""
    echo -e "${BOLD}설정 내용:${NC}"
    echo "  • 메모리: ${WSL_MEM}GB"
    echo "  • CPU: ${cpu_cores} 코어"
    [ "$ENABLE_MIRRORED" = true ] && echo "  • Mirrored Networking: 활성화"
    [ "$ENABLE_SPARSE" = true ] && echo "  • Sparse VHD: 활성화"
    [ "$ENABLE_RECLAIM" = true ] && echo "  • Auto Memory Reclaim: gradual"
    echo ""
    echo -e "${YELLOW}⚠️  중요: 설정을 적용하려면 WSL을 재시작해야 합니다!${NC}"
    echo ""
    echo -e "${BOLD}다음 단계:${NC}"
    echo ""
    echo "  ${CYAN}1. Windows PowerShell을 열고 다음 명령어 실행:${NC}"
    echo "     ${BOLD}wsl --shutdown${NC}"
    echo ""
    echo "  ${CYAN}2. WSL을 다시 시작하고 다음 스크립트 실행:${NC}"
    echo "     ${BOLD}bash scripts/setup-2-wsl-base.sh${NC}"
    echo ""
    echo -e "${BLUE}💡 Tip: 생성된 파일을 직접 확인하려면:${NC}"
    echo "   cat $GENERATED_WSLCONFIG"
    echo ""
    echo -e "${BLUE}💡 Tip: 'wsl --shutdown'은 모든 WSL 인스턴스를 종료합니다.${NC}"
    echo -e "${BLUE}   변경사항이 적용되려면 완전히 종료 후 재시작이 필수입니다.${NC}"
    echo ""
}

# Run
main "$@"
