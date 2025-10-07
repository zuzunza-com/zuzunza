/**
 * 사용자 관련 이벤트 핸들러
 */

import { Server, Socket } from 'socket.io';
import { logger } from '../utils/logger.js';

export function userHandlers(io: Server, socket: Socket): void {
  // 사용자 등록
  socket.on('user:register', (userId: string) => {
    try {
      socket.data.userId = userId;
      socket.join(`user:${userId}`);
      logger.info(`👤 User registered: ${userId} (${socket.id})`);
      
      // 모든 클라이언트에게 사용자 온라인 상태 알림
      io.emit('user:online', userId);
      
      socket.emit('user:registered', {
        success: true,
        userId,
        socketId: socket.id,
      });
    } catch (error) {
      logger.error('❌ User registration failed:', error);
      socket.emit('user:registered', {
        success: false,
        error: 'Registration failed',
      });
    }
  });

  // 사용자 정보 업데이트
  socket.on('user:update', (userData: any) => {
    try {
      if (!socket.data.userId) {
        return socket.emit('user:update_result', {
          success: false,
          error: 'User not authenticated',
        });
      }

      logger.info(`👤 User update: ${socket.data.userId}`, userData);

      socket.emit('user:update_result', {
        success: true,
        userId: socket.data.userId,
        data: userData,
      });
    } catch (error) {
      logger.error('❌ User update failed:', error);
      socket.emit('user:update_result', {
        success: false,
        error: 'Update failed',
      });
    }
  });

  // 사용자 상태 변경
  socket.on('user:status_change', (status: string) => {
    try {
      if (!socket.data.userId) {
        return socket.emit('user:status_change_result', {
          success: false,
          error: 'User not authenticated',
        });
      }

      logger.info(`👤 User status change: ${socket.data.userId} -> ${status}`);

      // 모든 클라이언트에게 상태 변경 알림
      io.emit('user:status_updated', {
        userId: socket.data.userId,
        status,
        timestamp: new Date().toISOString(),
      });

      socket.emit('user:status_change_result', {
        success: true,
        status,
      });
    } catch (error) {
      logger.error('❌ User status change failed:', error);
      socket.emit('user:status_change_result', {
        success: false,
        error: 'Status change failed',
      });
    }
  });

  // 온라인 사용자 목록 요청
  socket.on('user:get_online', async () => {
    try {
      const sockets = await io.fetchSockets();
      const onlineUsers = sockets
        .map((s: any) => s.data.userId)
        .filter((userId: string) => userId)
        .filter((userId: string, index: number, array: string[]) => array.indexOf(userId) === index); // 중복 제거

      logger.info(
        `👥 Online users requested by ${socket.data.userId}:`,
        onlineUsers.length
      );

      socket.emit('user:online_list', {
        success: true,
        users: onlineUsers,
        count: onlineUsers.length,
      });
    } catch (error) {
      logger.error('❌ Get online users failed:', error);
      socket.emit('user:online_list', {
        success: false,
        error: 'Failed to get online users',
      });
    }
  });
}
