/**
 * Socket.IO 서버 메인 진입점
 */
import { Server as SocketIOServer } from 'socket.io';
declare const io: SocketIOServer<import("socket.io").DefaultEventsMap, import("socket.io").DefaultEventsMap, import("socket.io").DefaultEventsMap, any>;
export { io as socketServer };
//# sourceMappingURL=server.d.ts.map