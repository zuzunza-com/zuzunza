#!/usr/bin/env node

/**
 * Zuzunza 데이터베이스 덤프 유틸리티
 * 암호화된 데이터베이스 백업 및 복원
 */

import { Command } from 'commander';
import inquirer from 'inquirer';
import chalk from 'chalk';
import ora from 'ora';
import { existsSync, statSync, unlinkSync, mkdtempSync, rmSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { tmpdir } from 'os';

import { getDatabaseConfig, getAvailableEnvironments, maskSensitiveInfo } from './lib/config-loader.js';
import { encryptFile, decryptFile, validatePassword, calculateFileHash } from './lib/crypto.js';
import { 
  createDump, 
  restoreDumpReplace, 
  restoreDumpMerge,
  testConnection,
  getDatabaseInfo,
  checkPostgresTools
} from './lib/database.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const program = new Command();

// 버전 정보
program
  .name('zuzunza-dump')
  .description('암호화된 데이터베이스 덤프 및 복원 유틸리티')
  .version('1.0.0');

/**
 * 파일 크기를 읽기 쉬운 형식으로 변환
 */
function formatBytes(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

/**
 * 현재 타임스탬프 생성
 */
function getTimestamp() {
  return new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
}

/**
 * 덤프 명령어
 */
program
  .command('dump')
  .description('데이터베이스 덤프 생성 (암호화)')
  .option('-e, --env <environment>', '환경 선택 (development/production)', 'production')
  .option('-o, --output <path>', '출력 파일 경로')
  .option('-p, --password <password>', '암호화 비밀번호')
  .option('--no-encrypt', '암호화하지 않음')
  .option('--schema-only', '스키마만 덤프')
  .option('--data-only', '데이터만 덤프')
  .action(async (options) => {
    console.log(chalk.bold.cyan('\n🗄️  Zuzunza 데이터베이스 덤프 유틸리티\n'));
    
    let tempDumpPath = null;
    let tempDir = null;
    
    // 종료 시 임시 파일 및 디렉토리 삭제 보장
    const cleanupTempFiles = () => {
      try {
        if (tempDir && existsSync(tempDir)) {
          rmSync(tempDir, { recursive: true, force: true });
          console.log(chalk.gray('🧹 임시 파일 삭제 완료'));
        }
      } catch (error) {
        console.log(chalk.yellow(`⚠️  임시 파일 삭제 실패: ${error.message}`));
      }
    };
    
    // 프로세스 종료 시 임시 파일 삭제
    process.on('exit', cleanupTempFiles);
    process.on('SIGINT', () => {
      cleanupTempFiles();
      process.exit(130);
    });
    process.on('SIGTERM', () => {
      cleanupTempFiles();
      process.exit(143);
    });
    
    try {
      // PostgreSQL 도구 확인
      const spinner = ora('PostgreSQL 도구 확인 중...').start();
      const hasTools = await checkPostgresTools();
      if (!hasTools) {
        spinner.fail('pg_dump/pg_restore가 설치되어 있지 않습니다.');
        console.log(chalk.yellow('\nPostgreSQL 클라이언트 도구를 설치해주세요:'));
        console.log(chalk.gray('  Ubuntu/Debian: sudo apt-get install postgresql-client'));
        console.log(chalk.gray('  macOS: brew install postgresql'));
        process.exit(1);
      }
      spinner.succeed('PostgreSQL 도구 확인 완료');
      
      // 환경 확인
      const availableEnvs = getAvailableEnvironments();
      if (!availableEnvs.includes(options.env)) {
        console.log(chalk.red(`\n❌ 환경 '${options.env}'를 찾을 수 없습니다.`));
        console.log(chalk.yellow(`사용 가능한 환경: ${availableEnvs.join(', ')}`));
        process.exit(1);
      }
      
      // 데이터베이스 설정 로드
      const dbConfig = getDatabaseConfig(options.env);
      console.log(chalk.gray(`\n📊 환경: ${options.env}`));
      console.log(chalk.gray(`📍 데이터베이스: ${dbConfig.host}:${dbConfig.port}/${dbConfig.database}`));
      
      // 연결 테스트
      const testSpinner = ora('데이터베이스 연결 테스트...').start();
      try {
        const connected = await testConnection(dbConfig);
        if (!connected) {
          testSpinner.fail('데이터베이스 연결 실패');
          process.exit(1);
        }
        testSpinner.succeed('데이터베이스 연결 성공');
      } catch (error) {
        testSpinner.fail(`연결 실패: ${error.message}`);
        process.exit(1);
      }
      
      // 데이터베이스 정보 조회
      try {
        const dbInfo = await getDatabaseInfo(dbConfig);
        console.log(chalk.gray(`📦 데이터베이스 크기: ${formatBytes(dbInfo.size)}`));
        console.log(chalk.gray(`📋 테이블 수: ${dbInfo.tableCount}`));
      } catch (error) {
        console.log(chalk.yellow(`⚠️  데이터베이스 정보 조회 실패: ${error.message}`));
      }
      
      // 출력 파일 경로 설정
      let outputPath = options.output;
      if (!outputPath) {
        const timestamp = getTimestamp();
        outputPath = join(__dirname, `zuzunza_${options.env}_${timestamp}.dump`);
      }
      
      // /tmp 폴더에 임시 덤프 파일 생성 (보안상 안전)
      tempDir = mkdtempSync(join(tmpdir(), 'zuzunza-dump-'));
      tempDumpPath = join(tempDir, 'temp.dump');
      const encryptedPath = options.encrypt !== false ? outputPath + '.encrypted' : outputPath;
      
      // 암호화 비밀번호 입력
      let password = options.password;
      if (options.encrypt !== false && !password) {
        const answers = await inquirer.prompt([
          {
            type: 'password',
            name: 'password',
            message: '암호화 비밀번호를 입력하세요 (12자 이상, 대소문자/숫자/특수문자 포함):',
            mask: '*',
            validate: (input) => {
              const validation = validatePassword(input);
              return validation.valid || validation.message;
            }
          },
          {
            type: 'password',
            name: 'passwordConfirm',
            message: '비밀번호를 다시 입력하세요:',
            mask: '*',
            validate: (input, answers) => {
              return input === answers.password || '비밀번호가 일치하지 않습니다.';
            }
          }
        ]);
        password = answers.password;
      }
      
      // 덤프 생성
      console.log(chalk.cyan('\n📤 데이터베이스 덤프 생성 중...\n'));
      const dumpSpinner = ora('덤프 파일 생성 중...').start();
      
      try {
        await createDump(dbConfig, tempDumpPath, {
          schemaOnly: options.schemaOnly,
          dataOnly: options.dataOnly,
          onProgress: (msg) => {
            if (msg.includes('processing')) {
              dumpSpinner.text = `덤프 중: ${msg.substring(0, 60)}...`;
            }
          }
        });
        
        const dumpSize = statSync(tempDumpPath).size;
        dumpSpinner.succeed(`덤프 파일 생성 완료 (${formatBytes(dumpSize)})`);
      } catch (error) {
        dumpSpinner.fail('덤프 생성 실패');
        throw error;
      }
      
      // 암호화
      if (options.encrypt !== false) {
        console.log(chalk.cyan('\n🔐 파일 암호화 중...\n'));
        const encryptSpinner = ora('암호화 및 압축 중...').start();
        
        try {
          await encryptFile(tempDumpPath, encryptedPath, password);
          
          const encryptedSize = statSync(encryptedPath).size;
          const originalSize = statSync(tempDumpPath).size;
          const ratio = ((1 - encryptedSize / originalSize) * 100).toFixed(1);
          
          encryptSpinner.succeed(
            `암호화 완료 (${formatBytes(encryptedSize)}, 압축률: ${ratio}%)`
          );
          
          // 임시 파일 및 디렉토리 삭제
          if (tempDir && existsSync(tempDir)) {
            rmSync(tempDir, { recursive: true, force: true });
            tempDir = null;
            tempDumpPath = null;
          }
        } catch (error) {
          encryptSpinner.fail('암호화 실패');
          // 오류 발생 시에도 임시 파일 및 디렉토리 삭제
          if (tempDir && existsSync(tempDir)) {
            rmSync(tempDir, { recursive: true, force: true });
            tempDir = null;
            tempDumpPath = null;
          }
          throw error;
        }
        
        // 파일 해시 계산
        const hashSpinner = ora('파일 무결성 해시 계산 중...').start();
        try {
          const hash = await calculateFileHash(encryptedPath);
          hashSpinner.succeed(`SHA-256: ${hash.substring(0, 16)}...`);
        } catch (error) {
          hashSpinner.warn('해시 계산 실패');
        }
      }
      
      console.log(chalk.bold.green('\n✅ 덤프 완료!\n'));
      console.log(chalk.gray(`📁 파일 위치: ${encryptedPath}\n`));
      
      if (options.encrypt !== false) {
        console.log(chalk.yellow('⚠️  비밀번호를 안전한 곳에 보관하세요!'));
        console.log(chalk.gray('   비밀번호를 잃어버리면 복원할 수 없습니다.\n'));
      }
      
    } catch (error) {
      console.error(chalk.red(`\n❌ 오류 발생: ${error.message}\n`));
      process.exit(1);
    }
  });

/**
 * 복원 명령어
 */
program
  .command('restore')
  .description('데이터베이스 복원 (복호화)')
  .option('-e, --env <environment>', '환경 선택 (development/production)', 'production')
  .option('-f, --file <path>', '덤프 파일 경로 (필수)', null)
  .option('-p, --password <password>', '복호화 비밀번호')
  .option('-m, --mode <mode>', '복원 모드 (replace/merge)', 'replace')
  .option('--no-decrypt', '복호화하지 않음 (평문 덤프)')
  .option('--force', '확인 없이 실행')
  .action(async (options) => {
    console.log(chalk.bold.cyan('\n🔄 Zuzunza 데이터베이스 복원 유틸리티\n'));
    
    let tempDecryptPath = null;
    let tempDir = null;
    
    // 종료 시 임시 파일 및 디렉토리 삭제 보장
    const cleanupTempFiles = () => {
      try {
        if (tempDir && existsSync(tempDir)) {
          rmSync(tempDir, { recursive: true, force: true });
          console.log(chalk.gray('🧹 임시 파일 삭제 완료'));
        }
      } catch (error) {
        console.log(chalk.yellow(`⚠️  임시 파일 삭제 실패: ${error.message}`));
      }
    };
    
    // 프로세스 종료 시 임시 파일 삭제
    process.on('exit', cleanupTempFiles);
    process.on('SIGINT', () => {
      cleanupTempFiles();
      process.exit(130);
    });
    process.on('SIGTERM', () => {
      cleanupTempFiles();
      process.exit(143);
    });
    
    try {
      // 파일 경로 확인
      if (!options.file) {
        console.log(chalk.red('❌ 덤프 파일 경로를 지정해주세요. (-f 옵션)'));
        process.exit(1);
      }
      
      if (!existsSync(options.file)) {
        console.log(chalk.red(`❌ 파일을 찾을 수 없습니다: ${options.file}`));
        process.exit(1);
      }
      
      const fileSize = statSync(options.file).size;
      console.log(chalk.gray(`📁 덤프 파일: ${options.file}`));
      console.log(chalk.gray(`📦 파일 크기: ${formatBytes(fileSize)}`));
      
      // PostgreSQL 도구 확인
      const spinner = ora('PostgreSQL 도구 확인 중...').start();
      const hasTools = await checkPostgresTools();
      if (!hasTools) {
        spinner.fail('pg_dump/pg_restore가 설치되어 있지 않습니다.');
        process.exit(1);
      }
      spinner.succeed('PostgreSQL 도구 확인 완료');
      
      // 데이터베이스 설정 로드
      const dbConfig = getDatabaseConfig(options.env);
      console.log(chalk.gray(`\n📊 환경: ${options.env}`));
      console.log(chalk.gray(`📍 데이터베이스: ${dbConfig.host}:${dbConfig.port}/${dbConfig.database}`));
      
      // 연결 테스트
      const testSpinner = ora('데이터베이스 연결 테스트...').start();
      try {
        const connected = await testConnection(dbConfig);
        if (!connected) {
          testSpinner.fail('데이터베이스 연결 실패');
          process.exit(1);
        }
        testSpinner.succeed('데이터베이스 연결 성공');
      } catch (error) {
        testSpinner.fail(`연결 실패: ${error.message}`);
        process.exit(1);
      }
      
      // 복원 모드 확인
      const mode = options.mode.toLowerCase();
      if (!['replace', 'merge'].includes(mode)) {
        console.log(chalk.red(`❌ 잘못된 복원 모드: ${mode}`));
        console.log(chalk.yellow('사용 가능한 모드: replace (갈아엎기), merge (덮어쓰기)'));
        process.exit(1);
      }
      
      // 경고 및 확인
      if (!options.force) {
        console.log(chalk.yellow.bold(`\n⚠️  경고: ${mode === 'replace' ? '갈아엎기' : '덮어쓰기'} 모드로 복원합니다!\n`));
        
        if (mode === 'replace') {
          console.log(chalk.red('   기존 데이터베이스의 모든 데이터가 삭제됩니다!'));
        } else {
          console.log(chalk.yellow('   기존 데이터와 충돌할 수 있습니다.'));
        }
        
        const confirm = await inquirer.prompt([
          {
            type: 'confirm',
            name: 'proceed',
            message: '정말로 복원하시겠습니까?',
            default: false
          }
        ]);
        
        if (!confirm.proceed) {
          console.log(chalk.gray('\n복원이 취소되었습니다.\n'));
          process.exit(0);
        }
      }
      
      let dumpPath = options.file;
      
      // /tmp 폴더에 임시 복호화 파일 생성 (보안상 안전)
      tempDir = mkdtempSync(join(tmpdir(), 'zuzunza-restore-'));
      tempDecryptPath = join(tempDir, 'temp_decrypt.dump');
      
      // 복호화
      if (options.decrypt !== false) {
        let password = options.password;
        if (!password) {
          const answers = await inquirer.prompt([
            {
              type: 'password',
              name: 'password',
              message: '복호화 비밀번호를 입력하세요:',
              mask: '*'
            }
          ]);
          password = answers.password;
        }
        
        console.log(chalk.cyan('\n🔓 파일 복호화 중...\n'));
        const decryptSpinner = ora('복호화 및 압축 해제 중...').start();
        
        try {
          await decryptFile(options.file, tempDecryptPath, password);
          const decryptedSize = statSync(tempDecryptPath).size;
          decryptSpinner.succeed(`복호화 완료 (${formatBytes(decryptedSize)})`);
          dumpPath = tempDecryptPath;
        } catch (error) {
          decryptSpinner.fail('복호화 실패');
          throw error;
        }
      }
      
      // 복원 실행
      console.log(chalk.cyan('\n📥 데이터베이스 복원 중...\n'));
      const restoreSpinner = ora(`${mode === 'replace' ? '갈아엎기' : '덮어쓰기'} 복원 중...`).start();
      
      try {
        if (mode === 'replace') {
          await restoreDumpReplace(dbConfig, dumpPath, {
            onProgress: (msg) => {
              if (msg.includes('processing')) {
                restoreSpinner.text = `복원 중: ${msg.substring(0, 60)}...`;
              }
            }
          });
        } else {
          await restoreDumpMerge(dbConfig, dumpPath, {
            onProgress: (msg) => {
              if (msg.includes('processing')) {
                restoreSpinner.text = `복원 중: ${msg.substring(0, 60)}...`;
              }
            }
          });
        }
        
        restoreSpinner.succeed('데이터베이스 복원 완료');
      } catch (error) {
        restoreSpinner.fail('복원 실패');
        throw error;
      } finally {
        // 임시 파일 및 디렉토리 삭제
        if (tempDir && existsSync(tempDir)) {
          rmSync(tempDir, { recursive: true, force: true });
          tempDir = null;
          tempDecryptPath = null;
        }
      }
      
      console.log(chalk.bold.green('\n✅ 복원 완료!\n'));
      
    } catch (error) {
      console.error(chalk.red(`\n❌ 오류 발생: ${error.message}\n`));
      process.exit(1);
    }
  });

/**
 * 정보 명령어
 */
program
  .command('info')
  .description('데이터베이스 정보 조회')
  .option('-e, --env <environment>', '환경 선택', 'production')
  .action(async (options) => {
    console.log(chalk.bold.cyan('\n📊 데이터베이스 정보\n'));
    
    try {
      const dbConfig = getDatabaseConfig(options.env);
      
      console.log(chalk.gray('환경:'), chalk.white(options.env));
      console.log(chalk.gray('호스트:'), chalk.white(`${dbConfig.host}:${dbConfig.port}`));
      console.log(chalk.gray('데이터베이스:'), chalk.white(dbConfig.database));
      console.log(chalk.gray('사용자:'), chalk.white(dbConfig.user));
      
      const spinner = ora('데이터베이스 정보 조회 중...').start();
      
      try {
        const connected = await testConnection(dbConfig);
        if (!connected) {
          spinner.fail('데이터베이스 연결 실패');
          process.exit(1);
        }
        
        const dbInfo = await getDatabaseInfo(dbConfig);
        spinner.stop();
        
        console.log(chalk.gray('\n데이터베이스 크기:'), chalk.white(formatBytes(dbInfo.size)));
        console.log(chalk.gray('테이블 수:'), chalk.white(dbInfo.tableCount));
        console.log(chalk.gray('PostgreSQL 버전:'), chalk.white(dbInfo.pgVersion.split(',')[0]));
        console.log();
      } catch (error) {
        spinner.fail(`조회 실패: ${error.message}`);
      }
      
    } catch (error) {
      console.error(chalk.red(`\n❌ 오류 발생: ${error.message}\n`));
      process.exit(1);
    }
  });

// 프로그램 실행
program.parse(process.argv);

// 인자가 없으면 도움말 표시
if (process.argv.length === 2) {
  program.help();
}

