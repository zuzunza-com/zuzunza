/**
 * 데이터베이스 덤프 및 복원 유틸리티
 */

import { spawn } from 'child_process';
import { existsSync, unlinkSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * PostgreSQL 덤프 생성
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
      '-f', outputPath,
      '--format=custom', // 커스텀 포맷 (압축 지원)
      '--compress=9',    // 최대 압축
      '--verbose',
      '--no-owner',      // 소유자 정보 제외
      '--no-acl',        // 권한 정보 제외
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
    
    const pgDump = spawn('pg_dump', args, { env });
    
    let stderr = '';
    
    pgDump.stderr.on('data', (data) => {
      stderr += data.toString();
      if (options.onProgress) {
        options.onProgress(data.toString());
      }
    });
    
    pgDump.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`pg_dump 실패 (코드: ${code})\n${stderr}`));
      }
    });
    
    pgDump.on('error', (error) => {
      reject(new Error(`pg_dump 실행 실패: ${error.message}`));
    });
  });
}

/**
 * PostgreSQL 덤프 복원 - 갈아엎기 모드 (DROP & CREATE)
 * @param {object} dbConfig - 데이터베이스 설정
 * @param {string} dumpPath - 덤프 파일 경로
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
      '--verbose',
      '--clean',           // 기존 객체 삭제
      '--if-exists',       // 객체가 없어도 오류 무시
      '--no-owner',
      '--no-acl',
      dumpPath
    ];
    
    // 단일 트랜잭션으로 실행 (원자성 보장)
    if (options.singleTransaction !== false) {
      args.push('--single-transaction');
    }
    
    // 특정 테이블만 복원
    if (options.tables && Array.isArray(options.tables)) {
      options.tables.forEach(table => {
        args.push('-t', table);
      });
    }
    
    const env = {
      ...process.env,
      PGPASSWORD: dbConfig.password
    };
    
    const pgRestore = spawn('pg_restore', args, { env });
    
    let stderr = '';
    
    pgRestore.stderr.on('data', (data) => {
      stderr += data.toString();
      if (options.onProgress) {
        options.onProgress(data.toString());
      }
    });
    
    pgRestore.on('close', (code) => {
      // pg_restore는 경고가 있어도 0이 아닌 코드를 반환할 수 있음
      // 하지만 실제 오류인지 확인 필요
      if (code === 0 || (code === 1 && !stderr.includes('ERROR'))) {
        resolve();
      } else {
        reject(new Error(`pg_restore 실패 (코드: ${code})\n${stderr}`));
      }
    });
    
    pgRestore.on('error', (error) => {
      reject(new Error(`pg_restore 실행 실패: ${error.message}`));
    });
  });
}

/**
 * PostgreSQL 덤프 복원 - 덮어쓰기 모드 (UPDATE/INSERT)
 * @param {object} dbConfig - 데이터베이스 설정
 * @param {string} dumpPath - 덤프 파일 경로
 * @param {object} options - 복원 옵션
 * @returns {Promise<void>}
 */
export async function restoreDumpMerge(dbConfig, dumpPath, options = {}) {
  if (!existsSync(dumpPath)) {
    throw new Error(`덤프 파일을 찾을 수 없습니다: ${dumpPath}`);
  }
  
  return new Promise((resolve, reject) => {
    const args = [
      '-h', dbConfig.host,
      '-p', String(dbConfig.port),
      '-U', dbConfig.user,
      '-d', dbConfig.database,
      '--verbose',
      '--no-owner',
      '--no-acl',
      '--data-only',       // 데이터만 복원 (스키마는 유지)
      dumpPath
    ];
    
    // 단일 트랜잭션으로 실행
    if (options.singleTransaction !== false) {
      args.push('--single-transaction');
    }
    
    // 특정 테이블만 복원
    if (options.tables && Array.isArray(options.tables)) {
      options.tables.forEach(table => {
        args.push('-t', table);
      });
    }
    
    // 오류 발생 시 계속 진행 (덮어쓰기 모드)
    if (options.continueOnError !== false) {
      args.push('--no-data-for-failed-tables');
    }
    
    const env = {
      ...process.env,
      PGPASSWORD: dbConfig.password
    };
    
    const pgRestore = spawn('pg_restore', args, { env });
    
    let stderr = '';
    
    pgRestore.stderr.on('data', (data) => {
      stderr += data.toString();
      if (options.onProgress) {
        options.onProgress(data.toString());
      }
    });
    
    pgRestore.on('close', (code) => {
      // 덮어쓰기 모드에서는 일부 오류는 정상 (중복 키 등)
      if (code === 0 || (stderr.includes('duplicate key') || stderr.includes('already exists'))) {
        resolve();
      } else {
        reject(new Error(`pg_restore 실패 (코드: ${code})\n${stderr}`));
      }
    });
    
    pgRestore.on('error', (error) => {
      reject(new Error(`pg_restore 실행 실패: ${error.message}`));
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
 * pg_dump/pg_restore 설치 확인
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
  
  const [hasPgDump, hasPgRestore] = await Promise.all([
    checkTool('pg_dump'),
    checkTool('pg_restore')
  ]);
  
  return hasPgDump && hasPgRestore;
}

