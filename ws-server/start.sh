#!/bin/bash

# Socket.IO 서버 시작 스크립트

echo "🚀 Starting Socket.IO Server..."

# 의존성 설치
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# TypeScript 빌드
echo "🔨 Building TypeScript..."
npm run build

# 서버 시작
echo "🎯 Starting server..."
npm start
