# 🌸 Ryllis

**R**eact-**Y**ield **L**ightweight **L**ogic **I**ntegration **S**ystem

Anemone 프레임워크를 기반으로 만들어진 현대적이고 강력한 위키 엔진 + 블로그 플랫폼

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Go](https://img.shields.io/badge/Go-1.24+-00ADD8.svg)
![React](https://img.shields.io/badge/React-19-61DAFB.svg)

---

## ✨ 주요 특징

### 🚀 고성능 아키텍처
- **UDP 기반 RSock 프로토콜**: 초저지연 모듈 간 통신
- **모듈형 마이크로서비스**: Engine, Renderer, Gateway 독립 운영
- **SSR (Server-Side Rendering)**: React 19 기반 서버 사이드 렌더링
- **효율적인 캐싱**: 템플릿 및 데이터 캐싱으로 빠른 응답

### 📝 위키 + 블로그
- **위키 페이지**: 계층 구조, 버전 관리, 히스토리 추적
- **블로그 포스트**: 카테고리, 태그, 조회수 관리
- **나무마크 지원**: 나무위키 스타일 마크업 언어
- **전체 검색**: 위키 + 블로그 통합 검색

### 🔐 강력한 인증 시스템
- **JWT 기반 인증**: 안전한 토큰 기반 인증
- **세밀한 권한 관리**: 사용자별, 문서별 권한 제어
- **역할 기반 접근 제어 (RBAC)**: Admin, Editor, Viewer 역할
- **보호된 문서**: 문서별 읽기/쓰기 권한 설정

### 🎨 현대적인 UI/UX
- **React 19**: 최신 React 기반 SPA
- **Tailwind CSS**: 반응형 디자인
- **shadcn/ui**: 아름다운 컴포넌트
- **다크 모드 지원**: 눈이 편안한 다크 테마

---

## 🏗️ 시스템 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                         Client                              │
│                      (브라우저)                             │
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTP :8080
                            ↓
                  ┌─────────────────────┐
                  │     @gateway/       │
                  │   (HTTP 서버)       │
                  │   라우팅 & 검증     │
                  └──────────┬──────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
        engine.rsock                  renderer.rsock
        (UDP :9001)                   (UDP :9002)
              │                             │
              ↓                             ↓
    ┌──────────────────┐          ┌──────────────────┐
    │    @engine/      │          │   @renderer/     │
    │  (비즈니스 로직) │◄─────────│  (React SSR)     │
    │  데이터베이스    │  데이터   │  템플릿 렌더링   │
    └──────────────────┘  요청    └──────────────────┘
              │
              ↓
    ┌──────────────────┐
    │   PostgreSQL     │
    │   (데이터베이스) │
    └──────────────────┘

    @vendor/ (공통 모듈)
    - rsock (UDP 소켓 프로토콜)
    - http (HTTP 클라이언트)
    - db (데이터베이스 연결)

    @site/ (사이트 선언)
    - .ruststx 파일 파싱
    - 라우트 레지스트리
```

---

## 🎯 핵심 모듈

### 1. Engine (엔진)
- **역할**: 핵심 비즈니스 로직
- **포트**: UDP 9001
- **기능**:
  - 위키/블로그 CRUD
  - 사용자 인증 (JWT)
  - 권한 관리 (ACL)
  - 데이터베이스 연동
  - 검색 기능

### 2. Renderer (렌더러)
- **역할**: 프론트엔드 렌더링
- **포트**: UDP 9002
- **기술**: React 19 + Vite
- **기능**:
  - SSR (Server-Side Rendering)
  - 정적 파일 서빙
  - 템플릿 캐싱
  - Backend Processed Rendering (BPR)

### 3. Gateway (게이트웨이)
- **역할**: HTTP 요청 처리
- **포트**: HTTP 8080
- **기능**:
  - HTTP 서버 운영
  - 모듈 간 라우팅
  - 응답 검증
  - 로깅 & 모니터링

---

## 🚀 빠른 시작

### 사전 요구사항

- Go 1.24+
- Node.js 18+
- PostgreSQL 13+

### 1. 데이터베이스 설정

```bash
# PostgreSQL 데이터베이스 생성
sudo -u postgres createdb blogs

# 스키마 초기화
sudo -u postgres psql blogs < /srv/zuzunza/ryllis/db_schema.sql
```

### 2. 프로젝트 빌드

```bash
cd /srv/zuzunza/ryllis

# Makefile로 전체 빌드 (권장)
make build

# 또는 수동 빌드
cd renderer/react && npm install && npm run build
cd ../../engine && go build -o ../bin/anemone-engine
cd ../renderer && go build -o ../bin/anemone-renderer
cd ../gateway && go build -o ../bin/anemone-gateway
```

### 3. 서비스 실행

```bash
# Makefile 사용 (권장)
make dev

# 또는 수동 실행
# 터미널 1: Engine
./bin/anemone-engine > logs/engine.log 2>&1 &

# 터미널 2: Renderer
./bin/anemone-renderer > logs/renderer.log 2>&1 &

# 터미널 3: Gateway
./bin/anemone-gateway
```

### 4. 브라우저 접속

```
http://localhost:8080
```

---

## 📖 사용 가이드

### 위키 페이지 작성

1. **새 페이지 생성**: `/wiki` → "새 페이지" 버튼
2. **나무마크 작성**:
   ```
   == 제목 ==
   === 소제목 ===
   
   '''굵게''' ''기울임'' ~~취소선~~
   
   [[링크:다른_페이지]]
   [[https://example.com|외부 링크]]
   
   * 목록 1
   * 목록 2
   
   {{{#!syntax python
   def hello():
       print("Hello, Ryllis!")
   }}}
   ```
3. **저장 & 버전 관리**: 자동 버전 추적

### 블로그 포스트 작성

1. **새 포스트**: `/blog` → "새 포스트" 버튼
2. **마크다운 작성**:
   ```markdown
   # 제목
   ## 소제목
   
   **굵게** *기울임*
   
   - 목록
   - 항목
   
   ```code
   console.log('Hello');
   ```
   ```
3. **카테고리 & 태그**: 분류 및 검색 최적화

### 사용자 관리

```bash
# 관리자 계정 생성 (첫 실행 시)
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "secure_password",
    "email": "admin@example.com",
    "role": "admin"
  }'
```

### 권한 관리

- **Admin**: 모든 권한
- **Editor**: 문서 생성/수정
- **Viewer**: 읽기 전용

---

## 🛠️ 개발

### 프로젝트 구조

```
ryllis/
├── bin/                    # 빌드된 바이너리
├── engine/                 # 백엔드 엔진
│   ├── main.go            # 메인 진입점
│   ├── database.go        # DB 연결
│   ├── auth.go            # 인증 로직
│   ├── handler/           # API 핸들러
│   └── models/            # 데이터 모델
├── renderer/              # 프론트엔드 렌더러
│   ├── main.go           # 렌더러 서버
│   ├── ssr.go            # SSR 로직
│   └── react/            # React 앱
│       ├── src/
│       │   ├── pages/    # 페이지 컴포넌트
│       │   ├── components/  # UI 컴포넌트
│       │   └── utils/    # 유틸리티
│       └── dist/         # 빌드 결과물
├── gateway/               # HTTP 게이트웨이
│   └── main.go
├── site/                  # 사이트 선언
│   └── sites/
│       └── main.ruststx  # 라우트 정의
├── vendor/                # 공통 모듈
│   ├── rsock/            # UDP 소켓
│   ├── http/             # HTTP 클라이언트
│   └── db/               # DB 유틸리티
└── Makefile              # 빌드 자동화
```

### 개발 명령어

```bash
# 전체 빌드
make build

# 개발 모드 (Hot Reload)
make dev

# React 개발 서버
cd renderer/react && npm run dev

# 서비스 정지
make stop

# 로그 확인
tail -f logs/engine.log
tail -f logs/renderer.log
tail -f logs/gateway.log

# 데이터베이스 초기화
psql blogs < db_reset.sql
```

### API 테스트

```bash
# 블로그 목록
curl http://localhost:8080/api/blog/list

# 위키 페이지 조회
curl http://localhost:8080/api/wiki/get?slug=home

# 검색
curl http://localhost:8080/api/search?q=keyword
```

---

## 🔌 RSock 프로토콜

Ryllis의 핵심 통신 프로토콜

### 패킷 구조

#### 요청 패킷
```
[2 bytes: route length][n bytes: route][m bytes: payload]
```

#### 응답 패킷
```
[2 bytes: status code][2 bytes: error length][n bytes: error][data]
```

### 예제

```go
// Gateway → Engine 요청
resp, err := sock.Send("127.0.0.1:9001", "/api/wiki/get", jsonPayload)

// Engine에서 핸들러 등록
rsock.Register("/api/wiki/get", func(req *Request) (*Response, error) {
    // 위키 페이지 조회 로직
    return &Response{StatusCode: 200, Data: wikiData}, nil
})
```

---

## 📊 데이터베이스 스키마

### 주요 테이블

#### blog_posts (블로그 포스트)
```sql
- id (SERIAL PRIMARY KEY)
- title (VARCHAR)
- content (TEXT)
- author (VARCHAR)
- category (VARCHAR)
- tags (TEXT[])
- view_count (INTEGER)
- is_published (BOOLEAN)
- created_at, updated_at (TIMESTAMP)
```

#### wiki_pages (위키 페이지)
```sql
- id (SERIAL PRIMARY KEY)
- title (VARCHAR)
- slug (VARCHAR UNIQUE)
- content (TEXT)
- editor (VARCHAR)
- version (INTEGER)
- parent_id (INTEGER)
- view_count (INTEGER)
- is_protected (BOOLEAN)
- protection_level (VARCHAR)
- tags (TEXT[])
- created_at, updated_at (TIMESTAMP)
```

#### users (사용자)
```sql
- id (SERIAL PRIMARY KEY)
- username (VARCHAR UNIQUE)
- email (VARCHAR UNIQUE)
- password_hash (VARCHAR)
- role (VARCHAR)
- created_at (TIMESTAMP)
```

#### acl (접근 제어 목록)
```sql
- id (SERIAL PRIMARY KEY)
- resource_type (VARCHAR)
- resource_id (INTEGER)
- user_id (INTEGER)
- permission (VARCHAR)
```

---

## 🔒 보안

### 인증
- **JWT 토큰**: 안전한 인증
- **BCrypt 해싱**: 비밀번호 암호화
- **토큰 만료**: 자동 세션 관리

### 권한
- **ACL 시스템**: 문서별 권한 제어
- **역할 기반**: Admin, Editor, Viewer
- **보호된 문서**: 읽기/쓰기 제한

### 네트워크
- **로컬 소켓**: 127.0.0.1만 허용
- **입력 검증**: SQL 인젝션, XSS 방어
- **Rate Limiting**: DDoS 방어 (예정)

---

## 📈 성능

### 벤치마크 (예상)

| 지표 | 값 |
|------|-----|
| 평균 응답 시간 | < 10ms |
| 최대 처리량 | 10,000+ req/s |
| 메모리 사용량 | < 100MB |
| 동시 연결 | 무제한 (UDP) |

### 최적화
- UDP 소켓으로 TCP 오버헤드 제거
- 템플릿 캐싱
- 데이터베이스 인덱싱
- 고루틴 병렬 처리

---

## 🔧 설정

### 환경 변수

```bash
# 데이터베이스
export DATABASE_URL="host=localhost port=5432 user=postgres password=yourpass dbname=blogs sslmode=disable"

# JWT
export JWT_SECRET="your-secret-key-here"

# 서버 포트
export GATEWAY_PORT=8080
export ENGINE_PORT=9001
export RENDERER_PORT=9002
```

### .ruststx 라우트 설정

```ruststx
@site {
  name: "Ryllis"
  description: "Wiki + Blog Platform"
}

@route GET / {
  handler: "HomeHandler"
  template: "index.html"
}

@route GET /wiki/:slug {
  handler: "WikiDetailHandler"
  template: "index.html"
  middleware: "auth"
}
```

---

## 🚧 로드맵

### v1.1 (예정)
- [ ] WebSocket 지원 (실시간 협업 편집)
- [ ] 파일 업로드 (이미지, 문서)
- [ ] 댓글 시스템
- [ ] RSS 피드

### v1.2 (예정)
- [ ] 다국어 지원 (i18n)
- [ ] 테마 시스템
- [ ] 플러그인 아키텍처
- [ ] 전체 텍스트 검색 (ElasticSearch)

### v2.0 (예정)
- [ ] 분산 환경 지원
- [ ] Redis 캐싱
- [ ] 모니터링 대시보드
- [ ] GraphQL API

---

## 📚 문서

- [빠른 시작 가이드](ryllis/QUICKSTART.md)
- [설치 가이드](ryllis/SETUP.md)
- [기술 명세서](ryllis/TECHNICAL_SPEC.md)
- [프레임워크 가이드](ryllis/FRAMEWORK.md)
- [마이그레이션 요약](ryllis/MIGRATION_SUMMARY.md)
- [API 테스트](ryllis/API_TEST.md)
- [인증 설정](ryllis/AUTHENTICATION_SETUP.md)

---

## 🤝 기여

이슈 및 Pull Request를 환영합니다!

### 기여 방법

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 라이선스

MIT License

Copyright (c) 2025 Ryllis

---

## 💬 커뮤니티

- **GitHub Issues**: 버그 리포트, 기능 제안
- **Discussions**: 질문, 아이디어 공유

---

## 🙏 감사의 말

Ryllis는 다음 오픈소스 프로젝트에 기반합니다:

- **Anemone Framework**: 모듈형 마이크로서비스 아키텍처
- **React**: UI 라이브러리
- **Go**: 백엔드 언어
- **PostgreSQL**: 데이터베이스
- **Vite**: 빌드 도구
- **Tailwind CSS**: 스타일링
- **shadcn/ui**: UI 컴포넌트

---

<div align="center">

**Ryllis** - React-Yield Lightweight Logic Integration System 🌸

*빠르고, 현대적이고, 확장 가능한 위키 엔진*

[시작하기](ryllis/QUICKSTART.md) · [문서](ryllis/TECHNICAL_SPEC.md) · [기여하기](#기여)

Made with ❤️ by the Ryllis team

</div>
