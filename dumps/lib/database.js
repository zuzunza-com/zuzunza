/**
 * 데이터베이스 덤프 및 복원 유틸리티
 * PostgreSQL 17 호환
 */

import { spawn } from 'child_process';
import { existsSync, unlinkSync, createWriteStream } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * PostgreSQL 전체 덤프 생성 (psql plain SQL format)
 * @param {object} dbConfig - 데이터베이스 설정
 * @param {string} outputPath - 출력 파일 경로
 * @param {object} options - 덤프 옵션
 * @returns {Promise<void>}
 */
export async function createDump(dbConfig, outputPath, options = {}) {
  return new Promise((resolve, reject) => {
    const args = [
      '-h', dbConfig.host,
      '-p', String(dbConfig.port),
      '-U', dbConfig.user,
      '-d', dbConfig.database,
      '--no-owner',           // 소유자 정보 제외
      '--no-privileges',      // 권한 정보 제외 (--no-acl 대신)
      '--if-exists',          // DROP 문에 IF EXISTS 추가
      '--clean',              // DROP 문 포함
      '--create',             // CREATE DATABASE 포함하지 않음 (통갈이 모드용)
      '--verbose'
    ];
    
    // 특정 테이블만 덤프하는 경우
    if (options.tables && Array.isArray(options.tables)) {
      options.tables.forEach(table => {
        args.push('-t', table);
      });
    }
    
    // 특정 스키마만 덤프하는 경우
    if (options.schema) {
      args.push('-n', options.schema);
    }
    
    // 데이터 제외 (스키마만)
    if (options.schemaOnly) {
      args.push('--schema-only');
    }
    
    // 데이터만 (스키마 제외)
    if (options.dataOnly) {
      args.push('--data-only');
    }
    
    const env = {
      ...process.env,
      PGPASSWORD: dbConfig.password
    };
    
    // pg_dump로 SQL 덤프 생성
    const pgDump = spawn('pg_dump', args, { env });
    const output = createWriteStream(outputPath);
    
    let stderr = '';
    
    // stdout을 파일로 리다이렉트
    pgDump.stdout.pipe(output);
    
    pgDump.stderr.on('data', (data) => {
      stderr += data.toString();
      if (options.onProgress) {
        options.onProgress(data.toString());
      }
    });
    
    pgDump.on('close', (code) => {
      output.end();
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`pg_dump 실패 (코드: ${code})\n${stderr}`));
      }
    });
    
    pgDump.on('error', (error) => {
      output.end();
      reject(new Error(`pg_dump 실행 실패: ${error.message}`));
    });
  });
}

/**
 * PostgreSQL 전체 덤프 복원 - 통갈이 모드 (psql 기반)
 * 기존 데이터베이스를 완전히 DROP하고 새로 복원
 * @param {object} dbConfig - 데이터베이스 설정
 * @param {string} dumpPath - 덤프 파일 경로 (SQL 파일)
 * @param {object} options - 복원 옵션
 * @returns {Promise<void>}
 */
export async function restoreDumpReplace(dbConfig, dumpPath, options = {}) {
  if (!existsSync(dumpPath)) {
    throw new Error(`덤프 파일을 찾을 수 없습니다: ${dumpPath}`);
  }
  
  return new Promise((resolve, reject) => {
    const args = [
      '-h', dbConfig.host,
      '-p', String(dbConfig.port),
      '-U', dbConfig.user,
      '-d', dbConfig.database,
      '-v', 'ON_ERROR_STOP=1',  // 에러 발생 시 중단
      '-f', dumpPath             // SQL 파일 실행
    ];
    
    // 단일 트랜잭션으로 실행 (원자성 보장)
    if (options.singleTransaction !== false) {
      args.push('--single-transaction');
    }
    
    const env = {
      ...process.env,
      PGPASSWORD: dbConfig.password
    };
    
    const psql = spawn('psql', args, { env });
    
    let stdout = '';
    let stderr = '';
    
    psql.stdout.on('data', (data) => {
      stdout += data.toString();
      if (options.onProgress) {
        options.onProgress(data.toString());
      }
    });
    
    psql.stderr.on('data', (data) => {
      stderr += data.toString();
      if (options.onProgress) {
        options.onProgress(data.toString());
      }
    });
    
    psql.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`psql 복원 실패 (코드: ${code})\n${stderr}`));
      }
    });
    
    psql.on('error', (error) => {
      reject(new Error(`psql 실행 실패: ${error.message}`));
    });
  });
}

/**
 * 데이터베이스 연결 테스트
 * @param {object} dbConfig - 데이터베이스 설정
 * @returns {Promise<boolean>}
 */
export async function testConnection(dbConfig) {
  return new Promise((resolve, reject) => {
    const args = [
      '-h', dbConfig.host,
      '-p', String(dbConfig.port),
      '-U', dbConfig.user,
      '-d', dbConfig.database,
      '-c', 'SELECT 1'
    ];
    
    const env = {
      ...process.env,
      PGPASSWORD: dbConfig.password
    };
    
    const psql = spawn('psql', args, { env });
    
    psql.on('close', (code) => {
      resolve(code === 0);
    });
    
    psql.on('error', (error) => {
      reject(error);
    });
  });
}

/**
 * 데이터베이스 정보 조회
 * @param {object} dbConfig - 데이터베이스 설정
 * @returns {Promise<object>}
 */
export async function getDatabaseInfo(dbConfig) {
  return new Promise((resolve, reject) => {
    const query = `
      SELECT 
        pg_database_size(current_database()) as size,
        (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public') as table_count,
        current_database() as database_name,
        version() as pg_version
    `;
    
    const args = [
      '-h', dbConfig.host,
      '-p', String(dbConfig.port),
      '-U', dbConfig.user,
      '-d', dbConfig.database,
      '-t', // 튜플만 출력
      '-c', query
    ];
    
    const env = {
      ...process.env,
      PGPASSWORD: dbConfig.password
    };
    
    const psql = spawn('psql', args, { env });
    
    let stdout = '';
    let stderr = '';
    
    psql.stdout.on('data', (data) => {
      stdout += data.toString();
    });
    
    psql.stderr.on('data', (data) => {
      stderr += data.toString();
    });
    
    psql.on('close', (code) => {
      if (code === 0) {
        try {
          const parts = stdout.trim().split('|').map(p => p.trim());
          resolve({
            size: parseInt(parts[0]),
            tableCount: parseInt(parts[1]),
            databaseName: parts[2],
            pgVersion: parts[3]
          });
        } catch (error) {
          reject(new Error('데이터베이스 정보 파싱 실패'));
        }
      } else {
        reject(new Error(`psql 실패: ${stderr}`));
      }
    });
    
    psql.on('error', (error) => {
      reject(error);
    });
  });
}

/**
 * PostgreSQL 도구 설치 확인 (pg_dump, psql)
 * @returns {Promise<boolean>}
 */
export async function checkPostgresTools() {
  const checkTool = (tool) => {
    return new Promise((resolve) => {
      const check = spawn(tool, ['--version']);
      check.on('close', (code) => resolve(code === 0));
      check.on('error', () => resolve(false));
    });
  };
  
  const [hasPgDump, hasPsql] = await Promise.all([
    checkTool('pg_dump'),
    checkTool('psql')
  ]);
  
  return hasPgDump && hasPsql;
}

