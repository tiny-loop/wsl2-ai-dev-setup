# WSL2 AI 개발 환경 설정

Windows WSL2에서 AI IDE (Claude Desktop, Cursor 등) 및 개발 도구를 위한 최적화된 환경을 자동으로 구성하는 스크립트 모음입니다.

> **English version**: See [docs/en/README.md](docs/en/README.md)

## ✨ 주요 특징

- **🎯 3단계 설치 프로세스** - Windows 설정 → WSL 환경 → 개발 도구 순서로 명확한 단계
- **� Windows 10/11 자동 호환성** - Windows 버전 감지 후 배포하는 옵션을 자동으로 조정 (Mirrored, Experimental 기능은 Win11에서만)
- **🔒 Windows PATH 오염 방지** - `appendWindowsPath=false`로 충돌 방지, VS Code 경로만 선택적 추가
- **🌐 Mirrored Networking** - Windows 11에서 AI IDE의 Browser Subagent 완벽 지원
- **⚡ 자동 메모리 관리** - WSL2 메모리 자동 회수로 시스템 안정성 향상 (Windows 11)
- **📦 선택적 설치** - Node.js, Chrome, Claude Code, Gemini CLI 등 필요한 것만 설치

## 목차

- [빠른 시작](#-빠른-시작)
- [설치 프로세스](#-설치-프로세스)
- [사전 요구사항](#사전-요구사항)
- [상세 가이드](#상세-가이드)
- [문제 해결](#-문제-해결)
- [추가 정보](#-추가-정보)

## 🚀 빠른 시작

### 1. 저장소 클론

```bash
# WSL2 터미널에서 실행
git clone https://github.com/tiny-flowlab/wsl2-ai-dev-setup.git
cd wsl2-ai-dev-setup
```

### 2. 메인 설치 스크립트 실행

```bash
./setup.sh
```

메뉴에서 다음 중 선택:
- **단계별 설치** (권장): Step 1 → 2 → 3 순서대로 진행
- **전체 자동 설치**: 모든 단계를 순차 실행

## 📋 설치 프로세스

### Step 1: Windows 호스트 설정 (.wslconfig)

```bash
bash scripts/setup-1-windows.sh
```

**수행 작업:**
- Windows 사용자 홈 자동 탐지
- **시스템 메모리 및 Windows 버전 자동 감지**
- WSL2 메모리/CPU 할당량 설정
- **고급 옵션 선택** (모든 사용자에게 동일 메뉴 표시):
  - Mirrored Networking (Windows 11 권장)
  - Sparse VHD (Windows 11 전용)
  - Auto Memory Reclaim (Windows 11 전용)
  - DNS Tunneling (Windows 11 전용)
- **Windows 10**: 미지원 옵션 자동 제외 + 요약 표시
- **Windows 11**: 모든 옵션 사용 가능
- `.wslconfig` 파일을 Windows 홈에 **자동 복사** ✅

**Windows 10 사용자:**
- Mirrored, Experimental 기능이 자동으로 제외됩니다.
- NAT 모드로 WSL이 실행되며, `$WINDOWS_HOST` 환경변수로 Windows 서비스 접근 가능

**완료 후:**
```powershell
# Windows PowerShell에서 실행
wsl --shutdown
wsl  # WSL 재시작 (설정 적용)
```
WSL 다시 시작 후 Step 2로 진행

### Step 2: WSL 기본 환경 설정

```bash
bash scripts/setup-2-wsl-base.sh
```

**수행 작업:**
- `/etc/wsl.conf` 설정 (appendWindowsPath=false)
- Git 전역 설정 (CRLF, filemode)
- `~/.bashrc` 환경 변수 (VS Code 경로만 추가)

**완료 후:**
```bash
source ~/.bashrc
```
```powershell
# Windows PowerShell에서 다시 실행
wsl --shutdown
```

### Step 3: 개발 도구 설치 (선택적)

```bash
bash scripts/setup-3-dev-tools.sh
```

**설치 가능한 도구:**
1. Node.js + npm (NVM 사용)
2. Chrome (MCP 디버깅용)
3. Claude Code / Cursor CLI
4. Gemini CLI
5. SSH Key 설정

필요한 것만 선택하여 설치 가능합니다.

## 사전 요구사항

### Windows 측

- **Windows 11 22H2 이상 (권장)** - Mirrored Networking 및 고급 기능 지원
  - Windows 10도 지원하지만 일부 기능 제한
- WSL2 활성화 및 최신 버전
- 인터넷 연결

### WSL2 배포판

지원 운영체제:
- **Ubuntu 20.04+** / Debian 기반 배포판 (권장)
- Rocky Linux 9+ / RHEL 기반 배포판

WSL2 버전 확인:
```bash
wsl --version  # Windows PowerShell에서
```

## 상세 가이드

### 주요 최적화 기능

#### 1. Windows PATH 오염 방지

**문제:**
- `appendWindowsPath=true` (기본값)일 때, Windows의 모든 실행 파일이 WSL PATH에 추가됨
- Node.js, Python 등이 Windows/WSL 양쪽에 설치되면 충돌 발생
- 성능 저하 및 명령어 실행 오류

**해결:**
```ini
# /etc/wsl.conf
[interop]
appendWindowsPath=false  # PATH 오염 차단
```

**VS Code 경로 복구:**
```bash
# ~/.bashrc에 VS Code 경로만 추가
export PATH="$PATH:/mnt/c/Users/<사용자명>/AppData/Local/Programs/Microsoft VS Code/bin"
```

#### 2. Mirrored Networking (Windows 11 전용)

AI IDE (Cursor, Claude Desktop, Antigravity)의 Browser Subagent가 Windows Chrome에 접근하려면 필수:

```ini
# .wslconfig
[wsl2]
networkingMode=mirrored  # Windows와 동일 IP 사용
```

**효과:**
- WSL → Windows Chrome (`localhost:9222`) 접근 가능
- VPN 연결 자동 공유
- IPv6 완전 지원

#### 3. 자동 메모리 관리

```ini
# .wslconfig (Windows 11)
[experimental]
autoMemoryReclaim=gradual  # 미사용 메모리 자동 반환
sparseVhd=true            # 디스크 공간 자동 축소
```

### 프로젝트 구조

```
wsl2-ai-dev-setup/
├── setup.sh                      # 메인 설치 스크립트 (인터랙티브)
├── scripts/
│   ├── setup-1-windows.sh        # Step 1: Windows 호스트 설정
│   ├── setup-2-wsl-base.sh       # Step 2: WSL 기본 환경
│   ├── setup-3-dev-tools.sh      # Step 3: 개발 도구 설치
│   ├── install-nodejs.sh         # Node.js 설치 (NVM)
│   ├── install-chrome.sh         # Chrome 설치
│   ├── install-claude-code.sh    # Claude Code 설치
│   ├── install-gemini.sh         # Gemini CLI 설치
│   ├── setup-ssh-key.sh          # SSH 키 생성
│   ├── validate-environment.sh   # 환경 검증 및 진단
│   └── check-versions.sh         # 버전 확인
├── configs/
│   ├── wslconfig-windows         # .wslconfig 템플릿
│   ├── wsl.conf                  # wsl.conf 템플릿
│   ├── mcp-config.json           # MCP 설정 예제
│   └── vscode-settings.json      # VS Code 권장 설정
└── docs/
    └── troubleshooting.md        # 문제 해결 가이드

### 권장 설치 순서
1.  **9) WSL2 대화형 사양 맞춤 최적화**: 시스템 RAM에 맞춘 메모리 할당 및 Windows 11 전용 고급 기능(Mirrored Network 등)을 설정합니다.
2.  **1) Full setup**: Node.js, Claude Code, Gemini CLI 등 개발 도구를 일괄 설치합니다.
3.  **10) 환경 검증**: 모든 설정이 최적의 상태(PATH 격리 등)인지 확인합니다.

---

## 🛠 주요 최적화 기능 (WSL2 Architecture Analysis 기반)

### 1. 전역 리소스 관리 (.wslconfig)
-   **Memory Allocation**: 시스템 RAM 사양에 맞춰 25%~75% 자동 제안.
-   **Experimental Features (Win 11)**:
    -   `mirrored`: Windows와 WSL간의 네트워크 경계를 허물어 `localhost` 통신 최적화.
    -   `autoMemoryReclaim`: 리눅스에서 사용하지 않는 메모리를 윈도우로 즉시 반환.
    -   `sparseVhd`: 리눅스 파일을 지우면 가상 디스크(VHDX) 크기를 자동으로 축소.

### 2. 환경 격리 및 연동 (wsl.conf)
-   **Windows PATH 격리**: `appendWindowsPath = false`를 통해 Windows의 수많은 `.exe` 파일이 리눅스 환경에 간섭하는 것을 방지 (성능 향상 및 명령어 충돌 방지).
-   **VS Code 연동**: PATH를 격리하더라도 `code .`을 사용할 수 있도록 VS Code 바이너리 경로만 추출하여 별도 복구.
-   **Permissions (Metadata)**: `/mnt/c` 등의 드라이브 마운트 시 리눅스 권한(`chmod`, `chown`)을 사용할 수 있도록 설정.

자세한 내용: [문제 해결 가이드](docs/troubleshooting.md)

### 🔴 Windows 10 vs 11 중요 차이점

| 기능 | Windows 10 | Windows 11 (22H2+) |
|------|------------|-------------------|
| **네트워크 모드** | NAT만 (localhost 제한) | **Mirrored** ✅ (양방향 localhost) |
| **메모리 자동 회수** | ❌ | ✅ `autoMemoryReclaim` |
| **AI IDE 호환성** | 제한적 (우회 필요) | **완전 지원** ✅ |

> **Cursor, Antigravity 등 AI IDE 사용 시 Windows 11 + `networkingMode=mirrored` 필수!**

📚 공식 문서: [Microsoft WSL 구성 가이드](https://learn.microsoft.com/ko-kr/windows/wsl/wsl-config)

## 사전 요구사항

- Windows 10/11 with WSL2 활성화
  - ⚠️ **권장**: Windows 11 22H2 이상 (AI IDE 완전 지원)
- WSL2 배포판 설치 (지원 OS 참고)
- WSLg (GUI 지원) - 최신 WSL2 버전에 포함
- 인터넷 연결

**지원 운영체제:**
- Ubuntu 20.04+ / Debian 기반 배포판
- Rocky Linux 9+ / RHEL 기반 배포판 (Fedora, CentOS)

### WSL2 버전 확인

```bash
wsl --version  # Windows PowerShell에서 실행
```

WSL 업데이트가 필요한 경우:
```bash
wsl --update  # Windows PowerShell에서 실행
```

## 시작하기 전에

### 1단계: Windows에서 WSL2 설정 (최초 1회)

이 단계는 Windows 환경에서 수행합니다.

#### WSL2 설치

**관리자 권한 PowerShell**에서 실행:

```powershell
# 자동 설치 (기본: Ubuntu)
wsl --install

# 또는 특정 배포판 지정:
wsl --install -d Ubuntu-22.04
# 또는
wsl --install -d RockyLinux-9
```

**사용 가능한 배포판 목록 확인:**
```powershell
wsl --list --online
```

#### WSL2 업데이트 및 확인

```powershell
# WSL2 업데이트
wsl --update

# 버전 확인 (2.0.0 이상이어야 함)
wsl --version

# WSL2 재시작 (업데이트 후)
wsl --shutdown
```

#### WSL2 실행

```powershell
# 설치한 배포판 실행
wsl

# 또는 특정 배포판 실행
wsl -d Ubuntu-22.04
```

**첫 실행 시**: 사용자 이름과 비밀번호를 설정해야 합니다.

### 2단계: WSL2 내부에서 저장소 가져오기

이제부터는 **WSL2 터미널 내부**에서 작업합니다.

#### 방법 1: Git으로 클론 (권장)

**Git이 이미 설치되어 있는 경우:**
```bash
# 저장소 클론
# WSL2 터미널에서 실행
git clone https://github.com/tiny-flowlab/wsl2-ai-dev-setup.git
cd wsl2-ai-dev-setup
```

**Git이 설치되어 있지 않은 경우:**

Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y git
```

Rocky Linux/RHEL:
```bash
sudo dnf install -y git
```

그 후 위의 git clone 명령어 실행.

#### 방법 2: ZIP 다운로드

Git을 사용하지 않는 경우:

1. 브라우저에서 저장소 페이지 방문
2. "Code" → "Download ZIP" 클릭
3. Windows 다운로드 폴더에서 WSL2로 복사:

```bash
# Windows 다운로드 폴더에서 복사
mkdir -p ~/my_work
cd ~/my_work
unzip /mnt/c/Users/<your-windows-username>/Downloads/dev_setup-main.zip
mv dev_setup-main dev_setup
cd dev_setup
```

#### 방법 3: 직접 생성

이 저장소를 fork하거나 내용을 복사하여 직접 만든 경우:

```bash
mkdir -p ~/my_work/dev_setup
cd ~/my_work/dev_setup
# 파일들을 여기에 복사
```

## 빠른 시작

저장소를 가져온 후, WSL2 터미널에서:

1. 저장소 디렉토리로 이동:
```bash
cd ~/my_work/dev_setup
```

2. 메인 설치 스크립트를 실행합니다:
```bash
bash setup.sh
```

3. 대화형 프롬프트에 따라 설치할 항목을 선택합니다

4. 설치 후 셸을 다시 로드합니다:
```bash
source ~/.bashrc
```

## 프로젝트 구조

```
dev_setup/
├── setup.sh                      # 메인 설치 오케스트레이션 스크립트
├── scripts/
│   ├── common.sh                 # 공통 함수 (OS 감지, 패키지 관리자 추상화)
│   ├── install-nodejs.sh         # Node.js 및 NVM 설치
│   ├── install-claude-code.sh    # Claude Code CLI 설치
│   ├── install-gemini.sh         # Gemini CLI 설치
│   ├── install-chrome.sh         # Chrome 및 MCP 설치
│   ├── start-chrome-debug.sh     # Chrome 원격 디버깅 시작 스크립트
│   ├── setup-ssh-key.sh          # SSH 키 생성 및 GitHub 설정
│   ├── check-versions.sh         # 설치된 도구 버전 확인
│   ├── validate-environment.sh   # 🆕 환경 검증 (PATH 오염, 설정 점검)
│   └── apply-optimizations.sh    # 🆕 WSL2 최적화 설정 적용
├── configs/
│   ├── mcp-config.json           # MCP 설정 예시
│   ├── bashrc-additions          # 환경 변수 및 별칭
│   ├── wsl.conf                  # 🆕 /etc/wsl.conf 템플릿 (PATH 오염 방지)
│   ├── wslconfig-windows         # 🆕 .wslconfig 템플릿 (메모리, 네트워크)
│   └── vscode-settings.json      # 🆕 VS Code 최적화 설정
├── docs/
│   ├── troubleshooting.md        # 종합 문제 해결 가이드 (한국어)
│   └── en/                       # 영어 문서
│       ├── README.md
│       ├── CLAUDE.md
│       └── troubleshooting.md
├── README.md                     # 이 파일 (한국어)
└── CLAUDE.md                     # Claude Code용 가이드 (한국어)
```

## 설치 가이드

### 옵션 1: 전체 설치

모든 것을 한 번에 설치:

```bash
bash setup.sh
# 옵션 1 (전체 설치) 선택
```

### 옵션 2: 개별 설치

각 컴포넌트를 개별적으로 설치:

#### Node.js (먼저 설치 필요)

```bash
bash scripts/install-nodejs.sh
```

설치 내역:
- NVM (Node Version Manager)
- 최신 Node.js LTS 버전
- npm 글로벌 패키지 지원

#### Claude Code

```bash
bash scripts/install-claude-code.sh
```

Anthropic API 키 필요: https://console.anthropic.com/settings/keys

**자동 설정:**
- Claude CLI 설치
- `claude mcp add` 명령으로 chrome-devtools MCP 서버 추가
- jq로 WSL2 workaround 인수 (`--browserUrl`) 자동 추가
- 설정 파일: `~/.config/claude/config.json`

#### Gemini CLI

```bash
bash scripts/install-gemini.sh
```

Google 계정 OAuth 인증 사용 (API 키 불필요):
- 설치 후 `gemini` 명령 실행
- 로그인 프롬프트에 따라 Google 계정으로 인증
- 무료 티어: Gemini 2.5 Pro, 분당 60회/하루 1,000회 요청

**자동 설정:**
- Gemini CLI 설치
- `gemini mcp add` 명령으로 chrome-devtools MCP 서버 추가
- jq로 WSL2 workaround 인수 (`--browserUrl`) 자동 추가
- 설정 파일: `~/.gemini/settings.json`

#### Chrome + MCP

```bash
bash scripts/install-chrome.sh
```

설치 내역:
- WSL2용 Google Chrome
- 원격 디버깅 설정 스크립트 (`start-chrome-debug.sh`)

**참고:** chrome-devtools-mcp는 npm 글로벌 설치하지 않습니다. 각 CLI의 MCP 설정에서 `npx`를 통해 실행 시 자동으로 최신 버전을 다운로드합니다.

#### GitHub용 SSH 키

```bash
bash scripts/setup-ssh-key.sh
```

SSH 키(ED25519 또는 RSA)를 생성하고 GitHub 설정 방법을 안내합니다.

## Chrome 원격 디버깅 & MCP

### 왜 이런 설정이 필요한가요?

`chrome-devtools-mcp` 패키지는 WSL2 환경에서 **아키텍처 제한사항**이 있습니다:

- **GitHub Issue #131** (✅ CLOSED): WSL2에서 Chrome을 감지하지 못함
  - https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131
  - **상태**: ❌ 근본 해결 안 됨 (아키텍처 제한)
  - **해결**: `--browserUrl` 또는 `--wsEndpoint` 사용 (공식 권장)
- **GitHub Issue #225** (✅ CLOSED, 2025년 10월): `headless=false` 사용 시 프로토콜 에러
  - https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225
  - **상태**: ⚠️ 외부 Chrome 사용 시 우회 가능
  - **해결**: v0.7.0+ 안정성 향상, workaround가 공식 방법

**공식 권장 방법** (v0.9.0 기준):

1. Chrome을 원격 디버깅 모드로 별도 실행
2. MCP를 `--browserUrl` 또는 `--wsEndpoint`로 외부 Chrome에 연결
3. 이 방법으로 안정적인 연결 보장
4. **현재 최신**: chrome-devtools-mcp v0.9.0 (2025년 10월)
5. **권장**: v0.9.0 이상 사용 (WebSocket endpoint 지원)

> 📖 **자세한 버전 정보**: [chrome-devtools-mcp CHANGELOG](docs/chrome-devtools-mcp-CHANGELOG.md) 참고

### Chrome MCP 시작하기

```bash
bash scripts/start-chrome-debug.sh
```

이 스크립트는 다음과 같이 Chrome을 시작합니다:
- 포트 9222에서 원격 디버깅 (설정 가능)
- 별도의 프로필 디렉토리 사용
- WSLg를 통한 GUI 창

### Chrome 디버깅 확인

```bash
curl http://localhost:9222/json/version
```

Chrome 버전 정보가 담긴 JSON 출력이 표시되어야 합니다.

### MCP 설정

**✅ 자동 설정 (권장)**

설치 스크립트(`install-claude-code.sh`, `install-gemini.sh`)가 자동으로 MCP를 설정합니다:
1. CLI의 `mcp add` 명령으로 chrome-devtools 서버 추가
2. jq로 `--browserUrl=http://localhost:9222` 인수 자동 추가

설치 후 추가 설정 불필요! Chrome 디버깅만 시작하면 됩니다:
```bash
bash scripts/start-chrome-debug.sh
```

---

**수동 설정 (참고용)**

이미 설정이 완료되었지만, 수동으로 변경하려면:

```json
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

**대안 방법 (고급):**

`configs/mcp-config.json` 파일에서 다음 내용을 참고하세요:
- 방법 2: `--executable-path`로 Windows Chrome 직접 사용
- 방법 3: `--headless` 모드로 WSL Chrome 사용
- **방법 4 (v0.9.0+)**: `--wsEndpoint`로 WebSocket 연결 (아래 참고)
- Windows 11 네트워크 미러링 설정
- 여러 Chrome 인스턴스 설정

**설정 파일 위치:**
- Claude Code: `~/.config/claude/config.json`
- Gemini CLI: `~/.gemini/settings.json`

---

### WebSocket Endpoint 방법 (v0.9.0+)

chrome-devtools-mcp v0.9.0부터 WebSocket endpoint를 직접 지정할 수 있습니다:

**1. WebSocket URL 확인**:
```bash
curl http://localhost:9222/json/version
```

출력 예시:
```json
{
  "webSocketDebuggerUrl": "ws://127.0.0.1:9222/devtools/browser/abc123..."
}
```

**2. MCP 설정**:
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

**3. 인증이 필요한 경우** (선택사항):
```json
{
  "args": [
    "chrome-devtools-mcp@latest",
    "--wsEndpoint=ws://127.0.0.1:9222/devtools/browser/abc123...",
    "--wsHeaders={\"Authorization\":\"Bearer YOUR_TOKEN\"}"
  ]
}
```

**browserUrl vs wsEndpoint**:
- `--browserUrl`: 간단, 자동으로 WebSocket 탐지
- `--wsEndpoint`: 직접 지정, 커스텀 헤더 지원, 고급 시나리오용

## 환경 설정

### 자동 설정

설치 스크립트가 자동으로 `~/.bashrc`에 필요한 설정을 추가합니다:

- NVM 초기화
- npm 글로벌 경로
- API 키 (실제 키는 직접 입력 필요)
- SSH 에이전트 자동 시작
- Chrome 디버깅 포트
- 유용한 별칭 및 함수

### 수동 설정

수동 설정을 원하는 경우 `configs/bashrc-additions` 파일에서 추가할 수 있는 모든 환경 변수와 함수를 확인하세요.

### API 키 설정

`~/.bashrc`를 편집하여 실제 API 키를 추가하세요:

```bash
export ANTHROPIC_API_KEY='your-anthropic-api-key-here'
```

**참고:** Gemini CLI는 OAuth 인증을 사용하므로 API 키가 필요하지 않습니다.

## 사용법

### Claude Code

```bash
claude --help                    # 도움말 표시
claude                          # 대화형 세션 시작
```

### Gemini CLI

```bash
gemini                          # 대화형 세션 시작 (첫 실행 시 인증)
gemini --help                   # 도움말 표시
```

### Chrome 디버깅

```bash
chrome-debug                    # Chrome 디버깅 시작 (별칭)
chrome-stop                     # Chrome 디버깅 중지 (별칭)
check-chrome-debug              # Chrome 실행 상태 확인 (함수)
```

### 개발 환경 확인

```bash
check-dev-env                   # 모든 컴포넌트 상태 표시
check-versions                  # 설치된 도구 버전 확인 및 업데이트 알림
```

## VSCode 통합

### VSCode Remote-WSL 확장 설치

1. Windows에 VSCode 설치
2. "Remote - WSL" 확장 설치
3. WSL2 터미널을 열고 실행:
   ```bash
   code .
   ```

VSCode가 자동으로 WSL2 환경에 연결됩니다.

### VSCode와 Claude Code

모든 설정이 완료되면:
1. Claude Code가 통합 터미널에서 작동합니다
2. 설정된 경우 MCP 서버에 접근할 수 있습니다
3. Chrome 디버깅을 백그라운드에서 실행할 수 있습니다

## 문제 해결

**종합 문제 해결 가이드는 [`docs/troubleshooting.md`](docs/troubleshooting.md)를 참고하세요**

이 가이드에는 다음 출처의 검증된 해결책이 포함되어 있습니다:
- GitHub Issue #131: https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131
- GitHub Issue #225: https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225
- Cursor Forum: https://forum.cursor.com/t/complete-guide-setting-up-mcp-tools-with-browser-extensions-in-wsl2/109614

### 주요 Chrome MCP 문제

#### Issue #131: WSL2에서 Chrome 감지 안 됨

**문제:** MCP가 WSL2에서 Chrome 브라우저를 찾지 못함

**해결:** 외부 Chrome과 `--browserUrl` 사용
```bash
bash scripts/start-chrome-debug.sh
curl http://localhost:9222/json/version  # 확인
```

**대안:** Windows Chrome을 직접 지정
```json
{
  "args": [
    "chrome-devtools-mcp@latest",
    "--executable-path=/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
  ]
}
```

#### Issue #225: headless=false 시 프로토콜 에러

**문제:** `Protocol error (Target.setDiscoverTargets): Target closed`

**해결:** 외부 Chrome 인스턴스 사용 (방법 1) - 이 방법으로 문제를 완전히 회피

**대안:** WSLg 설정 수정
```bash
# WSLg 확인
echo $DISPLAY        # :0 또는 유사한 값 표시되어야 함

# WSL 업데이트 (PowerShell에서)
wsl --update
wsl --shutdown
```

### Chrome이 시작되지 않음

```bash
echo $DISPLAY        # :0 또는 유사한 값 표시되어야 함
xeyes               # X11 테스트 (설치: sudo apt install x11-apps)
```

**해결:** WSL 업데이트
```powershell
# Windows PowerShell에서
wsl --update
wsl --version    # 2.0.0+ 이어야 함
wsl --shutdown
```

### MCP 연결 문제

1. Chrome이 실행 중인지 확인:
   ```bash
   lsof -i :9222
   ```

2. 연결 테스트:
   ```bash
   curl http://localhost:9222/json/version
   ```

3. Chrome 프로세스 확인:
   ```bash
   ps aux | grep chrome | grep remote-debugging
   ```

4. 디버그 로깅 활성화:
   ```json
   {
     "args": [
       "chrome-devtools-mcp@latest",
       "--browserUrl=http://localhost:9222",
       "--log-file=/tmp/chrome-mcp.log"
     ]
   }
   ```

### Node.js / npm 문제

NVM 다시 로드:
```bash
source ~/.bashrc
nvm use --lts
```

글로벌 패키지 위치 확인:
```bash
npm config get prefix    # ~/.npm-global 이어야 함
```

### SSH 키 문제

GitHub 연결 테스트:
```bash
ssh -T git@github.com
```

SSH 에이전트 확인:
```bash
ssh-add -l              # 로드된 키 목록
```

### PATH 문제

PATH 확인:
```bash
echo $PATH
```

다음이 포함되어야 합니다:
- `$HOME/.npm-global/bin`
- `$HOME/.nvm/versions/node/*/bin`

### Windows 11 네트워크 미러링 (선택사항)

WSL2-Windows 네트워킹 개선:

1. Windows에서 `%USERPROFILE%\.wslconfig` 편집:
   ```ini
   [wsl2]
   networkingMode=mirrored
   ```

2. WSL 재시작:
   ```powershell
   wsl --shutdown
   ```

장점: localhost 포워딩 개선, MCP 통신 향상

## 커스터마이징

### Chrome 디버그 포트 변경

```bash
export CHROME_DEBUG_PORT=9223
bash scripts/start-chrome-debug.sh
```

MCP 설정도 새 포트에 맞게 업데이트하세요.

### 여러 Chrome 인스턴스

서로 다른 포트에서 여러 Chrome 인스턴스를 실행할 수 있습니다. 예시는 `configs/mcp-config.json`을 참고하세요.

## 보안 주의사항

- **절대 API 키를 버전 관리에 커밋하지 마세요**
- `~/.bashrc`를 비공개로 유지하세요
- SSH 키는 `~/.ssh/`에 적절한 권한(private key는 600)으로 보관하세요
- 인터넷에서 받은 스크립트를 실행할 때 주의하세요

## 버전 확인

설치된 도구들의 버전을 확인하고 업데이트가 필요한지 자동으로 확인할 수 있습니다:

```bash
# 명령줄에서
check-versions

# 또는 setup.sh 메뉴에서
bash setup.sh
# 옵션 8 선택: Check installed versions
```

이 명령은 다음을 확인합니다:
- NVM, Node.js, npm 버전
- Claude Code CLI 및 Gemini CLI 버전
- Google Chrome 버전
- chrome-devtools-mcp 버전 (v0.7.0 이상 권장)
- Chrome 원격 디버깅 상태

각 도구에 대해 최신 버전과 비교하고, 업데이트가 필요한 경우 업데이트 명령어를 표시합니다.

## 업데이트

### 버전 확인 먼저

```bash
check-versions                 # 어떤 도구를 업데이트해야 하는지 확인
```

### Node.js 업데이트

```bash
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'
```

### npm 패키지 업데이트

```bash
npm-update-global              # 모든 글로벌 패키지 업데이트 (함수)
# 또는 수동으로:
npm update -g
```

### Chrome 업데이트

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get upgrade google-chrome-stable
```

**Rocky Linux/RHEL:**
```bash
sudo dnf upgrade google-chrome-stable
```

### Claude Code 업데이트

```bash
npm update -g @anthropic-ai/claude-code
```

## 추가 자료

### 공식 문서
- [WSL2 Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [Claude Code Documentation](https://docs.anthropic.com/)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [NVM Documentation](https://github.com/nvm-sh/nvm)
- [Chrome DevTools MCP](https://github.com/ChromeDevTools/chrome-devtools-mcp)

### 검증된 GitHub 이슈
- [Issue #131 - WSL2 Chrome Detection](https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131) - WSL2에서 Chrome 감지 실패 문제
- [Issue #225 - Headless Protocol Error](https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225) - Headless 모드 프로토콜 에러

### 커뮤니티 가이드
- [Cursor Forum - WSL2 MCP Setup](https://forum.cursor.com/t/complete-guide-setting-up-mcp-tools-with-browser-extensions-in-wsl2/109614) - WSL2에서 MCP 도구 설정 가이드
- [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/) - Chrome DevTools 프로토콜 문서

## 기여

자신의 용도에 맞게 스크립트를 자유롭게 커스터마이징하세요. 버그를 발견하거나 개선사항이 있다면 스크립트를 업데이트해 주세요.

## 라이선스

이 스크립트는 개인 사용을 위해 있는 그대로 제공됩니다. 필요에 따라 수정하고 배포하세요.
