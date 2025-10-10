# Zuzunza Fallback Site 🎨

## 개요

메인 Zuzunza 웹사이트(`www.zuzunza.com`)가 다운되었을 때 자동으로 표시되는 PHP 기반의 동적 대체(fallback) 사이트입니다.

### 주요 특징

- **PHP 8.4 기반**: 동적 서버 상태 모니터링 및 실시간 헬스체크
- **모던 디자인**: 화려한 그라디언트와 애니메이션 효과
- **실시간 모니터링**: 메인 서버, 데이터베이스, Redis, 서버 부하 실시간 확인
- **자동 복구 감지**: 5초마다 서버 상태 체크 및 자동 리다이렉트
- **API 엔드포인트**: JSON 기반 상태 확인 API 제공

## 동작 방식

### HTTP (포트 80) 동작

1. **정상 상태**: HTTP 요청 → HTTPS로 302 리다이렉트 → 메인 사이트
2. **메인 서버 다운**: HTTP 요청 → Fallback 사이트 직접 서빙

### HTTPS (포트 443) 동작

1. **정상 상태**: HTTPS 요청 → Next.js 서버(5688) 프록시
2. **메인 서버 다운** (502/503/504 오류 발생):
   - `ProxyErrorOverride On` 설정으로 오류 감지
   - `ErrorDocument` 설정으로 HTTP fallback 사이트로 리다이렉트
   - 사용자는 `http://www.zuzunza.com/` fallback 페이지 확인

## 설정 파일

### Apache 가상 호스트

**파일**: `/srv/gateway/sites-enabled/www.zuzunza.com.conf`

#### HTTP VirtualHost (포트 80)

```apache
<VirtualHost *:80>
    ServerName www.zuzunza.com
    ServerAlias zuzunza.com
    
    # Fallback 사이트 DocumentRoot
    DocumentRoot /srv/zuzunza/fallback-site
    
    <Directory /srv/zuzunza/fallback-site>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
    
    # 정상 상태: HTTPS로 리다이렉트
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteCond %{HTTP_HOST} ^(www\.)?zuzunza\.com$ [NC]
    RewriteRule ^(?!fallback-check)(.*)$ https://www.zuzunza.com$1 [R=302,L]
</VirtualHost>
```

#### HTTPS VirtualHost (포트 443)

```apache
<VirtualHost *:443>
    ServerName www.zuzunza.com
    
    # 메인 서버 다운 시 HTTP Fallback으로 리다이렉트
    ProxyErrorOverride On
    ErrorDocument 502 http://www.zuzunza.com/
    ErrorDocument 503 http://www.zuzunza.com/
    ErrorDocument 504 http://www.zuzunza.com/
    
    # 메인 Next.js 서버로 프록시
    ProxyPass / http://127.0.0.1:5688/ retry=0
    ProxyPassReverse / http://127.0.0.1:5688/
</VirtualHost>
```

## Fallback 페이지 기능

### 자동 복구 감지

`index.html`에 포함된 JavaScript가 5초마다 메인 서버 상태를 확인:

```javascript
setInterval(function() {
    fetch('/', { method: 'HEAD' })
        .then(response => {
            if (response.ok) {
                window.location.reload(); // 서버 복구 시 자동 새로고침
            }
        })
        .catch(() => {
            // 아직 서버가 응답하지 않음
        });
}, 5000);
```

### 사용자 경험

- **시각적 피드백**: 점검 중 상태 표시 (펄스 애니메이션)
- **자동 새로고침**: 서버 복구 시 자동으로 정상 페이지로 이동
- **수동 새로고침**: 사용자가 직접 새로고침 버튼 클릭 가능
- **예상 복구 시간**: 약 5-10분 안내
- **긴급 문의**: 관리자 이메일 제공

## 테스트 방법

### 1. 메인 서버 중지

```bash
# Next.js 서버 중지 (예시)
pm2 stop neotrinity
```

### 2. Fallback 동작 확인

```bash
# HTTP 접속 테스트
curl -I http://www.zuzunza.com/
# → Fallback 페이지 서빙 확인

# HTTPS 접속 테스트
curl -I https://www.zuzunza.com/
# → HTTP Fallback으로 리다이렉트 확인 (502 오류 시)
```

### 3. 브라우저 테스트

1. `http://www.zuzunza.com` 접속
   - 메인 서버 정상: HTTPS로 리다이렉트
   - 메인 서버 다운: Fallback 페이지 표시

2. `https://www.zuzunza.com` 접속
   - 메인 서버 정상: 정상 페이지
   - 메인 서버 다운: HTTP Fallback으로 리다이렉트

### 4. 메인 서버 재시작

```bash
# Next.js 서버 재시작
pm2 start neotrinity
```

Fallback 페이지에서 5초 이내에 자동으로 정상 페이지로 복구됩니다.

## 파일 구조

```
/srv/zuzunza/fallback-site/
├── index.php          # 메인 Fallback 페이지 (PHP 8.4)
├── logs/              # 접속 로그 디렉토리
│   └── fallback.log   # 자동 생성되는 로그 파일
├── .gitignore         # Git 무시 파일
└── README.md          # 이 문서
```

## PHP 기능

### 헬스체크 기능

1. **메인 서버 체크**:
   - Socket 연결 체크 (fsockopen)
   - HTTP 헬스체크 (cURL)

2. **데이터베이스 체크** (PostgreSQL):
   - PDO를 사용한 연결 테스트
   - SELECT 1 쿼리 실행

3. **Redis 체크**:
   - Redis 확장 사용
   - PING 명령 테스트

4. **시스템 상태**:
   - 서버 부하 (sys_getloadavg)
   - 메모리 사용량
   - 타임스탬프

### API 엔드포인트

**GET** `/?api=status`

서버 상태를 JSON으로 반환합니다.

```json
{
  "main_server": {
    "socket": true,
    "http": true
  },
  "database": true,
  "redis": true,
  "timestamp": 1728561234,
  "server_load": [0.5, 0.6, 0.7],
  "memory_usage": {
    "used": 2097152,
    "peak": 4194304
  },
  "action": "redirect",
  "redirect_url": "https://www.zuzunza.com"
}
```

### 로깅 시스템

모든 접속과 서버 다운 이벤트가 자동으로 로그에 기록됩니다:

```
[2025-10-10 12:30:45] [WARNING] [IP: 127.0.0.1] Main server is down - serving fallback page
[2025-10-10 12:31:12] [WARNING] [IP: 192.168.1.100] Fallback page served - Main server is down
```

## 유지보수

### Fallback 페이지 수정

1. `/srv/zuzunza/fallback-site/index.html` 편집
2. Apache 재시작 불필요 (정적 파일이므로 즉시 반영)

### Apache 설정 수정

1. `/srv/gateway/sites-enabled/www.zuzunza.com.conf` 편집
2. 설정 검증: `sudo apachectl configtest`
3. Apache 재시작: `sudo systemctl reload apache2`

## 장애 대응 흐름

```
[사용자 요청]
      ↓
[Apache Gateway]
      ↓
[HTTPS 요청?] ─── Yes ──→ [Next.js 프록시]
      ↓                          ↓
     No                    [502/503/504?]
      ↓                          ↓
[HTTP Fallback              Yes → [HTTP Fallback
  사이트 서빙]                     리다이렉트]
```

## 보안 고려사항

- Fallback 사이트는 HTTP로만 서빙 (HTTPS 인증서 문제 회피)
- 민감한 정보 미포함 (공개 안내 페이지만)
- 자동 복구 스크립트는 안전한 HEAD 요청만 사용

## 모니터링

### 로그 확인

```bash
# Apache 오류 로그
sudo tail -f /var/log/apache2/www.zuzunza.com_ssl_error.log

# Apache 접속 로그
sudo tail -f /var/log/apache2/www.zuzunza.com_ssl_access.log
```

### 알림 설정 (권장)

메인 서버 다운 시 관리자에게 자동 알림을 보내도록 모니터링 도구 설정:

- Uptime Robot
- Pingdom
- New Relic
- Prometheus + Alertmanager

## 문의

기술 지원: admin@zuzunza.com

