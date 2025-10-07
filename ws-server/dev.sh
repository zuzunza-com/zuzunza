#!/bin/bash

# Socket.IO 서버 개발 모드 시작 스크립트

echo "🚀 Starting Socket.IO Server in development mode..."

# 의존성 설치
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# 개발 서버 시작
echo "🎯 Starting development server..."
npm run dev
