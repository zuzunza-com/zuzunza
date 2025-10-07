/**
 * 서버 설정
 */

export const config = {
  server: {
    port: process.env.SOCKET_PORT || 5689,
    host: process.env.SOCKET_HOST || '0.0.0.0',
  },
  
  socket: {
    path: '/socket.io',
    pingTimeout: 60000,
    pingInterval: 25000,
    connectTimeout: 60000,
    upgradeTimeout: 10000,
    maxHttpBufferSize: 1e6, // 1MB
  },
  
  cors: {
    origins: [
      'https://www.zuzunza.com',
      'https://zuzunza.com',
      'https://api.zuzunza.com',
      'https://ws.zuzunza.com',
      'https://dev.zuzunza.com',
      'http://localhost:3000',
      'http://127.0.0.1:3000'
    ],
  },
  
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    format: process.env.LOG_FORMAT || 'json',
  },
};
