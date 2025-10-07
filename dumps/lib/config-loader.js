/**
 * Config 파일 로더 유틸리티
 * ../neotrinity/config 디렉토리에서 설정을 읽어옵니다
 */

import { readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// config 디렉토리 경로
const CONFIG_DIR = join(__dirname, '../../neotrinity/config');

/**
 * 환경에 따른 config 파일 로드
 * @param {string} env - 'development', 'production', 또는 기본값
 * @returns {object} config 객체
 */
export function loadConfig(env = 'production') {
  let configPath;
  
  if (env === 'development') {
    configPath = join(CONFIG_DIR, 'config.development.json');
  } else if (env === 'production') {
    configPath = join(CONFIG_DIR, 'config.production.json');
  } else {
    configPath = join(CONFIG_DIR, 'config.json');
  }
  
  if (!existsSync(configPath)) {
    throw new Error(`Config 파일을 찾을 수 없습니다: ${configPath}`);
  }
  
  try {
    const configContent = readFileSync(configPath, 'utf-8');
    return JSON.parse(configContent);
  } catch (error) {
    throw new Error(`Config 파일 파싱 실패: ${error.message}`);
  }
}

/**
 * DATABASE_URL 파싱
 * @param {string} databaseUrl - PostgreSQL connection URL
 * @returns {object} 파싱된 연결 정보
 */
export function parseDatabaseUrl(databaseUrl) {
  try {
    // postgresql://user:password@host:port/database 형식 파싱
    const url = new URL(databaseUrl);
    
    return {
      user: url.username || 'postgres',
      password: url.password || '',
      host: url.hostname || 'localhost',
      port: parseInt(url.port) || 5432,
      database: url.pathname.slice(1) || 'postgres',
      url: databaseUrl
    };
  } catch (error) {
    throw new Error(`DATABASE_URL 파싱 실패: ${error.message}`);
  }
}

/**
 * Config에서 데이터베이스 연결 정보 추출
 * @param {string} env - 환경 (development, production)
 * @returns {object} 데이터베이스 연결 정보
 */
export function getDatabaseConfig(env = 'production') {
  const config = loadConfig(env);
  
  // DATABASE_URL이 있으면 우선 사용
  if (config.DATABASE_URL) {
    return parseDatabaseUrl(config.DATABASE_URL);
  }
  
  // 개별 필드로 구성
  return {
    user: config.POSTGRES_USER || 'postgres',
    password: config.POSTGRES_PASSWORD || '',
    host: config.POSTGRES_HOST || 'localhost',
    port: parseInt(config.POSTGRES_PORT) || 5432,
    database: config.POSTGRES_DB || 'postgres',
    url: `postgresql://${config.POSTGRES_USER}:${config.POSTGRES_PASSWORD}@${config.POSTGRES_HOST}:${config.POSTGRES_PORT}/${config.POSTGRES_DB}`
  };
}

/**
 * 사용 가능한 환경 목록 반환
 * @returns {string[]} 환경 목록
 */
export function getAvailableEnvironments() {
  const envs = [];
  
  if (existsSync(join(CONFIG_DIR, 'config.json'))) {
    envs.push('default');
  }
  if (existsSync(join(CONFIG_DIR, 'config.development.json'))) {
    envs.push('development');
  }
  if (existsSync(join(CONFIG_DIR, 'config.production.json'))) {
    envs.push('production');
  }
  
  return envs;
}

/**
 * Config 정보 표시 (민감한 정보 마스킹)
 * @param {object} config
 * @returns {object} 마스킹된 config
 */
export function maskSensitiveInfo(config) {
  const masked = { ...config };
  
  const sensitiveKeys = [
    'PASSWORD', 'SECRET', 'KEY', 'TOKEN', 'PASS'
  ];
  
  for (const key in masked) {
    if (sensitiveKeys.some(sensitive => key.toUpperCase().includes(sensitive))) {
      const value = String(masked[key]);
      if (value.length > 4) {
        masked[key] = value.slice(0, 2) + '*'.repeat(value.length - 4) + value.slice(-2);
      } else {
        masked[key] = '****';
      }
    }
  }
  
  return masked;
}

/**
 * 데이터베이스 연결 문자열 생성 (pg_dump/pg_restore용)
 * @param {object} dbConfig - 데이터베이스 설정
 * @returns {string} 연결 문자열
 */
export function buildConnectionString(dbConfig) {
  return `postgresql://${dbConfig.user}:${dbConfig.password}@${dbConfig.host}:${dbConfig.port}/${dbConfig.database}`;
}

/**
 * 환경 변수로 내보내기 (pg_dump/pg_restore용)
 * @param {object} dbConfig
 * @returns {object} 환경 변수 객체
 */
export function getPostgresEnv(dbConfig) {
  return {
    PGHOST: dbConfig.host,
    PGPORT: String(dbConfig.port),
    PGUSER: dbConfig.user,
    PGPASSWORD: dbConfig.password,
    PGDATABASE: dbConfig.database
  };
}

