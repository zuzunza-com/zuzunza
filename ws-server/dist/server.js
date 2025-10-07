/**
 * Socket.IO 서버 메인 진입점
 */
import { createServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';
import { setupSocketHandlers } from './handlers/socket-handlers.js';
import { logger } from './utils/logger.js';
import { config } from './config/config.js';
// HTTP 서버 생성
const httpServer = createServer();
// Socket.IO 서버 생성
const io = new SocketIOServer(httpServer, {
    cors: {
        origin: config.cors.origins,
        credentials: true,
        methods: ['GET', 'POST', 'OPTIONS'],
        allowedHeaders: ['*'],
        exposedHeaders: ['*'],
    },
    transports: ['polling', 'websocket'],
    allowEIO3: true,
    pingTimeout: config.socket.pingTimeout,
    pingInterval: config.socket.pingInterval,
    path: config.socket.path,
    connectTimeout: config.socket.connectTimeout,
    upgradeTimeout: config.socket.upgradeTimeout,
    maxHttpBufferSize: config.socket.maxHttpBufferSize,
    serveClient: false,
    allowUpgrades: true,
    httpCompression: {
        threshold: 1024,
        memLevel: 7,
        concurrencyLimit: 10,
    },
    perMessageDeflate: {
        threshold: 1024,
        concurrencyLimit: 10,
        memLevel: 7,
    },
});
// Socket.IO 이벤트 핸들러 설정
setupSocketHandlers(io);
// 서버 시작
const PORT = config.server.port;
httpServer.listen(PORT, () => {
    logger.info(`🚀 Socket.IO Server running on port ${PORT}`);
    logger.info(`📡 Socket.IO endpoint: http://localhost:${PORT}${config.socket.path}`);
    logger.info(`🔗 Transport: polling, websocket`);
    logger.info(`🌐 CORS origins: ${config.cors.origins.join(', ')}`);
});
// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('🛑 Socket.IO Server shutting down...');
    httpServer.close(() => {
        logger.info('✅ Socket.IO Server closed');
        process.exit(0);
    });
});
process.on('SIGINT', () => {
    logger.info('🛑 Socket.IO Server shutting down...');
    httpServer.close(() => {
        logger.info('✅ Socket.IO Server closed');
        process.exit(0);
    });
});
export { io as socketServer };
//# sourceMappingURL=server.js.map