#!/bin/bash

# PM2로 웹소켓 서버 시작 스크립트

echo "🚀 Starting WebSocket Server with PM2..."

# 로그 디렉토리 생성
mkdir -p logs

# 의존성 설치 확인
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# TypeScript 빌드
echo "🔨 Building TypeScript..."
npm run build

# PM2로 서버 시작
echo "🎯 Starting server with PM2..."
npm run pm2:start

# 상태 확인
echo "📊 Checking server status..."
npm run pm2:status

echo "✅ WebSocket Server started with PM2!"
echo "📋 Useful commands:"
echo "   - View logs: npm run pm2:logs"
echo "   - Monitor: npm run pm2:monit"
echo "   - Restart: npm run pm2:restart"
echo "   - Stop: npm run pm2:stop"
