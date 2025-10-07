/**
 * Socket.IO 이벤트 핸들러
 */

import { Server, Socket } from 'socket.io';
import { logger } from '../utils/logger.js';
import { userHandlers } from './user-handlers.js';
import { chatHandlers } from './chat-handlers.js';
import { callHandlers } from './call-handlers.js';

export function setupSocketHandlers(io: Server): void {
  io.on('connection', (socket: Socket) => {
    logger.info(`✅ Socket connected: ${socket.id}`);
    logger.info(`📊 Total connected clients: ${io.engine.clientsCount}`);
    logger.info(`🔗 Transport: ${socket.conn.transport.name}`);
    
    // Ping 이벤트 전송
    socket.emit('ping');
    
    // 기본 이벤트 핸들러 등록
    setupBasicHandlers(socket);
    
    // 사용자 관련 이벤트 핸들러
    userHandlers(io, socket);
    
    // 채팅 관련 이벤트 핸들러
    chatHandlers(io, socket);
    
    // 통화 관련 이벤트 핸들러
    callHandlers(io, socket);
    
    // 연결 해제 처리
    socket.on('disconnect', (reason: string) => {
      const userId = socket.data.userId;
      if (userId) {
        io.emit('user:offline', userId);
        logger.info(`👤 User offline: ${userId}`);
      }
      logger.info(`❌ Socket disconnected: ${socket.id}, reason: ${reason}`);
      logger.info(`📊 Remaining connected clients: ${io.engine.clientsCount}`);
    });
  });
}

function setupBasicHandlers(socket: Socket): void {
  // Ping 응답
  socket.on('ping', () => {
    logger.debug(`🏓 Ping received from client: ${socket.id}`);
  });
}
