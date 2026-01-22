#!/bin/bash

# scripts/interactive-setup.sh
# WSL2 AI Development Environment Interactive Setup Script

set -e

# Load common functions if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "${SCRIPT_DIR}/common.sh" ] && source "${SCRIPT_DIR}/common.sh"

echo -e "\033[1;34m[WSL2 AI Dev Setup] 인터랙티브 설정 시작...\033[0m"

# 1. Host OS 정보 수집
echo -e "\n\033[1;33mStep 1: 시스템 정보 확인 중...\033[0m"

get_win_info() {
    # PowerShell을 통해 정보 수집 시도
    # TotalVisibleMemorySize는 KB 단위
    local win_mem_kb=$(powershell.exe -Command "(Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize" 2>/dev/null | tr -d '\r')
    local win_ver=$(powershell.exe -Command "[Environment]::OSVersion.Version.Build" 2>/dev/null | tr -d '\r')
    
    if [[ -n "$win_mem_kb" && "$win_mem_kb" =~ ^[0-9]+$ ]]; then
        TOTAL_RAM_GB=$(( win_mem_kb / 1024 / 1024 ))
        echo "검색된 RAM: ${TOTAL_RAM_GB}GB"
    else
        echo "PowerShell을 통한 메모리 정보 수집 실패."
        read -p "전체 시스템 RAM 용량을 입력하세요 (GB 단위, 예: 16, 32, 64): " TOTAL_RAM_GB
    fi

    if [[ -n "$win_ver" && "$win_ver" =~ ^[0-9]+$ ]]; then
        WIN_BUILD=$win_ver
        if [ "$WIN_BUILD" -ge 22000 ]; then
            IS_WIN11=true
            echo "검색된 OS: Windows 11 (Build $WIN_BUILD)"
        else
            IS_WIN11=false
            echo "검색된 OS: Windows 10 (Build $WIN_BUILD)"
        fi
    else
        echo "OS 버전 확인 실패."
        read -p "사용 중인 OS가 Windows 11입니까? (y/n): " is_win11_input
        [[ "$is_win11_input" =~ ^[Yy]$ ]] && IS_WIN11=true || IS_WIN11=false
    fi
}

get_win_info

# 2. 메모리 기반 설정 계산
echo -e "\n\033[1;33mStep 2: 자원 할당 설정\033[0m"
echo "시스템의 전체 메모리는 ${TOTAL_RAM_GB}GB 입니다."
echo "원하는 할당 비율을 선택하세요:"
echo "1) 25% (${TOTAL_RAM_GB/4}GB) - 웹 개발 및 가벼운 용도"
echo "2) 50% ($((TOTAL_RAM_GB/2))GB) - 일반적인 AI/데이터 과학 개발 (추천)"
echo "3) 75% ($((TOTAL_RAM_GB*3/4))GB) - 대규모 모델 학습 및 로컬 LLM 구동"
echo "4) 직접 입력"

read -p "선택 (1-4): " MEM_CHOICE

case $MEM_CHOICE in
    1) WSL_MEM=$(( TOTAL_RAM_GB / 4 )) ;;
    2) WSL_MEM=$(( TOTAL_RAM_GB / 2 )) ;;
    3) WSL_MEM=$(( TOTAL_RAM_GB * 3 / 4 )) ;;
    4) read -p "메모리 크기 입력 (GB): " WSL_MEM ;;
    *) WSL_MEM=$(( TOTAL_RAM_GB / 2 )); echo "기본값(50%)을 사용합니다." ;;
esac

echo "설정된 메모리: ${WSL_MEM}GB"

# 3. 브라우저 및 IDE 연동 (VSCode Path 처리)
echo -e "\n\033[1;33mStep 3: Windows PATH 격리 및 VS Code 복구\033[0m"
echo "기본적으로 Windows의 PATH는 WSL과 분리됩니다 (성능 및 충돌 방지)."
echo "하지만 'code .' 명령어를 사용하기 위해 VS Code의 경로만 추출하여 추가합니다."

# PowerShell을 통해 VS Code 위치 찾기 시도
# (Windows PATH가 아직 연결되어 있다는 전제 하에)
VSCODE_BIN_PATH=$(which code 2>/dev/null | grep "/mnt/c" | head -n 1)

if [ -z "$VSCODE_BIN_PATH" ]; then
    # which로 못찾으면 powershell로 시도
    VSCODE_BIN_PATH=$(powershell.exe -Command "(Get-Command code).Source" 2>/dev/null | sed 's/\\/\//g' | sed 's/C:/\/mnt\/c/I' | xargs dirname 2>/dev/null | tr -d '\r')
fi

if [ -z "$VSCODE_BIN_PATH" ]; then
    echo "VS Code 경로를 자동으로 찾지 못했습니다."
    # 일반적인 경로 추측
    WIN_USER=$(powershell.exe -Command "echo \$env:USERNAME" 2>/dev/null | tr -d '\r')
    if [ -n "$WIN_USER" ]; then
        POTENTIAL_PATH="/mnt/c/Users/${WIN_USER}/AppData/Local/Programs/Microsoft VS Code/bin"
        if [ -d "$POTENTIAL_PATH" ]; then
            VSCODE_BIN_PATH="$POTENTIAL_PATH"
            echo "추측된 VS Code 경로: $VSCODE_BIN_PATH"
        fi
    fi
fi

if [ -z "$VSCODE_BIN_PATH" ]; then
    read -p "VS Code의 bin 폴더 경로를 입력하세요 (예: /mnt/c/.../bin, 건너뛰려면 Enter): " VSCODE_BIN_PATH
fi

# 4. 고급 옵션 메뉴
echo -e "\n\033[1;33mStep 4: 고급 옵션 설정\033[0m"
echo "다음 중 활성화할 기능을 선택하세요 (예: 1,3)"
echo "------------------------------------------------"
echo "1) Mirrored Networking (Win 11 전용): Windows와 WSL의 IP를 동일하게 사용 (강력 추천)"
echo "2) Sparse VHD (Win 11 전용): WSL에서 파일을 지우면 Windows 디스크 공간을 즉시 반환"
echo "3) Auto Memory Reclaim: 리눅스 캐시 메모리를 자동으로 윈도우에 반환 (gradual)"
echo "4) DNS Tunneling: VPN 사용 시 발생할 수 있는 네트워크 연결 이슈 해결"
echo "5) 설정 완료"
echo "------------------------------------------------"

OPT_MIRRORED="n"
OPT_SPARSE="n"
OPT_RECLAIM="n"
OPT_DNS="n"

read -p "번호를 입력하세요: " ADV_INPUT

if [[ $ADV_INPUT == *"1"* && "$IS_WIN11" = true ]]; then OPT_MIRRORED="y"; fi
if [[ $ADV_INPUT == *"2"* && "$IS_WIN11" = true ]]; then OPT_SPARSE="y"; fi
if [[ $ADV_INPUT == *"3"* ]]; then OPT_RECLAIM="y"; fi
if [[ $ADV_INPUT == *"4"* ]]; then OPT_DNS="y"; fi

# 5. 설정 파일 생성 로직
echo -e "\n\033[1;33mStep 5: 설정 파일 생성 중...\033[0m"

# .wslconfig 생성 (Windows 사이드)
WSLCONFIG_OUT="configs/generated/.wslconfig"
mkdir -p configs/generated

cat <<EOF > "$WSLCONFIG_OUT"
[wsl2]
memory=${WSL_MEM}GB
EOF

[[ "$OPT_MIRRORED" == "y" ]] && echo "networkingMode=mirrored" >> "$WSLCONFIG_OUT"
[[ "$OPT_SPARSE" == "y" ]] && echo "sparseVhd=true" >> "$WSLCONFIG_OUT"
[[ "$OPT_RECLAIM" == "y" ]] && echo "autoMemoryReclaim=gradual" >> "$WSLCONFIG_OUT"
[[ "$OPT_DNS" == "y" ]] && echo "dnsTunneling=true" >> "$WSLCONFIG_OUT"

# wsl.conf 생성 (Linux 사이드)
WSL_CONF_OUT="configs/generated/wsl.conf"
cat <<EOF > "$WSL_CONF_OUT"
[boot]
systemd=true

[interop]
enabled=true
appendWindowsPath=false

[automount]
enabled=true
options="metadata,uid=1000,gid=1000,umask=22,fmask=11"
EOF

# bashrc 연동용 snippet 생성
BASHRC_SNIPPET="configs/generated/bashrc-vscode"
if [ -n "$VSCODE_BIN_PATH" ]; then
    echo "export PATH=\"\$PATH:$VSCODE_BIN_PATH\"" > "$BASHRC_SNIPPET"
else
    touch "$BASHRC_SNIPPET"
fi

echo -e "\n\033[1;32m설정 파일이 생성이 완료되었습니다!\033[0m"
echo "생성된 파일 위치:"
echo "- $WSLCONFIG_OUT (Windows %USERPROFILE% 폴더로 이동 필요)"
echo "- $WSL_CONF_OUT (/etc/wsl.conf 로 복사 필요)"
echo "- $BASHRC_SNIPPET (~/.bashrc 에 추가 필요)"

echo -e "\n\033[1;33mStep 6: 설정을 즉시 적용하시겠습니까?\033[0m"
echo "(주의: /etc/wsl.conf 를 변경하려면 sudo 권한이 필요하며, .bashrc가 업데이트됩니다.)"
read -p "적용하시겠습니까? (y/n): " APPLY_NOW

if [[ "$APPLY_NOW" =~ ^[Yy]$ ]]; then
    # wsl.conf 적용
    sudo cp "$WSL_CONF_OUT" /etc/wsl.conf
    echo "✔ /etc/wsl.conf 가 업데이트되었습니다."

    # bashrc 연동
    if [ -s "$BASHRC_SNIPPET" ]; then
        if ! grep -q "bashrc-vscode" ~/.bashrc; then
            # 절대 경로로 source 하도록 수정
            FULL_BASHRC_SNIPPET_PATH="$(realpath ${BASHRC_SNIPPET})"
            echo -e "\n# VS Code Path Recovery from WSL Optimization\nsource ${FULL_BASHRC_SNIPPET_PATH}" >> ~/.bashrc
            echo "✔ ~/.bashrc 에 VS Code 경로 추가 완료."
        fi
    fi

    # .wslconfig 자동 복사 시도
    # Windows 사용자 프로필 경로 찾기 (C:\Users\username)
    WIN_USER_PROFILE=$(powershell.exe -Command "echo \$env:USERPROFILE" 2>/dev/null | tr -d '\r' | sed 's/\\/\//g' | sed 's/C:/\/mnt\/c/I')
    
    if [ -n "$WIN_USER_PROFILE" ] && [ -d "$WIN_USER_PROFILE" ]; then
        cp "$WSLCONFIG_OUT" "$WIN_USER_PROFILE/.wslconfig"
        echo "✔ Windows 호스트의 .wslconfig가 업데이트되었습니다 ($WIN_USER_PROFILE/.wslconfig)."
    else
        echo -e "\n\033[1;31m중요: .wslconfig 파일은 수동으로 옮겨야 합니다.\033[0m"
        echo "윈도우 탐색기에서 %USERPROFILE% 폴더(예: C:\\Users\\사용자명)로 아래 파일을 복사하세요."
        echo "소스 파일: $WSLCONFIG_OUT"
    fi

    # 7. Git 전역 설정 추천
    echo -e "\n\033[1;33mStep 7: Git 전역 설정 (권장)\033[0m"
    echo "WSL2와 Windows간의 파일 공유 시 발생할 수 있는 줄바꿈 및 권한 문제를 방지합니다."
    read -p "Git 권장 설정을 적용하시겠습니까? (autocrlf=input, filemode=false) (y/n): " APPLY_GIT
    if [[ "$APPLY_GIT" =~ ^[Yy]$ ]]; then
        git config --global core.autocrlf input
        git config --global core.filemode false
        echo "✔ Git 전역 설정 완료 (core.autocrlf=input, core.filemode=false)"
    fi

    echo -e "\n\033[1;32m[성공] 모든 설정이 적용되었습니다!\033[0m"
    echo -e "추가 팁: AI IDE(Cursor 등)의 성능을 위해 'configs/vscode-settings.json'의 파일 감시자 제외 설정을 VS Code에 적용하는 것을 권장합니다."
    
    echo -e "\n\033[1;33m💡 아키텍처 팁 (중요):\033[0m"
    echo "1. 8초 규칙: WSL은 마지막 터미널 종료 후 8초간 백그라운드에서 유지됩니다."
    echo "   변경사항을 즉시 적용하려면 반드시 'wsl --shutdown'을 실행하세요."
    echo "2. 파일 시스템: 성능을 위해 프로젝트 소스코드는 반드시 리눅스(~/...) 내부에 두세요."
    echo "   /mnt/c 경로는 9P 프로토콜 오버헤드로 인해 AI 인덱싱이 매우 느립니다."

    echo -e "\n이제 윈도우 터미널(CMD/PowerShell)에서 아래 명령어를 순서대로 실행하세요:"
    echo -e ">> wsl --shutdown"
    echo -e ">> wsl"
    echo -e "\n다시 접속 후 'code .' 또는 'node -v' 등이 정상 작동하는지 확인하세요."
else
    echo "수동 적용을 위해 생성된 파일들을 확인해 주세요."
fi
