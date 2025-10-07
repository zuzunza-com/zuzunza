/**
 * 서버 설정
 */
export declare const config: {
    server: {
        port: string | number;
        host: string;
    };
    socket: {
        path: string;
        pingTimeout: number;
        pingInterval: number;
        connectTimeout: number;
        upgradeTimeout: number;
        maxHttpBufferSize: number;
    };
    cors: {
        origins: string[];
    };
    logging: {
        level: string;
        format: string;
    };
};
//# sourceMappingURL=config.d.ts.map