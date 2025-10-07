#!/bin/bash

# PM2로 웹소켓 서버 재시작 스크립트

echo "🔄 Restarting WebSocket Server..."

# TypeScript 빌드
echo "🔨 Building TypeScript..."
npm run build

# PM2로 서버 재시작
echo "🎯 Restarting server with PM2..."
npm run pm2:restart

# 상태 확인
echo "📊 Checking server status..."
npm run pm2:status

echo "✅ WebSocket Server restarted!"
