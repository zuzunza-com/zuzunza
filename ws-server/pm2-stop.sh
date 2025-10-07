#!/bin/bash

# PM2로 웹소켓 서버 중지 스크립트

echo "🛑 Stopping WebSocket Server..."

# PM2로 서버 중지
npm run pm2:stop

echo "✅ WebSocket Server stopped!"
echo "📋 To completely remove from PM2: npm run pm2:delete"
