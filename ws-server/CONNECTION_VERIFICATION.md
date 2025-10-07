# 웹소켓 서버 연결성 검증 결과

## 📋 설정 확인 결과

### ✅ 1. Apache 설정 (ws.zuzunza.com.conf)
- **프록시 대상**: `http://127.0.0.1:5689/socket.io/`
- **웹소켓 업그레이드**: 지원됨
- **CORS 설정**: `https://www.zuzunza.com` 허용
- **SSL/TLS**: Cloudflare Origin 인증서 사용

### ✅ 2. ws-server 설정
- **포트**: 5689 (SOCKET_PORT 환경변수)
- **경로**: `/socket.io`
- **CORS Origins**: 
  - `https://www.zuzunza.com`
  - `https://ws.zuzunza.com`
  - `http://localhost:3000`
- **전송 방식**: polling, websocket

### ✅ 3. neotrinity 클라이언트 설정
- **연결 URL**: 
  - 개발: `http://localhost:3000`
  - 프로덕션: `https://ws.zuzunza.com`
- **경로**: `/socket.io`
- **전송 방식**: polling, websocket
- **인증**: withCredentials: true

### ✅ 4. PM2 설정
- **스크립트**: `dist/server.js`
- **포트**: 5689 (SOCKET_PORT 환경변수)
- **로그**: `./logs/` 디렉토리
- **자동 재시작**: 활성화

## 🔗 연결 흐름

```
클라이언트 (neotrinity) 
    ↓
https://ws.zuzunza.com/socket.io/
    ↓
Apache (포트 443)
    ↓
ProxyPass → http://127.0.0.1:5689/socket.io/
    ↓
ws-server (PM2, 포트 5689)
```

## 📝 사용 가능한 명령어

### PM2 관리
```bash
# 서버 시작
./pm2-start.sh

# 서버 중지
./pm2-stop.sh

# 서버 재시작
./pm2-restart.sh

# 로그 확인
npm run pm2:logs

# 상태 확인
npm run pm2:status

# 모니터링
npm run pm2:monit
```

### 테스트
```bash
# 웹소켓 연결 테스트
node test-socket.js
```

## ⚠️ 주의사항

1. **PM2 설치**: `pnpm install pm2 -g` 또는 `npm install pm2 -g`
2. **포트 충돌**: 5689 포트가 다른 서비스에서 사용되지 않는지 확인
3. **방화벽**: 5689 포트가 로컬에서 접근 가능한지 확인
4. **SSL 인증서**: Cloudflare Origin 인증서가 유효한지 확인

## 🚀 배포 순서

1. TypeScript 빌드: `npm run build`
2. PM2로 시작: `./pm2-start.sh`
3. 연결 테스트: `node test-socket.js`
4. 상태 확인: `npm run pm2:status`
