# 주전자닷컴 (Zuzunza)

> **창작자를 위한 통합 크리에이티브 플랫폼**

주전자닷컴은 플래시 애니메이션, 자작 게임, 웹툰, 아트워크 등 다양한 창작물을 공유하고 소통하는 국내 최대 규모의 창작 커뮤니티입니다.

---

## 프로젝트 구조

```
zuzunza-dyllis/
├── app/                    # 메인 앱 (Next.js 16)
├── app-studio/             # Studio 앱 (개발자 도구)
├── dyllis-ditto/           # Ditto 서버 (빌드 & 배포)
│   ├── server/             # 런타임 서버
│   ├── compile/            # 앱 빌드 결과물
│   └── studio-compile/     # Studio 빌드 결과물
├── scripts/                # 설치 및 운영 스크립트
├── wiki/                   # 개발자 문서 (심볼릭 링크)
└── Makefile               # 빌드 및 서비스 관리
```

## 기술 스택

| 분류 | 기술 |
|------|------|
| Frontend | Next.js 16, React 19, TypeScript |
| Backend | Node.js, Dyllis Ditto Server |
| Auth | Better Auth, Supabase Auth |
| Database | Supabase (PostgreSQL) |
| Cache | Redis |
| Process Manager | PM2 (제한된 pm2 계정으로 실행) |

## 설치 및 실행

### 1. 최초 설치 (라이센스 필요)

```bash
make install
```

설치 시 라이센스 키와 암구호를 입력해야 합니다.

### 2. 빌드

```bash
# Studio 앱 빌드
make build-studio

# 메인 앱 빌드
make build

# Ditto 서버 빌드
make build-server

# 전체 빌드
make build-all
```

### 3. 서비스 실행

```bash
# Studio 서버 시작 (포트 7601)
make studio-start

# 메인 앱 서버 시작 (포트 7600)
make app-start

# PM2 상태 확인
su -l pm2 -c 'pm2 list'
```

### 4. 서비스 중지

```bash
make studio-stop
make app-pm2-stop
```

## PM2 서비스 관리

PM2는 보안을 위해 제한된 `pm2` 사용자 계정으로 실행됩니다.

```bash
# PM2 상태 확인
su -l pm2 -c 'pm2 list'

# 로그 확인
su -l pm2 -c 'pm2 logs dyllis-studio'

# 재시작
su -l pm2 -c 'pm2 restart all'
```

## API 시스템

### xzase (eXtend ZUZUNZA Arcading Service Environment)

고급 인증 및 ZVM 실행 시스템:

| 엔드포인트 | 설명 |
|-----------|------|
| `/api/xzase/v1` | OpenAPI 스펙 |
| `/api/xzase/v1/authenticate` | 인증 (p:1~5 모드) |
| `/api/xzase/v1/decrypt` | ZVM 스크립트 복호화 |
| `/api/xzase/v1/zvm` | ZVM 실행 |

### zase (ZUZUNZA Arcading Service Environment)

게임 에셋 서비스:

| 엔드포인트 | 설명 |
|-----------|------|
| `/api/game/zase/v1` | 게임 파서 |
| `/api/game/zase/v2` | v2 API |

### Supabase

| 엔드포인트 | 설명 |
|-----------|------|
| `https://api.zuzunza.com` | Supabase REST API |
| `https://api.zuzunza.com/auth/v1` | Auth API |
| `https://api.zuzunza.com/rest/v1` | PostgREST API |

## 서비스 포트

| 서비스 | 포트 | 설명 |
|--------|------|------|
| Main App (Ditto) | 7600 | 메인 애플리케이션 |
| Studio | 7601 | 개발자 도구 |
| Redis | 6379 | 캐시 서버 |
| Supabase | 외부 | api.zuzunza.com |

## 문서

- [Wiki](https://github.com/zuzunza-com/zuzunza/wiki) - 개발자 문서
- [개발자 가이드](https://github.com/zuzunza-com/zuzunza/wiki/개발자-가이드)
- [플랫폼 구조 개요](https://github.com/zuzunza-com/zuzunza/wiki/플랫폼-구조-개요)
- [REST API 개요](https://github.com/zuzunza-com/zuzunza/wiki/REST-API-개요)

---

<div align="center">
  <b>Zuzunza Development Team</b><br>
  Powered by Dyllis Ditto
</div>
