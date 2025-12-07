# 🫖 주전자닷컴 개발 문서 & 운영 가이드라인 문서

> **창작자를 위한 통합 크리에이티브 플랫폼**

주전자닷컴은 플래시 애니메이션, 자작 게임, 웹툰, 아트워크 등 다양한 창작물을 공유하고 소통하는 국내 최대 규모의 창작 커뮤니티입니다. v4 업데이트를 통해 더욱 강력한 기능과 안정적인 서비스를 제공합니다.

---

## 🌟 주요 서비스 및 기능 안내

### 1. 🎨 크리에이티브 콘텐츠
- **플래시(Flash) & HTML5**: 고전 플래시 애니메이션부터 최신 HTML5 게임까지 완벽 지원 (Ruffle 에뮬레이터 탑재).
- **아트워크 & 웹툰**: 고화질 일러스트와 연재형 웹툰을 위한 전용 뷰어 및 갤러리.
- **자작 게임**: 인디 개발자를 위한 게임 업로드 및 배포 플랫폼.
- **비디오**: Cloudflare Stream 기반의 고화질 비디오 스트리밍 서비스.

### 2. 🏰 커뮤니티 & 소셜
- **실시간 소통**: Socket.IO 기반의 실시간 채팅 및 알림 시스템.
- **통합 게시판**: 자유, 유머, 강좌, 질문답변 등 주제별 커뮤니티 공간.
- **마이페이지**: 나만의 프로필 꾸미기, 채널 아트(배너) 설정, 활동 내역 관리.
- **쪽지 & 알림**: 회원 간 비공개 메시지 및 활동 알림 기능.

### 3. 🛍️ 포인트 & 스토어
- **포인트 시스템**: 활동에 따라 적립되는 포인트로 다양한 아이템 구매.
- **아이템 샵**: 아바타, 닉네임 효과, 아이콘 등 커뮤니티 아이템 판매.

### 4. 🛡️ 보안 및 편의성
- **CDN 가속**: 전 세계 어디서나 빠른 로딩 속도 (Cloudflare R2 + MinIO 하이브리드).
- **미디어 암호화**: 창작자의 콘텐츠 보호를 위한 URL 및 메타데이터 암호화 전송.
- **반응형 웹**: PC, 태블릿, 모바일 등 모든 기기에서 최적화된 화면 제공.

---

## 🏗️ SuperTrinity Core (엔진 및 기술)

이 문서는 주전자닷컴 v4의 핵심 엔진인 **SuperTrinity Core**의 기술적 명세를 포함합니다.

### 아키텍처 개요
SuperTrinity는 고성능 Python 백엔드, 최신 Next.js 프론트엔드, 그리고 Rust 기반의 미디어 처리 엔진이 결합된 하이브리드 아키텍처입니다.

![Backend](https://img.shields.io/badge/backend-FastAPI-green.svg)
![Frontend](https://img.shields.io/badge/frontend-Next.js_16-black.svg)
![Engine](https://img.shields.io/badge/engine-Rust_Vectorman-orange.svg)

### 주요 기술 특징
1.  **Vectorman Engine (Rust)**
    -   SWF/Flash 파일 파싱 및 썸네일 고속 추출.
    -   C FFI를 통한 `swftools` 라이브러리 연동.
    -   미디어 리소스 암호화 및 보안 토큰 생성.

2.  **Next.js 16 Frontend**
    -   App Router 기반의 모던 아키텍처.
    -   `Native-Frontend` 헤더를 통한 클라이언트 무결성 검증.
    -   React 19 최신 기능 활용 (Server Actions 등).

3.  **FastAPI Backend**
    -   비동기 처리를 통한 고성능 API 서비스.
    -   Git Flow 전략에 따른 안정적인 배포 파이프라인.
    -   `ver.json` 매니페스트를 이용한 버전 관리.

### 🛠️ 기술 스택

| 분류 | 기술 | 비고 |
|------|------|------|
| **Backend** | Python 3.12, FastAPI | API 서버 코어 |
| **Frontend** | Next.js 16, React 19 | 사용자 인터페이스 |
| **Engine** | Rust, Axum, swftools | 미디어 처리 엔진 |
| **Infra** | Docker, Cloudflare | 배포 및 CDN |

---

## 🔧 설치 및 실행 방법

### 1. 환경 설정
프로젝트 루트에 `.env` 파일을 생성하고 필요한 환경 변수(DB 접속 정보, JWT 키 등)를 설정합니다.

### 2. 실행 명령어

**개발 모드 (전체)**
```bash
npm run dev
```

**백엔드만 실행**
```bash
npm run dev:backend
```

**프론트엔드만 실행**
```bash
npm run dev:frontend
```

**Vectorman (Rust) 빌드**
```bash
cd etc/vectorman && cargo build --release
```

---

## 📚 문서 (Documentation)

자세한 운영 규칙 및 기술 가이드는 [Wiki](https://github.com/zuzunza-com/zuzunza/wiki)에서 확인하세요.

- **[커뮤니티 이용 규칙](https://github.com/zuzunza-com/zuzunza/wiki/Community-Guidelines)**
- **[개인정보 처리방침](https://github.com/zuzunza-com/zuzunza/wiki/Privacy-Policy)**
- **[개발팀 규칙 및 기여 가이드](https://github.com/zuzunza-com/zuzunza/wiki/Development-Guidelines)**
- **[기술 문서: CDN 가이드](https://github.com/zuzunza-com/zuzunza/wiki/CDN_FALLBACK_GUIDE)**

---

<div align="center">
  <b>Zuzunza Development Team</b><br>
  Powered by SuperTrinity Core
</div>
