# 문제 해결 가이드

WSL2 개발 환경 설정 중 발생하는 일반적인 문제와 해결 방법입니다. GitHub 이슈 및 커뮤니티 포럼에서 검증된 솔루션을 기반으로 작성되었습니다.

> **📚 공식 문서**: [Microsoft WSL 구성 가이드](https://learn.microsoft.com/ko-kr/windows/wsl/wsl-config)

> **English version**: See [en/troubleshooting.md](en/troubleshooting.md)

## 목차

1. [🔴 Windows 10 vs 11 기능 차이 (필독)](#windows-10-vs-11-기능-차이-필독)
2. [🔴 핵심 문제: PATH 오염 및 Windows/Linux 바이너리 충돌](#핵심-문제-path-오염-및-windowslinux-바이너리-충돌)
3. [🔴 파일 시스템 성능 및 권한 문제](#파일-시스템-성능-및-권한-문제)
4. [🟡 Git 줄바꿈(CRLF/LF) 및 권한 문제](#git-줄바꿈crlfLf-및-권한-문제)
5. [AI IDE 관련 (Cursor, Antigravity)](#ai-ide-관련-cursor-antigravity)
6. [Chrome DevTools MCP 문제](#chrome-devtools-mcp-문제)
7. [WSLg (GUI) 문제](#wslg-gui-문제)
8. [Node.js 및 npm 문제](#nodejs-및-npm-문제)
9. [SSH 키 문제](#ssh-키-문제)
10. [네트워크 및 포트 문제](#네트워크-및-포트-문제)
11. [일반 WSL2 문제](#일반-wsl2-문제)

---

## Windows 10 vs 11 기능 차이 (필독)

> ⚠️ **중요**: Windows 버전에 따라 사용 가능한 WSL2 기능이 **근본적으로 다릅니다**.
> AI IDE(Cursor, Antigravity)나 복잡한 네트워크 환경에서는 Windows 11이 **사실상 필수**입니다.

### 기능 비교표

| 기능 | Windows 10 | Windows 11 (22H2+) | 구성 방법 |
|------|------------|-------------------|-----------|
| **네트워크 모드** | NAT만 지원 | **Mirrored 지원** ✅ | `.wslconfig`: `networkingMode=mirrored` |
| **Localhost 접근** | Win→Lin만 | **양방향** ✅ | Mirrored 모드 사용 |
| **메모리 자동 회수** | ❌ 미지원 | **gradual/dropcache** ✅ | `.wslconfig`: `autoMemoryReclaim=gradual` |
| **디스크 자동 축소** | ❌ 미지원 | **Sparse VHD** ✅ | `.wslconfig`: `sparseVhd=true` |
| **IPv6 지원** | 제한적 | **완전 지원** | Mirrored 모드 사용 |
| **VPN 호환성** | 문제 빈번 | **자동 공유** | Mirrored 모드 사용 |
| **호스트 루프백** | ❌ 미지원 | ✅ 지원 | `hostAddressLoopback=true` |
| **Systemd** | 업데이트 필요 | 기본 지원 | `wsl.conf`: `systemd=true` |
| **WSLg (GUI)** | 업데이트 필요 | 기본 내장 | 자동 |

### 네트워킹 모드 상세 비교

#### NAT 모드 (Windows 10 기본)

```
┌─────────────────────────────────────────────────────┐
│  Windows Host (192.168.1.100)                       │
│  ┌─────────────────────────────────────────────┐    │
│  │  Hyper-V Virtual Switch (NAT)               │    │
│  │  ┌─────────────────────────────────────┐    │    │
│  │  │  WSL2 VM (172.28.x.x)               │    │    │
│  │  │  - localhost ≠ Windows localhost    │    │    │
│  │  │  - 별도 IP 대역                      │    │    │
│  │  └─────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘

문제점:
- Linux에서 localhost:9222 → Windows Chrome 연결 불가
- VPN 연결 시 WSL 인터넷 끊김
- IPv6 미지원
```

#### Mirrored 모드 (Windows 11 22H2+)

```
┌─────────────────────────────────────────────────────┐
│  Windows Host + WSL2 (동일 네트워크 스택 공유)       │
│  - IP: 192.168.1.100 (공유)                        │
│  - localhost: 양방향 완벽 호환                      │
│  - VPN: 자동 공유                                   │
│  - IPv6, mDNS, 멀티캐스트 지원                      │
└─────────────────────────────────────────────────────┘

해결:
- Linux localhost:9222 = Windows localhost:9222 ✅
- Antigravity Browser Agent 정상 작동 ✅
```

### Windows 10 사용자를 위한 권장사항

**1. .wslconfig 수정 (Windows 11 전용 옵션 제거):**

```ini
# %USERPROFILE%\.wslconfig (Windows 10 호환 버전)
[wsl2]
memory=8GB
processors=4
swap=4GB
localhostForwarding=true
guiApplications=true

# ⚠️ 아래 옵션들은 Windows 10에서 무시되거나 오류 발생
# networkingMode=mirrored  # 주석 처리!
# [experimental] 섹션 전체 주석 처리!
```

**2. Localhost 연결 문제 우회 (NAT 모드):**

```bash
# WSL에서 Windows 호스트 IP 확인
cat /etc/resolv.conf | grep nameserver | awk '{print $2}'
# 예: 172.28.0.1

# Chrome 디버깅 연결 시 localhost 대신 호스트 IP 사용
curl http://172.28.0.1:9222/json/version
```

**3. Windows 11 업그레이드 고려:**
- Antigravity, Cursor 등 AI IDE 완전 지원
- VPN + WSL 호환성 문제 해결
- 메모리 자동 회수로 장시간 사용 안정성 향상

---

## 핵심 문제: PATH 오염 및 Windows/Linux 바이너리 충돌

### ⚠️ 가장 중요한 문제

WSL2의 기본 설정은 Windows의 PATH를 Linux에 자동으로 추가합니다. 이로 인해 **심각한 충돌**이 발생할 수 있습니다.

### 증상

```bash
# Windows의 node.exe가 실행됨
$ which node
/mnt/c/Program Files/nodejs/node.exe

# 바이너리 형식 오류
$ node script.js
cannot execute binary file: Exec format error

# npm.cmd 실행 시 문법 오류
$ npm install
Syntax error: word unexpected (expecting "in")

# NVM으로 버전 변경해도 Windows 버전이 계속 실행됨
$ nvm use 18
$ node --version
v14.0.0  # Windows에 설치된 버전
```

### 근본 원인

WSL2가 Windows의 `%PATH%`를 Linux의 `$PATH` 끝에 추가하여:
- Linux 바이너리가 없으면 Windows 바이너리(.exe)가 실행됨
- Windows 배치 파일(.cmd)을 Linux 쉘 스크립트로 해석하려 시도
- NVM 등 버전 관리자가 무력화됨

### 해결 방법 (필수)

**1. /etc/wsl.conf 설정:**

```bash
# 템플릿 복사
sudo cp configs/wsl.conf /etc/wsl.conf

# 또는 수동 생성
sudo tee /etc/wsl.conf << 'EOF'
[interop]
enabled = true
appendWindowsPath = false

[automount]
options = "metadata,uid=1000,gid=1000,umask=022,fmask=11,case=off"

[boot]
systemd = true
EOF
```

**2. WSL 재시작 (PowerShell에서):**

```powershell
wsl --shutdown
```

**⚠️ "8초 규칙"**: 터미널 종료 후 약 8초 대기하거나 `wsl --shutdown`으로 강제 종료해야 설정이 적용됩니다.

**3. 필요한 Windows 도구만 선택적 추가 (~/.bashrc):**

```bash
# VS Code
export PATH="$PATH:/mnt/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin"

# Windows 시스템 도구 (explorer.exe 등)
export PATH="$PATH:/mnt/c/Windows/System32"

# 또는 alias 사용
alias explorer='/mnt/c/Windows/explorer.exe'
```

**4. 검증:**

```bash
# PATH에 /mnt/c가 없어야 함
echo $PATH | grep -c "/mnt/c"  # 0이어야 정상

# node가 Linux 경로를 가리켜야 함
which node  # /home/user/.nvm/versions/node/v20.x.x/bin/node
```

---

## 파일 시스템 성능 및 권한 문제

### /mnt/c 사용 시 성능 저하 (10~100배 느림)

**원인:** WSL2는 Windows 드라이브를 **9P 프로토콜**(네트워크 파일 시스템)로 마운트합니다. 
대용량 단일 파일 전송은 빠르지만, **수만 개의 작은 파일** 처리에서 극심한 오버헤드 발생.

**증상:**
- `npm install`이 수 분 소요 (네이티브: 수 초)
- 파일 감시(watch) 모드가 느리거나 감지 실패
- IDE 인덱싱이 매우 느림

**해결:**

```bash
# ❌ 절대 금지
cd /mnt/c/Users/Me/projects/my-app
npm install  # 매우 느림

# ✅ 올바른 방법
cd ~/projects
git clone git@github.com:user/my-app.git
cd my-app
npm install  # 빠름
```

### chmod가 작동하지 않음 (777 문제)

**증상:**
```bash
$ chmod 600 ~/.ssh/id_rsa
$ ls -la ~/.ssh/id_rsa
-rwxrwxrwx 1 user user ...  # 여전히 777
```

**원인:** /mnt/c에서는 NTFS가 Linux 권한을 지원하지 않음

**해결:**

```ini
# /etc/wsl.conf
[automount]
options = "metadata,umask=22,fmask=11"
```

재시작 후:
```bash
# 기존 파일의 권한 수정
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/id_*.pub
```

### 파일 잠금 오류 (EBUSY/EPERM)

**증상:**
```bash
Error: EPERM: operation not permitted
Error: EBUSY: resource busy or locked
rm: cannot remove 'node_modules': Directory not empty
```

**원인:** Windows Defender나 다른 프로세스가 파일을 잠금

**해결:**
1. Windows Defender에서 프로젝트 폴더 제외
2. 프로젝트를 Linux 파일시스템으로 이동
3. 필요시 WSL 재시작: `wsl --shutdown`

---

## Git 줄바꿈(CRLF/LF) 및 권한 문제

### "bad interpreter: ^M" 오류

**증상:**
```bash
$ ./script.sh
/bin/bash^M: bad interpreter: No such file or directory
```

**원인:** Windows에서 생성된 파일에 CRLF 줄바꿈이 포함됨

**해결:**

```bash
# 1. 파일 변환
dos2unix script.sh
# 또는
sed -i 's/\r$//' script.sh

# 2. Git 설정으로 예방
git config --global core.autocrlf input
git config --global core.eol lf
```

### Git이 모든 파일을 "변경됨"으로 표시

**증상:** 아무것도 수정하지 않았는데 `git status`에 모든 파일이 변경됨으로 표시

**원인:** 파일 모드(실행 권한) 변경이 감지됨

**해결:**

```bash
git config --global core.filemode false
```

### Git 설정 권장값

```bash
# 줄바꿈 처리 (Linux 스타일 유지)
git config --global core.autocrlf input

# 파일 모드 변경 무시
git config --global core.filemode false

# 기본 줄바꿈
git config --global core.eol lf
```

---

## AI IDE 관련 (Cursor, Antigravity)

### Cursor: CPU 점유율 폭증 / UI 프리징

**원인:** 파일 감시자(File Watcher)가 node_modules 등을 실시간 감시

**해결 (settings.json):**

```json
{
  "files.watcherExclude": {
    "**/node_modules/**": true,
    "**/.git/objects/**": true,
    "**/venv/**": true,
    "**/__pycache__/**": true,
    "**/.nx/cache/**": true,
    "**/dist/**": true,
    "**/build/**": true
  }
}
```

또는 `configs/vscode-settings.json` 참조

### Antigravity: 브라우저 에이전트 연결 실패

**증상:**
```
ECONNREFUSED 127.0.0.1:9222
브라우저를 제어할 수 없습니다
```

**원인:** WSL2의 localhost가 Windows의 localhost와 격리됨 (NAT 모드)

**해결 (Windows 11 22H2+):**

```ini
# %USERPROFILE%\.wslconfig
[wsl2]
networkingMode=mirrored
```

PowerShell에서:
```powershell
wsl --shutdown
```

### .wslconfig 권장 설정 (AI IDE용)

```ini
[wsl2]
memory=8GB
processors=4
swap=4GB
networkingMode=mirrored
dnsTunneling=true
autoProxy=true
localhostForwarding=true
guiApplications=true

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
```

---

## Chrome DevTools MCP 문제

### Issue #131: WSL2에서 Chrome 감지 실패 (✅ CLOSED)

**상태:** 이슈 종료 - Workaround 방법들이 공식화됨

**문제:**
- MCP가 WSL2 환경에서 Chrome 브라우저를 찾지 못함
- 에러: "Chrome executable not found"
- MCP가 WSL 내부만 확인하고 Windows Chrome을 인식하지 못함

**공식 이슈:** https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131 (CLOSED)

**해결 방법:**

#### 방법 1: --browserUrl 사용 (권장)
외부에서 Chrome을 시작하고 포트 포워딩으로 연결:

```bash
# 1. Chrome을 원격 디버깅 모드로 시작
bash scripts/start-chrome-debug.sh

# 2. 연결 확인
curl http://localhost:9222/json/version

# 3. MCP 설정
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

#### 방법 2: Windows Chrome 직접 사용
Windows Chrome 설치 경로를 직접 지정:

```json
{
  "args": [
    "-y",
    "chrome-devtools-mcp@latest",
    "--executable-path=/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
  ]
}
```

**참고:** Chrome이 다른 위치에 설치되어 있다면 경로를 조정하세요.

#### 방법 3: WSL 내부에 Chrome 설치
WSL2 내부에 Linux용 Chrome 설치:

```bash
bash scripts/install-chrome.sh
```

---

### Issue #225: headless=false 사용 시 프로토콜 에러 (✅ CLOSED)

**상태:** 이슈 종료 (2025년 10월) - v0.7.0에서 해결됨

**문제:**
- 에러: `Protocol error (Target.setDiscoverTargets): Target closed`
- WSL2 Ubuntu에서 `headless: false` 설정 시 발생
- `headless: true`로 설정하면 작동함

**공식 이슈:** https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225 (CLOSED)

**해결 상태:**
- **chrome-devtools-mcp v0.7.0+**에서 Puppeteer 개선으로 안정성 향상
- Chrome 감지 로직 향상 및 Windows 환경 변수 인식 개선
- **현재 최신**: v0.9.0 (2025년 10월) - WebSocket endpoint 지원
- v0.9.0 이상 사용 권장
- 자세한 내역: [CHANGELOG](chrome-devtools-mcp-CHANGELOG.md)

**원인:**
WSLg(GUI 지원)가 제대로 설정되지 않았거나 Chrome이 GUI 모드로 실행되지 않음

**해결 방법:**

1. **--browserUrl 방법 사용** (문제를 완전히 회피)
   ```bash
   bash scripts/start-chrome-debug.sh
   ```

2. **WSLg 설정 수정**
   ```bash
   # WSLg 상태 확인
   echo $DISPLAY        # :0 또는 유사한 값이 표시되어야 함
   echo $WAYLAND_DISPLAY

   # WSL 업데이트 (Windows PowerShell에서)
   wsl --update
   wsl --shutdown

   # WSL 배포판 재시작
   ```

3. **헤드리스 모드 사용** (임시 해결책)
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

### WebSocket Endpoint 방법 (v0.9.0+)

chrome-devtools-mcp v0.9.0부터 WebSocket endpoint를 직접 지정할 수 있습니다. `--browserUrl`의 대안으로 사용 가능합니다.

**언제 사용하나요?**
- 커스텀 인증 헤더가 필요한 경우
- 직접 WebSocket URL을 제어하고 싶은 경우
- 고급 시나리오 (프록시, 커스텀 네트워크 설정 등)

**사용 방법:**

**1단계: Chrome 시작**
```bash
bash scripts/start-chrome-debug.sh
```

**2단계: WebSocket URL 확인**
```bash
curl http://localhost:9222/json/version
```

출력 예시:
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

**3단계: MCP 설정**

**기본 사용:**
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

**인증 헤더 포함:**
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

**browserUrl vs wsEndpoint 비교:**

| 특징 | --browserUrl | --wsEndpoint |
|-----|-------------|--------------|
| 사용 난이도 | ⭐ 쉬움 | ⭐⭐ 중간 |
| 자동 WebSocket 탐지 | ✅ 자동 | ❌ 수동 입력 필요 |
| 커스텀 헤더 지원 | ❌ 없음 | ✅ --wsHeaders 사용 |
| 권장 용도 | 일반 사용자 | 고급 사용자, 특수 요구사항 |

**장점:**
- 커스텀 인증 지원
- 더 세밀한 제어
- 프록시/터널링 시나리오에 유용

**단점:**
- WebSocket URL을 수동으로 확인/복사해야 함
- Chrome 재시작 시 URL 변경될 수 있음

**Tip**: 대부분의 경우 `--browserUrl`로 충분합니다. 특별한 요구사항이 있을 때만 `--wsEndpoint`를 사용하세요.

---

### SSH Tunneling 방법 (VM-to-Host)

**v0.9.0 공식 문서 추가**: WSL2/VM에서 Host의 Chrome에 연결하는 공식 방법

**문제:**
WSL2/VM 내부에서 Host의 Chrome(Windows)에 직접 연결 시 도메인 헤더 검증 실패

**해결:**
SSH tunneling을 사용하여 localhost로 포트 포워딩

```bash
# WSL2/VM에서 실행
ssh -N -L 127.0.0.1:9222:127.0.0.1:9222 user@host-ip
```

**설명:**
- `-N`: 명령어 실행 안 함 (터널링만)
- `-L`: 로컬 포트를 원격 포트로 포워딩
- `127.0.0.1:9222`: WSL2의 9222 포트
- `user@host-ip`: Windows Host의 사용자 및 IP

**그 후 MCP 설정:**
```json
{
  "args": [
    "chrome-devtools-mcp@latest",
    "--browserUrl=http://127.0.0.1:9222"
  ]
}
```

**참고:**
- Host에서 Chrome을 `--remote-debugging-port=9222`로 시작해야 함
- SSH 서버가 Host에 실행 중이어야 함 (Windows OpenSSH 또는 WSL2 내 SSH)
- GitHub Issue #131, #225, #328, #139 관련 공식 workaround

---

## WSLg (GUI) 문제

### WSLg가 작동하지 않음

**증상:**
- `$DISPLAY` 환경 변수가 비어있거나 설정되지 않음
- GUI 앱이 시작되지 않음
- Chrome 창이 나타나지 않음

**진단:**
```bash
echo $DISPLAY              # :0 또는 :1이 표시되어야 함
echo $WAYLAND_DISPLAY      # wayland-0 또는 유사한 값
xeyes                      # X11 테스트 (설치: sudo apt install x11-apps)
```

**해결 방법:**

1. **WSL 업데이트** (Windows PowerShell 관리자 권한으로 실행)
   ```powershell
   wsl --update
   wsl --version    # 버전 확인 (2.0.0+ 이어야 함)
   wsl --shutdown
   ```

2. **Windows 버전 확인**
   - WSLg는 Windows 11 또는 Windows 10 22H2+ 필요
   - 확인: 설정 > 시스템 > 정보

3. **WSL 배포판 재설치** (업데이트로 해결 안 될 경우)
   ```powershell
   # 데이터를 먼저 백업하세요!
   wsl --unregister Ubuntu
   wsl --install Ubuntu
   ```

4. **수동 DISPLAY 설정** (임시 해결책)
   ```bash
   export DISPLAY=:0
   # 영구 적용을 위해 ~/.bashrc에 추가
   echo 'export DISPLAY=:0' >> ~/.bashrc
   ```

---

## Node.js 및 npm 문제

### 설치 후 Node/npm 명령을 찾을 수 없음

**문제:**
```bash
$ node --version
bash: node: command not found
```

**해결 방법:**

1. **셸 설정 다시 로드**
   ```bash
   source ~/.bashrc
   # 또는 터미널 재시작
   ```

2. **수동으로 NVM 로드**
   ```bash
   export NVM_DIR="$HOME/.nvm"
   [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
   ```

3. **NVM 설치 확인**
   ```bash
   # NVM이 설치되어 있는지 확인
   ls -la ~/.nvm

   # 필요시 재설치
   bash scripts/install-nodejs.sh
   ```

### npm 글로벌 패키지를 찾을 수 없음

**문제:**
```bash
$ claude
bash: claude: command not found
```

**해결 방법:**

1. **npm 글로벌 경로 확인**
   ```bash
   npm config get prefix
   # /home/user/.npm-global이어야 함
   ```

2. **PATH 수정**
   ```bash
   echo $PATH | grep npm-global
   # 없다면 ~/.bashrc에 추가:
   echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

3. **패키지 재설치**
   ```bash
   npm install -g @anthropic-ai/claude-code
   npm install -g chrome-devtools-mcp@latest
   ```

---

## SSH 키 문제

### GitHub에서 SSH 키가 작동하지 않음

**문제:**
- `git push`가 인증 에러로 실패
- `ssh -T git@github.com` 실패

**해결 방법:**

1. **SSH 키가 에이전트에 추가되었는지 확인**
   ```bash
   ssh-add -l
   # 비어있다면 키 추가:
   ssh-add ~/.ssh/id_ed25519
   # 또는
   ssh-add ~/.ssh/id_rsa
   ```

2. **GitHub에 키 등록 확인**
   ```bash
   # 공개 키 확인
   cat ~/.ssh/id_ed25519.pub
   # 복사하여 GitHub에 추가: https://github.com/settings/keys
   ```

3. **GitHub 연결 테스트**
   ```bash
   ssh -T git@github.com
   # "Hi username! You've successfully authenticated..." 표시되어야 함
   ```

4. **SSH 권한 수정**
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_*
   chmod 644 ~/.ssh/id_*.pub
   ```

### MD5 vs SHA256 지문

**참고:** GitHub는 이제 기본적으로 MD5가 아닌 SHA256 지문을 사용합니다.

```bash
# SHA256 지문 보기 (GitHub 기본)
ssh-keygen -lf ~/.ssh/id_ed25519

# MD5 지문 보기 (레거시)
ssh-keygen -E md5 -lf ~/.ssh/id_ed25519
```

---

## 네트워크 및 포트 문제

### 포트가 이미 사용 중

**문제:**
```
Error: Port 9222 is already in use
```

**해결 방법:**

1. **포트를 사용 중인 프로세스 확인**
   ```bash
   lsof -i :9222
   netstat -tuln | grep 9222
   ```

2. **기존 Chrome 프로세스 종료**
   ```bash
   pkill -f 'chrome.*remote-debugging-port=9222'
   ```

3. **다른 포트 사용**
   ```bash
   export CHROME_DEBUG_PORT=9223
   bash scripts/start-chrome-debug.sh
   # MCP 설정도 맞게 업데이트
   ```

### localhost 연결 거부

**문제:**
- `curl http://localhost:9222` 실패
- MCP가 Chrome에 연결할 수 없음

**해결 방법:**

1. **Chrome 실행 확인**
   ```bash
   ps aux | grep chrome | grep remote-debugging
   ```

2. **Chrome 시작 대기**
   ```bash
   # Chrome이 초기화되는데 5-10초 소요될 수 있음
   sleep 5
   curl http://localhost:9222/json/version
   ```

3. **네트워크 미러링 활성화** (Windows 11)
   ```ini
   # %USERPROFILE%\.wslconfig 편집
   [wsl2]
   networkingMode=mirrored
   ```
   ```powershell
   # PowerShell에서
   wsl --shutdown
   # WSL 재시작
   ```

4. **방화벽 확인**
   ```bash
   # WSL2는 가상 네트워크 어댑터 사용
   # Windows 방화벽이 localhost 연결을 허용하는지 확인
   ```

---

## 일반 WSL2 문제

### WSL2가 느리거나 응답 없음

**해결 방법:**

1. **WSL2 메모리 증가** (`%USERPROFILE%\.wslconfig`에서)
   ```ini
   [wsl2]
   memory=8GB
   processors=4
   ```

2. **WSL 재시작**
   ```powershell
   wsl --shutdown
   ```

3. **Windows 업데이트 확인**
   - Windows가 최신 상태인지 확인
   - 최신 WSL 업데이트 설치

### 파일 시스템 성능

**권장 사항:**

1. **개발에는 Linux 파일 시스템 사용**
   ```bash
   # /home/user/에서 작업 (빠름)
   # /mnt/c/에서는 작업하지 않기 (느림)
   ```

2. **필요시 Windows 파일 접근**
   ```bash
   # Windows C: 드라이브
   cd /mnt/c/Users/YourName/

   # 하지만 저장소는 Linux 파일시스템에 클론
   cd ~
   git clone git@github.com:user/repo.git
   ```

---

## 진단 명령어

### 빠른 환경 확인

```bash
# check-dev-env 함수 사용
check-dev-env

# 또는 수동으로:
node --version
npm --version
google-chrome --version
echo $DISPLAY
curl http://localhost:9222/json/version
ssh -T git@github.com
```

### Chrome MCP 디버깅

```bash
# MCP 설정에 로그 파일 추가
{
  "args": [
    "chrome-devtools-mcp@latest",
    "--browserUrl=http://localhost:9222",
    "--log-file=/tmp/chrome-mcp.log"
  ]
}

# 로그 확인
tail -f /tmp/chrome-mcp.log
```

### 시스템 정보

```bash
# WSL 버전
wsl --version      # (PowerShell에서)

# WSL 배포판 버전
cat /etc/os-release

# 커널 버전
uname -r

# WSL2 확인
grep -i microsoft /proc/version
```

---

## 도움말 리소스

### 유용한 자료

- **Chrome DevTools MCP GitHub**: https://github.com/ChromeDevTools/chrome-devtools-mcp
  - Issue #131 (WSL2): https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131
  - Issue #225 (Headless): https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225

- **Cursor Forum WSL2 가이드**: https://forum.cursor.com/t/complete-guide-setting-up-mcp-tools-with-browser-extensions-in-wsl2/109614

- **WSL 문서**: https://docs.microsoft.com/en-us/windows/wsl/

- **MCP 문서**: https://modelcontextprotocol.io/

### 이슈 보고 시

이슈를 보고할 때 다음 정보를 포함하세요:

1. **시스템 정보**
   ```bash
   wsl --version
   cat /etc/os-release
   node --version
   google-chrome --version
   echo $DISPLAY
   ```

2. **에러 메시지** (전체 출력)

3. **재현 단계**

4. **시도한 해결 방법** (이 가이드에서)

---

## 알려진 제한사항

1. **WSL2에서 Chrome 감지** - --browserUrl 해결책 사용
2. **헤드리스 모드 문제** - 외부 Chrome 인스턴스 사용
3. **네트워크 격리** - Windows 11에서 네트워크 미러링 활성화
4. **GUI 성능** - WSLg가 네이티브 Linux보다 느릴 수 있음
5. **파일 시스템 속도** - Linux 파일시스템 사용, /mnt/c/ 사용 안 함

---

## 빠른 수정 체크리스트

문제가 발생하면:

- [ ] 셸 다시 로드: `source ~/.bashrc`
- [ ] WSLg 확인: `echo $DISPLAY`
- [ ] Chrome 실행 확인: `ps aux | grep chrome`
- [ ] 포트 테스트: `curl http://localhost:9222/json/version`
- [ ] PATH 확인: `echo $PATH`
- [ ] WSL 업데이트: `wsl --update` (PowerShell)
- [ ] WSL 재시작: `wsl --shutdown` (PowerShell)
- [ ] 로그 확인: `tail -f /tmp/chrome-mcp.log`
- [ ] 진단 실행: `check-dev-env`

---

*최종 업데이트: GitHub Issues #131, #225 및 커뮤니티 솔루션 기반 (2025년 기준)*
