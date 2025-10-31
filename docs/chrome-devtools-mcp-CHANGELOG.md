# chrome-devtools-mcp 변경 이력

이 문서는 `chrome-devtools-mcp` 패키지의 주요 버전별 변경사항을 WSL2 사용자 관점에서 정리한 것입니다.

> **English version**: See [en/chrome-devtools-mcp-CHANGELOG.md](en/chrome-devtools-mcp-CHANGELOG.md)

> **공식 저장소**: https://github.com/ChromeDevTools/chrome-devtools-mcp

---

## 목차

- [현재 권장 버전](#현재-권장-버전)
- [WSL2 사용자를 위한 핵심 정보](#wsl2-사용자를-위한-핵심-정보)
- [버전 히스토리](#버전-히스토리)
  - [v0.9.0 (최신)](#v090-2025년-10월-22일---현재-최신)
  - [v0.8.1](#v081-2025년-10월-13일)
  - [v0.8.0](#v080-2025년-10월-10일)
  - [v0.7.1](#v071-2025년-10월-10일)
  - [v0.7.0](#v070-2025년-10월-10일)
- [향후 예정 (v0.10.0)](#향후-예정-v0100)
- [WSL2 관련 개선사항 요약](#wsl2-관련-개선사항-요약)

---

## 현재 권장 버전

**최신 안정 버전**: `v0.9.0` (2025년 10월 22일)

**WSL2 사용자 권장**: `v0.9.0+`
- 향상된 안정성
- WebSocket endpoint 지원
- 공식 VM/WSL2 문서 포함
- 의존성 번들링으로 설치 신뢰성 향상

**설치 방법**:
```bash
# npx 사용 (권장 - 항상 최신 버전)
npx chrome-devtools-mcp@latest

# 또는 글로벌 설치
npm install -g chrome-devtools-mcp@latest
```

---

## WSL2 사용자를 위한 핵심 정보

### ⚠️ 중요: Issue #131 및 #225의 실제 상태

**Issue #131: WSL2에서 Chrome 감지 불가**
- 상태: ✅ CLOSED (Workaround 공식 문서화)
- **해결 여부**: ❌ 근본 해결 안 됨 (아키텍처 제한)
- **현재 상황**: `--browserUrl` 또는 `--wsEndpoint` 사용 필요

**Issue #225: headless=false 프로토콜 에러**
- 상태: ✅ CLOSED (v0.7.0+에서 안정성 향상)
- **해결 여부**: ⚠️ 외부 Chrome 사용 시 우회 가능
- **현재 상황**: Puppeteer 개선으로 연결 안정성 향상

### 공식 권장 방법

v0.9.0 기준 WSL2에서의 권장 사용 방법:

**방법 1: browserUrl (간단, 권장)**
```bash
# Chrome 시작
google-chrome --remote-debugging-port=9222 &

# MCP 설정
npx chrome-devtools-mcp@latest --browserUrl=http://127.0.0.1:9222
```

**방법 2: WebSocket Endpoint (v0.9.0+, 고급)**
```bash
# WebSocket URL 확인
curl http://localhost:9222/json/version

# MCP 설정
npx chrome-devtools-mcp@latest --wsEndpoint=ws://127.0.0.1:9222/devtools/browser/<id>
```

**방법 3: SSH Tunneling (VM-to-Host)**
```bash
# WSL2/VM에서 Host로 터널링
ssh -N -L 127.0.0.1:9222:127.0.0.1:9222 user@host-ip

# 그 후 browserUrl 사용
npx chrome-devtools-mcp@latest --browserUrl=http://127.0.0.1:9222
```

---

## 버전 히스토리

### v0.9.0 (2025년 10월 22일) - **현재 최신**

**WSL2/VM 관련 주요 기능** ⭐

#### 1. WebSocket Endpoint 지원 (#404)
- 새로운 `--wsEndpoint` 파라미터 추가
- 직접 WebSocket 연결 지원
- 커스텀 헤더 지원 (인증 토큰 등)
- `--browserUrl`의 대안으로 사용 가능

**사용 예시**:
```bash
npx chrome-devtools-mcp@latest \
  --wsEndpoint=ws://127.0.0.1:9222/devtools/browser/<id> \
  --wsHeaders='{"Authorization":"Bearer YOUR_TOKEN"}'
```

#### 2. 공식 VM-to-Host 문서 추가 (#399)
- WSL2/VM 시나리오 공식 인정
- SSH tunneling 방법 문서화
- Issue #131, #225, #328, #139 참조

#### 3. 의존성 번들링 (#450, #417, #414, #409)
- 모든 의존성을 하나로 번들링
- 설치 문제 감소
- npm 캐시 이슈 해결

#### 4. 기타 주요 기능

**도구 카테고리 설정** (#454)
```bash
# 특정 카테고리만 활성화
--categoryEmulation=false  # 에뮬레이션 비활성화
--categoryPerformance=false  # 성능 도구 비활성화
--categoryNetwork=false  # 네트워크 도구 비활성화
```

**데이터 지속성 향상** (#419, #452, #411)
- 최근 3개 네비게이션 저장
- 이전 네비게이션의 콘솔 메시지 지원
- 더 나은 히스토리 추적

**네트워크 요청 개선**
- 안정적인 Request ID (#375, #382)
- Request/Response body 처리 개선 (#446)

**기타 개선사항**
- 콘솔 메시지 필터링 및 페이지네이션 (#387)
- Verbose 스냅샷 (#388)
- 프레임 평가 지원 (#443)

#### Breaking Changes
없음 - 이전 버전과 완벽 호환

---

### v0.8.1 (2025년 10월 13일)

**Puppeteer 업데이트** ⭐

#### Puppeteer v24.24.1로 업데이트 (#370)
- Issue #322 해결 (puppeteer/puppeteer#14304)
- Issue #292 해결 (puppeteer/puppeteer#14307, #14306)
- 전반적인 안정성 향상
- **WSL2 영향**: 연결 안정성 및 에러 처리 개선

#### 기타 개선사항
- Dialog 처리 개선 (#366, #362)
- 네비게이션 에러 메시지 향상 (#321)

#### Breaking Changes
없음

---

### v0.8.0 (2025년 10월 10일)

**Chrome 커스터마이징**

#### 커스텀 Chrome 인수 지원 (#338)
- Chrome에 추가 플래그 전달 가능
- **WSL2 영향**: WSL2 특화 Chrome 플래그 사용 가능

**사용 예시**:
```bash
npx chrome-devtools-mcp@latest \
  --chromeArgs='["--disable-gpu","--no-sandbox"]'
```

#### Breaking Changes
없음

---

### v0.7.1 (2025년 10월 10일)

**문서 개선** 📝

#### 문서 업데이트 (#335)
- 콘솔 메시지 및 네트워크 요청이 마지막 네비게이션 이후부터 추적됨을 명확히 설명

#### Breaking Changes
없음

---

### v0.7.0 (2025년 10월 10일)

**주요 기능 추가**

#### 1. 오프라인 네트워크 에뮬레이션 (#326)
- `emulate_network` 명령에 오프라인 모드 추가
- 네트워크 단절 시나리오 테스트 가능

#### 2. Request/Response Body 캡처 (#267)
- HTTP 요청 및 응답 본문 캡처
- 디버깅 능력 대폭 향상

#### 3. 안정성 개선
- 성능 추적 요약 순서 수정 (#334)
- MCP 레지스트리 게시 수정 (#313)
- 기본 ProtocolTimeout 개선 (#315)

#### Breaking Changes
없음

---

## 향후 예정 (v0.10.0)

**참고**: v0.10.0은 개발 중이며 아직 릴리즈되지 않았습니다.

### 예정된 기능

1. **DevTools 통합 강화**
   - DevTools Elements 패널에서 선택된 DOM 노드 가져오기 (#486)
   - DevTools UI에서 네트워크 요청 검사 (#477)

2. **성능 및 제어 개선**
   - 이슈 필터링 및 집계
   - 캐시 제어 옵션으로 페이지 새로고침 (#485)
   - 스냅샷을 파일로 저장 (#463)

3. **추가 도구**
   - 키 입력 도구 (#458)

---

## WSL2 관련 개선사항 요약

### 타임라인

| 버전 | 날짜 | WSL2/VM 관련 변경사항 |
|------|------|---------------------|
| v0.7.0 | 2025-10-10 | 안정성 개선 (ProtocolTimeout) |
| v0.8.0 | 2025-10-10 | 커스텀 Chrome 인수 지원 |
| v0.8.1 | 2025-10-13 | Puppeteer v24.24.1 안정성 향상 |
| **v0.9.0** | **2025-10-22** | **WebSocket endpoint**, **공식 VM 문서**, 의존성 번들링 |

### 핵심 개선사항

✅ **v0.9.0의 주요 WSL2 개선**:
1. WebSocket endpoint 지원으로 연결 방법 다양화
2. VM-to-host SSH tunneling 공식 문서화
3. 의존성 번들링으로 설치 안정성 향상
4. 도구 카테고리 선택으로 리소스 최적화

⚠️ **여전히 필요한 것**:
- Chrome을 수동으로 시작해야 함 (자동 감지 불가)
- `--browserUrl` 또는 `--wsEndpoint` 필수
- WSLg GUI 지원 필요 (headful 모드 사용 시)

---

## 추가 정보

### 공식 문서
- **GitHub Repository**: https://github.com/ChromeDevTools/chrome-devtools-mcp
- **Releases**: https://github.com/ChromeDevTools/chrome-devtools-mcp/releases
- **Issues**: https://github.com/ChromeDevTools/chrome-devtools-mcp/issues

### WSL2 관련 주요 이슈
- **Issue #131**: WSL2 Chrome 감지 - https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/131
- **Issue #225**: Headless Protocol 에러 - https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/225
- **Issue #328**: VM 환경 지원 - https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/328
- **Issue #139**: Remote debugging - https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/139

### 이 레포지토리의 관련 문서
- [README.md](../README.md) - 전체 설치 가이드
- [troubleshooting.md](troubleshooting.md) - 문제 해결
- [mcp-config.json](../configs/mcp-config.json) - MCP 설정 예시

---

**마지막 업데이트**: 2025년 1월
**작성자**: WSL2 AI Dev Setup 레포지토리
