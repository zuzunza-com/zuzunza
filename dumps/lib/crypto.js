/**
 * 암호화/복호화 유틸리티
 * AES-256-GCM을 사용한 강력한 암호화
 */

import crypto from 'crypto';
import { createReadStream, createWriteStream, readFileSync } from 'fs';
import { pipeline } from 'stream/promises';
import { createGzip, createGunzip } from 'zlib';
import { Readable } from 'stream';

const ALGORITHM = 'aes-256-gcm';
const KEY_LENGTH = 32; // 256 bits
const IV_LENGTH = 16; // 128 bits
const SALT_LENGTH = 64;
const TAG_LENGTH = 16;
const PBKDF2_ITERATIONS = 100000;

/**
 * 비밀번호로부터 암호화 키 생성
 */
function deriveKey(password, salt) {
  return crypto.pbkdf2Sync(
    password,
    salt,
    PBKDF2_ITERATIONS,
    KEY_LENGTH,
    'sha512'
  );
}

/**
 * 파일 암호화 (압축 포함)
 * @param {string} inputPath - 입력 파일 경로
 * @param {string} outputPath - 출력 파일 경로
 * @param {string} password - 암호화 비밀번호
 */
export async function encryptFile(inputPath, outputPath, password) {
  return new Promise((resolve, reject) => {
    try {
      // Salt와 IV 생성
      const salt = crypto.randomBytes(SALT_LENGTH);
      const iv = crypto.randomBytes(IV_LENGTH);
      
      // 키 생성
      const key = deriveKey(password, salt);
      
      // 암호화 스트림 생성
      const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
      
      // 파일 스트림
      const input = createReadStream(inputPath);
      const output = createWriteStream(outputPath);
      
      // 고압축 gzip 스트림 (compression level 9)
      const gzip = createGzip({ level: 9 });
      
      // 헤더 작성 (salt + iv)
      output.write(salt);
      output.write(iv);
      
      // 스트림 파이프라인
      input
        .pipe(gzip)
        .pipe(cipher)
        .pipe(output);
      
      output.on('finish', () => {
        // Auth tag를 파일 끝에 추가
        const tag = cipher.getAuthTag();
        const tagOutput = createWriteStream(outputPath, { flags: 'a' });
        tagOutput.write(tag);
        tagOutput.end();
        tagOutput.on('finish', () => resolve());
        tagOutput.on('error', reject);
      });
      
      input.on('error', reject);
      output.on('error', reject);
      cipher.on('error', reject);
      gzip.on('error', reject);
      
    } catch (error) {
      reject(error);
    }
  });
}

/**
 * 파일 복호화 (압축 해제 포함)
 * @param {string} inputPath - 암호화된 파일 경로
 * @param {string} outputPath - 출력 파일 경로
 * @param {string} password - 복호화 비밀번호
 */
export async function decryptFile(inputPath, outputPath, password) {
  return new Promise((resolve, reject) => {
    try {
      const fileBuffer = readFileSync(inputPath);
      
      // 헤더에서 salt와 iv 추출
      const salt = fileBuffer.subarray(0, SALT_LENGTH);
      const iv = fileBuffer.subarray(SALT_LENGTH, SALT_LENGTH + IV_LENGTH);
      
      // 파일 끝에서 auth tag 추출
      const tag = fileBuffer.subarray(fileBuffer.length - TAG_LENGTH);
      const encryptedData = fileBuffer.subarray(
        SALT_LENGTH + IV_LENGTH,
        fileBuffer.length - TAG_LENGTH
      );
      
      // 키 생성
      const key = deriveKey(password, salt);
      
      // 복호화 스트림 생성
      const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
      decipher.setAuthTag(tag);
      
      // 스트림 생성
      const gunzip = createGunzip();
      const output = createWriteStream(outputPath);
      
      // 암호화된 데이터를 버퍼로 변환하여 처리
      const encryptedStream = Readable.from(encryptedData);
      
      // 스트림 파이프라인
      encryptedStream
        .pipe(decipher)
        .pipe(gunzip)
        .pipe(output);
      
      output.on('finish', () => resolve());
      
      encryptedStream.on('error', reject);
      decipher.on('error', (err) => {
        reject(new Error('복호화 실패: 잘못된 비밀번호이거나 손상된 파일입니다.'));
      });
      gunzip.on('error', reject);
      output.on('error', reject);
      
    } catch (error) {
      reject(error);
    }
  });
}

/**
 * 비밀번호 강도 검증
 * @param {string} password
 * @returns {object} { valid: boolean, message: string }
 */
export function validatePassword(password) {
  if (!password || password.length < 12) {
    return {
      valid: false,
      message: '비밀번호는 최소 12자 이상이어야 합니다.'
    };
  }
  
  const hasUpper = /[A-Z]/.test(password);
  const hasLower = /[a-z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const hasSpecial = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password);
  
  const strength = [hasUpper, hasLower, hasNumber, hasSpecial].filter(Boolean).length;
  
  if (strength < 3) {
    return {
      valid: false,
      message: '비밀번호는 대문자, 소문자, 숫자, 특수문자 중 최소 3가지를 포함해야 합니다.'
    };
  }
  
  return { valid: true, message: '강력한 비밀번호입니다.' };
}

/**
 * 파일 해시 생성 (무결성 검증용)
 * @param {string} filePath
 * @returns {Promise<string>}
 */
export async function calculateFileHash(filePath) {
  return new Promise((resolve, reject) => {
    const hash = crypto.createHash('sha256');
    const stream = createReadStream(filePath);
    
    stream.on('data', (chunk) => hash.update(chunk));
    stream.on('end', () => resolve(hash.digest('hex')));
    stream.on('error', reject);
  });
}

