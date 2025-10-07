/**
 * 통화 관련 이벤트 핸들러
 */
import { logger } from '../utils/logger.js';
export function callHandlers(io, socket) {
    // 통화 시작
    socket.on('call:initiate', (data) => {
        try {
            logger.info('📞 Call initiated:', data);
            // 수신자에게 통화 요청 전송
            io.to(`user:${data.receiverId}`).emit('call:ringing', {
                sessionId: data.sessionId,
                callerId: data.callerId,
                callerName: data.callerName || '',
                callerImage: data.callerImage || null,
                mediaType: data.mediaType || 'audio',
                timestamp: new Date().toISOString(),
            });
            socket.emit('call:initiate_result', {
                sessionId: data.sessionId,
                receiverId: data.receiverId,
            });
        }
        catch (error) {
            logger.error('❌ Call initiation failed:', error);
            socket.emit('call:initiate_result', {
                success: false,
                sessionId: data.sessionId,
                error: 'Failed to initiate call',
            });
        }
    });
    // 통화 수락
    socket.on('call:accept', (data) => {
        try {
            logger.info('✅ Call accepted:', data);
            // 통화 세션에 참가
            socket.join(`call:${data.sessionId}`);
            // 통화 세션의 모든 참가자에게 수락 알림
            io.to(`call:${data.sessionId}`).emit('call:accepted', {
                sessionId: data.sessionId,
                receiverId: data.receiverId,
                timestamp: new Date().toISOString(),
            });
            socket.emit('call:accept_result', {
                success: true,
                sessionId: data.sessionId,
            });
        }
        catch (error) {
            logger.error('❌ Call acceptance failed:', error);
            socket.emit('call:accept_result', {
                success: false,
                sessionId: data.sessionId,
                error: 'Failed to accept call',
            });
        }
    });
    // 통화 거절
    socket.on('call:decline', (data) => {
        try {
            logger.info('❌ Call declined:', data);
            // 통화 세션의 모든 참가자에게 거절 알림
            io.to(`call:${data.sessionId}`).emit('call:declined', {
                sessionId: data.sessionId,
                receiverId: data.receiverId,
                reason: data.reason || 'Call declined',
                timestamp: new Date().toISOString(),
            });
            socket.emit('call:decline_result', {
                success: true,
                sessionId: data.sessionId,
            });
        }
        catch (error) {
            logger.error('❌ Call decline failed:', error);
            socket.emit('call:decline_result', {
                success: false,
                sessionId: data.sessionId,
                error: 'Failed to decline call',
            });
        }
    });
    // 통화 종료
    socket.on('call:end', (data) => {
        try {
            logger.info('📴 Call ended:', data);
            // 통화 세션의 모든 참가자에게 종료 알림
            io.to(`call:${data.sessionId}`).emit('call:ended', {
                sessionId: data.sessionId,
                userId: data.userId,
                reason: data.reason || 'Call ended',
                timestamp: new Date().toISOString(),
            });
            // 모든 참가자를 통화 세션에서 제거
            io.in(`call:${data.sessionId}`).socketsLeave(`call:${data.sessionId}`);
            socket.emit('call:end_result', {
                success: true,
                sessionId: data.sessionId,
            });
        }
        catch (error) {
            logger.error('❌ Call end failed:', error);
            socket.emit('call:end_result', {
                success: false,
                sessionId: data.sessionId,
                error: 'Failed to end call',
            });
        }
    });
    // WebRTC Offer
    socket.on('call:offer', (data) => {
        try {
            logger.info('📡 Call offer:', data.sessionId);
            io.to(`user:${data.to}`).emit('call:offer', {
                ...data,
                timestamp: new Date().toISOString(),
            });
        }
        catch (error) {
            logger.error('❌ Call offer failed:', error);
        }
    });
    // WebRTC Answer
    socket.on('call:answer', (data) => {
        try {
            logger.info('📡 Call answer:', data.sessionId);
            io.to(`user:${data.to}`).emit('call:answer', {
                ...data,
                timestamp: new Date().toISOString(),
            });
        }
        catch (error) {
            logger.error('❌ Call answer failed:', error);
        }
    });
    // ICE Candidate
    socket.on('call:ice_candidate', (data) => {
        try {
            io.to(`user:${data.to}`).emit('call:ice_candidate', {
                ...data,
                timestamp: new Date().toISOString(),
            });
        }
        catch (error) {
            logger.error('❌ ICE candidate failed:', error);
        }
    });
    // 음성 채널 참가
    socket.on('call:join_channel', async (data) => {
        try {
            logger.info('🎤 Join voice channel:', data);
            const roomName = `channel:${data.channelId}`;
            // 채널에 참가
            socket.join(roomName);
            // 채널의 다른 참가자들에게 새 참가자 알림
            socket.to(roomName).emit('call:user_joined', {
                userId: data.userId,
                channelId: data.channelId,
                timestamp: new Date().toISOString(),
            });
            // 현재 채널 참가자 목록 조회
            const sockets = await io.in(roomName).fetchSockets();
            const participants = sockets
                .map((s) => s.data.userId)
                .filter(id => id && id !== data.userId);
            socket.emit('call:join_channel_result', {
                channelId: data.channelId,
                participants,
                count: participants.length,
                timestamp: new Date().toISOString(),
            });
        }
        catch (error) {
            logger.error('❌ Join voice channel failed:', error);
            socket.emit('call:join_channel_result', {
                success: false,
                channelId: data.channelId,
                error: 'Failed to join voice channel',
            });
        }
    });
    // 음성 채널 나가기
    socket.on('call:leave_channel', (data) => {
        try {
            logger.info('🔇 Leave voice channel:', data);
            const roomName = `channel:${data.channelId}`;
            // 채널에서 나가기
            socket.leave(roomName);
            // 채널의 다른 참가자들에게 나가기 알림
            socket.to(roomName).emit('call:user_left', {
                userId: data.userId,
                channelId: data.channelId,
                timestamp: new Date().toISOString(),
            });
            socket.emit('call:leave_channel_result', {
                success: true,
                channelId: data.channelId,
            });
        }
        catch (error) {
            logger.error('❌ Leave voice channel failed:', error);
            socket.emit('call:leave_channel_result', {
                success: false,
                channelId: data.channelId,
                error: 'Failed to leave voice channel',
            });
        }
    });
}
//# sourceMappingURL=call-handlers.js.map