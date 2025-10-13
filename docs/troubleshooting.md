# 문제 해결 가이드

WSL2 개발 환경 설정 중 발생하는 일반적인 문제와 해결 방법입니다. GitHub 이슈 및 커뮤니티 포럼에서 검증된 솔루션을 기반으로 작성되었습니다.

> **English version**: See [en/troubleshooting.md](en/troubleshooting.md)

## 목차

1. [Chrome DevTools MCP 문제](#chrome-devtools-mcp-문제)
2. [WSLg (GUI) 문제](#wslg-gui-문제)
3. [Node.js 및 npm 문제](#nodejs-및-npm-문제)
4. [SSH 키 문제](#ssh-키-문제)
5. [네트워크 및 포트 문제](#네트워크-및-포트-문제)
6. [일반 WSL2 문제](#일반-wsl2-문제)

---

## Chrome DevTools MCP 문제

### Issue #131: WSL2에서 Chrome 감지 실패

**문제:**
- MCP가 WSL2 환경에서 Chrome 브라우저를 찾지 못함
- 에러: "Chrome executable not found"
- MCP가 WSL 내부만 확인하고 Windows Chrome을 인식하지 못함

**공식 이슈:** https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131

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

### Issue #225: headless=false 사용 시 프로토콜 에러

**문제:**
- 에러: `Protocol error (Target.setDiscoverTargets): Target closed`
- WSL2 Ubuntu에서 `headless: false` 설정 시 발생
- `headless: true`로 설정하면 작동함

**공식 이슈:** https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225

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
