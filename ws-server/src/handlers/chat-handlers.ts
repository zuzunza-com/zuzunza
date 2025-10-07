/**
 * 채팅 관련 이벤트 핸들러
 */

import { Server, Socket } from 'socket.io';
import { logger } from '../utils/logger.js';

export function chatHandlers(io: Server, socket: Socket): void {
  // 채팅 채널 참가
  socket.on('chat:join_channel', (data: { channelId: string }) => {
    try {
      const { channelId } = data;
      if (!channelId) {
        return socket.emit('chat:join_result', {
          success: false,
          error: 'Channel ID is required',
        });
      }

      socket.join(`channel:${channelId}`);
      logger.info(`💬 User joined chat: ${channelId} (${socket.data.userId})`);
      
      socket.emit('chat:join_result', {
        success: true,
        channelId,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('❌ Join chat channel failed:', error);
      socket.emit('chat:join_result', {
        success: false,
        error: 'Failed to join chat channel',
      });
    }
  });

  // 채팅 채널 나가기
  socket.on('chat:leave_channel', (data: { channelId: string }) => {
    try {
      const { channelId } = data;
      if (!channelId) {
        return socket.emit('chat:leave_result', {
          success: false,
          error: 'Channel ID is required',
        });
      }

      socket.leave(`channel:${channelId}`);
      logger.info(`👋 User left chat: ${channelId} (${socket.data.userId})`);
      
      socket.emit('chat:leave_result', {
        success: true,
        channelId,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('❌ Leave chat channel failed:', error);
      socket.emit('chat:leave_result', {
        success: false,
        error: 'Failed to leave chat channel',
      });
    }
  });

  // 채팅 메시지 전송
  socket.on('chat:send_message', (data: { channelId: string; message: string; messageType?: string }) => {
    try {
      if (!socket.data.userId) {
        return socket.emit('chat:send_result', {
          success: false,
          error: 'User not authenticated',
        });
      }

      const { channelId, message, messageType = 'text' } = data;

      if (!channelId || !message) {
        return socket.emit('chat:send_result', {
          success: false,
          error: 'Channel ID and message are required',
        });
      }

      const messageData = {
        id: generateMessageId(),
        channelId,
        userId: socket.data.userId,
        message,
        messageType,
        timestamp: new Date().toISOString(),
        edited: false,
        deleted: false,
      };

      logger.info('💬 Chat message:', {
        channelId,
        userId: socket.data.userId,
        messageType,
        messageLength: message.length,
      });

      // 채널의 다른 참가자들에게 메시지 전송
      socket.to(`channel:${channelId}`).emit('chat:new_message', messageData);

      socket.emit('chat:send_result', {
        success: true,
        messageId: messageData.id,
        timestamp: messageData.timestamp,
      });
    } catch (error) {
      logger.error('❌ Send chat message failed:', error);
      socket.emit('chat:send_result', {
        success: false,
        error: 'Failed to send message',
      });
    }
  });

  // 타이핑 시작
  socket.on('chat:start_typing', (data: { channelId: string }) => {
    try {
      if (!socket.data.userId) {
        return;
      }

      const { channelId } = data;
      if (!channelId) {
        return;
      }

      socket.to(`channel:${channelId}`).emit('chat:user_typing', {
        channelId,
        userId: socket.data.userId,
        isTyping: true,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('❌ Start typing failed:', error);
    }
  });

  // 타이핑 중지
  socket.on('chat:stop_typing', (data: { channelId: string }) => {
    try {
      if (!socket.data.userId) {
        return;
      }

      const { channelId } = data;
      if (!channelId) {
        return;
      }

      socket.to(`channel:${channelId}`).emit('chat:user_typing', {
        channelId,
        userId: socket.data.userId,
        isTyping: false,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('❌ Stop typing failed:', error);
    }
  });

  // 채널 참가자 목록 요청
  socket.on('chat:get_participants', async (data: { channelId: string }) => {
    try {
      const { channelId } = data;
      if (!channelId) {
        return socket.emit('chat:participants', {
          success: false,
          error: 'Channel ID is required',
        });
      }

      const sockets = await io.in(`channel:${channelId}`).fetchSockets();
      const participants = sockets
        .map(s => s.data.userId)
        .filter(userId => userId)
        .filter((userId, index, array) => array.indexOf(userId) === index); // 중복 제거

      logger.info(
        `👥 Chat participants requested for ${channelId}:`,
        participants.length
      );

      socket.emit('chat:participants', {
        success: true,
        channelId,
        participants,
        count: participants.length,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('❌ Get chat participants failed:', error);
      socket.emit('chat:participants', {
        success: false,
        error: 'Failed to get participants',
      });
    }
  });
}

function generateMessageId(): string {
  return `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}
