/**
 * 로거 유틸리티
 */
declare class Logger {
    private level;
    constructor();
    private shouldLog;
    private formatMessage;
    debug(message: string, ...args: any[]): void;
    info(message: string, ...args: any[]): void;
    warn(message: string, ...args: any[]): void;
    error(message: string, ...args: any[]): void;
}
export declare const logger: Logger;
export {};
//# sourceMappingURL=logger.d.ts.map