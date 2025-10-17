# 🫖 주전자닷컴 (Zuzunza)

> **창작자를 위한 통합 커뮤니티 플랫폼**

주전자닷컴은 아티스트, 크리에이터, 게이머들이 모여 창작물을 공유하고 소통하는 종합 온라인 커뮤니티 플랫폼입니다.

![License](https://img.shields.io/badge/license-Private-red.svg)
![Platform](https://img.shields.io/badge/platform-Multi--Service-blue.svg)
![Status](https://img.shields.io/badge/status-Production-green.svg)

---

## 🎯 플랫폼 개요

주전자닷컴은 단순한 SNS를 넘어 **창작자 생태계를 위한 올인원 플랫폼**입니다. 

### 핵심 가치

- 🎨 **창작의 자유**: 이미지, 영상, 글, 게임 등 모든 형태의 창작물 지원
- 👥 **실시간 소통**: 통화, 채팅, 라이브 방송으로 언제나 연결
- 🎮 **즐거운 경험**: 게임 플랫폼과 커뮤니티의 완벽한 조화
- 🚀 **성장 지원**: 챌린지, 크루 시스템으로 창작자 성장 도모
- 🔒 **안전한 환경**: 세밀한 권한 관리와 콘텐츠 보호

---

## 🏢 플랫폼 구성

주전자닷컴은 여러 독립적인 서비스들이 유기적으로 연결된 멀티-서비스 플랫폼입니다.

### 1. 주전자 메인 플랫폼 (neoTrinity)

**창작자를 위한 통합 SNS 플랫폼**

#### 📸 콘텐츠 허브
- **아트워크 갤러리**: 고화질 이미지 업로드 및 전시
- **동영상 플랫폼**: Cloudflare Stream 기반 영상 스트리밍
- **커뮤니티 게시판**: 텍스트 포스트 및 토론

#### 👥 소셜 네트워킹
- **서버 시스템**: Discord 스타일 커뮤니티 서버
- **크루**: 같은 관심사를 가진 창작자 모임
- **팔로우 & 피드**: 개인화된 콘텐츠 큐레이션

#### 🎙️ 실시간 커뮤니케이션
- **1:1 통화**: 음성/영상 통화 (WebRTC)
- **그룹 통화**: 음성 채널에서 다중 참여자 통화
- **라이브 스트리밍**: 실시간 방송 및 시청자 채팅

#### 🎮 참여형 콘텐츠
- **챌린지 시스템**: 주제별 창작 챌린지 및 투표
- **XP & 레벨**: 활동 기반 경험치 및 보상 시스템

**기술 스택**: Next.js 15, TypeScript, NestJS, Supabase, Redis, Socket.IO

---

### 2. 키즈짱게임 (kidszzanggame)

**플래시게임 & HTML5 게임 플랫폼**

#### 게임 허브
- **다양한 게임**: 플래시게임 및 HTML5 게임 완벽 지원
- **실시간 채팅**: Ably 기반 게임별 채팅방
- **게임 관리**: 카테고리, 태그, 검색 기능

#### 커뮤니티
- **게임 게시판**: 게임별 공략 및 토론
- **사용자 프로필**: 게임 플레이 기록 및 통계
- **반응형 디자인**: 모바일 최적화

**기술 스택**: Next.js 16, React 19, TypeScript, Supabase, Ably, AWS S3

---

### 3. 주전자 위키 (Ryllis)

**차세대 위키 엔진 + 블로그 플랫폼** 🆕

#### 고성능 아키텍처
- **UDP 기반 RSock**: 초저지연 모듈 간 통신
- **모듈형 마이크로서비스**: Engine, Renderer, Gateway 독립 운영
- **React SSR**: React 19 기반 서버 사이드 렌더링

#### 위키 + 블로그
- **위키 페이지**: 계층 구조, 버전 관리, 히스토리 추적
- **블로그 포스트**: 카테고리, 태그, 조회수 관리
- **나무마크 지원**: 나무위키 스타일 마크업

#### 강력한 인증
- **JWT 기반**: 안전한 토큰 기반 인증
- **RBAC**: Admin, Editor, Viewer 역할
- **문서 보호**: 문서별 읽기/쓰기 권한

**기술 스택**: Go 1.24+, React 19, PostgreSQL, UDP RSock 프로토콜

**상태**: 🔄 개발 중 (NextJS 대체 예정)

---

### 4. 주요 지원 서비스

#### Discord Bot (YUKINA_BOT)
- 멤버 스텟 조회 (`/stats`)
- 팔로우 관리 (`/follow`, `/unfollow`)
- 작품 조회 (`/artwork`, `/artworks`, `/random-artwork`)
- AI 채팅 (`/chat`)

**기술**: Discord.js, Supabase

#### WebSocket Server
- 실시간 통신 인프라
- Socket.IO 기반
- 다중 서비스 연결

**기술**: Node.js, Socket.IO, TypeScript

#### Sysnox (시스템 모니터링)
- 보안 모니터링
- IP 차단 관리
- SELinux 로그 관리

**기술**: Node.js

#### Database Dumps
- 자동 백업 시스템
- 암호화된 덤프 파일
- Cron 기반 스케줄링

**기술**: Node.js, PostgreSQL

#### Shared Library
- Supabase 클라이언트 공유
- 프로젝트 간 코드 재사용
- 타입 정의 공유

**기술**: TypeScript

---

## 🏗️ 전체 아키텍처

```
                    ┌─────────────────────────────────┐
                    │         사용자 (브라우저)        │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────┴──────────────────┐
                    │                                 │
         ┌──────────▼─────────┐          ┌──────────▼─────────┐
         │   주전자 메인       │          │   키즈짱게임        │
         │  (neoTrinity)      │          │  (kidszzanggame)   │
         │  Next.js 15        │          │  Next.js 16        │
         └──────────┬─────────┘          └──────────┬─────────┘
                    │                               │
         ┌──────────┴─────────┐          ┌─────────┴─────────┐
         │  NestJS Server     │          │  WebSocket Server │
         │  Redis Sessions    │          │  Ably Realtime    │
         └──────────┬─────────┘          └─────────┬─────────┘
                    │                               │
                    └───────────────┬───────────────┘
                                    │
                         ┌──────────▼──────────┐
                         │   Supabase          │
                         │   PostgreSQL        │
                         │   Authentication    │
                         └──────────┬──────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
         ┌──────────▼────────┐  ┌──▼─────────┐  ┌─▼─────────┐
         │  Discord Bot      │  │  Sysnox    │  │  Dumps    │
         │  (YUKINA)         │  │  Security  │  │  Backup   │
         └───────────────────┘  └────────────┘  └───────────┘

         ┌─────────────────────────────────────────────────────┐
         │              🆕 차세대 아키텍처 (Ryllis)             │
         │                                                       │
         │  ┌──────────┐  ┌───────────┐  ┌──────────────┐     │
         │  │ Gateway  │◄─┤ Renderer  │◄─┤   Engine     │     │
         │  │ HTTP     │  │ React SSR │  │   Business   │     │
         │  │ :8080    │  │ UDP :9002 │  │   UDP :9001  │     │
         │  └──────────┘  └───────────┘  └──────┬───────┘     │
         │                                       │              │
         │                              ┌────────▼────────┐    │
         │                              │   PostgreSQL    │    │
         │                              └─────────────────┘    │
         └─────────────────────────────────────────────────────┘
```

---

## 🛠️ 기술 스택 요약

### Frontend
- **Framework**: Next.js 15/16, React 19
- **Language**: TypeScript 5.9+
- **Styling**: Tailwind CSS 4+
- **UI Components**: Radix UI, shadcn/ui
- **Animation**: Framer Motion

### Backend
- **Server**: NestJS, Next.js API Routes
- **Language**: Go 1.24+ (Ryllis), Node.js
- **Database**: PostgreSQL, Supabase
- **Cache**: Redis
- **Real-time**: Socket.IO, Ably

### Infrastructure
- **Storage**: Cloudflare R2, AWS S3
- **Streaming**: Cloudflare Stream
- **WebRTC**: Cloudflare Realtime
- **Container**: Docker, Docker Compose
- **Proxy**: Nginx, Apache2

### DevOps
- **Package Manager**: pnpm 10+
- **Build**: Turborepo, Vite
- **Monitoring**: Sysnox
- **Backup**: 자동 암호화 덤프

---

## 🚀 로드맵

### Phase 1: 기존 플랫폼 안정화 ✅
- [x] neoTrinity 메인 플랫폼 구축
- [x] kidszzanggame 게임 플랫폼 구축
- [x] Discord Bot 통합
- [x] WebSocket 인프라
- [x] 통합 인증 시스템 (Redis)

### Phase 2: Ryllis 위키 엔진 개발 🔄
- [x] RSock 프로토콜 구현
- [x] Engine, Renderer, Gateway 모듈
- [x] 나무마크 파서
- [x] JWT 인증 시스템
- [ ] 프로덕션 배포
- [ ] 성능 최적화

### Phase 3: NextJS → Ryllis 마이그레이션 📋
- [ ] neoTrinity 일부 기능 Ryllis로 이전
- [ ] kidszzanggame 일부 기능 Ryllis로 이전
- [ ] 기능 손상 없이 점진적 전환
- [ ] 성능 비교 및 튜닝

### Phase 4: 통합 및 확장 🔮
- [ ] 전체 플랫폼 Ryllis 기반 재구축
- [ ] 분산 환경 지원
- [ ] 고급 검색 (ElasticSearch)
- [ ] GraphQL API
- [ ] 모니터링 대시보드

---

## 📂 프로젝트 구조

```
zuzunza/
├── neotrinity/              # 주전자 메인 플랫폼 (Next.js 15)
│   ├── src/                 # 소스 코드
│   ├── infra/               # 인프라 설정
│   └── docker-compose.yml   # Docker 설정
│
├── kidszzanggame/           # 키즈짱게임 (Next.js 16)
│   ├── app/                 # Next.js App Router
│   ├── components/          # React 컴포넌트
│   └── supabase/            # 데이터베이스
│
├── ryllis/                  # 🆕 위키 엔진 (Go + React)
│   ├── engine/              # 백엔드 엔진 (Go)
│   ├── renderer/            # 프론트엔드 렌더러 (React)
│   ├── gateway/             # HTTP 게이트웨이
│   ├── site/                # 사이트 선언 (.ruststx)
│   └── vendor/              # 공통 모듈 (rsock, db, http)
│
├── discord-bot/             # Discord 봇 (YUKINA)
│   └── src/commands/        # 슬래시 커맨드
│
├── ws-server/               # WebSocket 서버
│   └── src/                 # Socket.IO 서버
│
├── shared-lib/              # 공유 라이브러리
│   └── src/                 # Supabase 클라이언트
│
├── sysnox/                  # 시스템 모니터링
│   └── lib/                 # 보안 및 로그 관리
│
├── dumps/                   # 데이터베이스 백업
│   ├── auto-dump.sh         # 자동 백업 스크립트
│   └── *.dump.encrypted     # 암호화된 덤프
│
├── gateway/                 # 게이트웨이 (Apache2/Nginx)
│   ├── apache2/             # Apache 설정
│   └── public/              # 정적 파일
│
├── blogs/                   # 레거시 블로그 (PHP)
│   └── ...                  # PHP 블로그 시스템
│
├── fallback-site/           # 폴백 사이트
│   └── index.php            # 오류 페이지
│
└── pnpm-workspace.yaml      # Monorepo 설정
```

---

## 🔧 개발 환경 설정

### 사전 요구사항

#### 주전자 메인 & 키즈짱게임
- Node.js 18+
- pnpm 10.11.0+
- Docker & Docker Compose

#### Ryllis 위키
- Go 1.24+
- Node.js 18+
- PostgreSQL 13+

### 설치 및 실행

```bash
# 1. 저장소 클론
git clone <repository-url>
cd zuzunza

# 2. 의존성 설치 (Monorepo)
pnpm install

# 3. 환경 변수 설정
# 각 프로젝트별 .env 파일 생성 필요
cp neotrinity/.env.example neotrinity/.env
cp kidszzanggame/.env.example kidszzanggame/.env

# 4. 주전자 메인 실행
cd neotrinity
pnpm dev
# → http://localhost:3000

# 5. 키즈짱게임 실행
cd kidszzanggame
pnpm dev
# → http://localhost:3090

# 6. Ryllis 위키 실행
cd ryllis
make build
make dev
# → http://localhost:8080

# 7. Discord 봇 실행
cd discord-bot
npm start

# 8. WebSocket 서버 실행
cd ws-server
pnpm dev
```

### Docker 실행 (권장)

```bash
# neoTrinity
cd neotrinity
docker-compose up -d

# kidszzanggame
cd kidszzanggame
docker-compose up -d

# 로그 확인
docker-compose logs -f
```

---

## 🔐 환경 변수

각 프로젝트는 독립적인 환경 변수가 필요합니다.

### 공통 (Supabase)
```env
NEXT_PUBLIC_SUPABASE_URL=https://api.zuzunza.com
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### neoTrinity 추가
```env
REDIS_URL=redis://localhost:6379
SESSION_SECRET=your-session-secret
CLOUDFLARE_ACCOUNT_ID=your-account-id
CLOUDFLARE_STREAM_API_TOKEN=your-token
```

### kidszzanggame 추가
```env
ABLY_API_KEY=your-ably-key
AWS_ACCESS_KEY_ID=your-aws-key
AWS_SECRET_ACCESS_KEY=your-aws-secret
```

### Ryllis 추가
```env
DATABASE_URL=postgresql://user:pass@localhost:5432/blogs
JWT_SECRET=your-jwt-secret
GATEWAY_PORT=8080
ENGINE_PORT=9001
RENDERER_PORT=9002
```

---

## 📊 플랫폼 통계

### 사용자 활동
- **콘텐츠 타입**: 아트워크, 동영상, 텍스트, 게임
- **실시간 기능**: 1:1 통화, 그룹 통화, 라이브 방송, 채팅
- **소셜 기능**: 팔로우, 서버, 크루, 챌린지

### 기술 성능
- **평균 응답 시간**: < 1000ms (Next.js), < 10ms (Ryllis 목표)
- **동시 접속**: 무제한 (분산 아키텍처)
- **실시간 메시지**: Socket.IO, Ably 기반

---

## 🤝 기여

주전자닷컴은 비공개 프로젝트입니다. 내부 팀원만 기여 가능합니다.

<div align="center">

**주전자닷컴** - 창작자를 위한 통합 커뮤니티 플랫폼 🫖

*연결하고, 창작하고, 성장하는 공간*

[neoTrinity](neotrinity/) · [kidszzanggame](kidszzanggame/) · [Ryllis 위키](ryllis/)

---

### 🔄 현재 진행 중

**NextJS → Ryllis 마이그레이션**

기존 기능을 유지하면서 고성능 Ryllis 엔진으로 전환 중입니다.

---

Made with ❤️ by Zuzunza Team

</div>

