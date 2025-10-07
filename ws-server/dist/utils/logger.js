/**
 * 로거 유틸리티
 */
class Logger {
    level;
    constructor() {
        this.level = process.env.LOG_LEVEL || 'info';
    }
    shouldLog(level) {
        const levels = ['debug', 'info', 'warn', 'error'];
        return levels.indexOf(level) >= levels.indexOf(this.level);
    }
    formatMessage(level, message, ...args) {
        const timestamp = new Date().toISOString();
        const formattedArgs = args.length > 0 ? ' ' + args.map(arg => typeof arg === 'object' ? JSON.stringify(arg) : String(arg)).join(' ') : '';
        return `[${timestamp}] ${level.toUpperCase()}: ${message}${formattedArgs}`;
    }
    debug(message, ...args) {
        if (this.shouldLog('debug')) {
            console.log(this.formatMessage('debug', message, ...args));
        }
    }
    info(message, ...args) {
        if (this.shouldLog('info')) {
            console.log(this.formatMessage('info', message, ...args));
        }
    }
    warn(message, ...args) {
        if (this.shouldLog('warn')) {
            console.warn(this.formatMessage('warn', message, ...args));
        }
    }
    error(message, ...args) {
        if (this.shouldLog('error')) {
            console.error(this.formatMessage('error', message, ...args));
        }
    }
}
export const logger = new Logger();
//# sourceMappingURL=logger.js.map