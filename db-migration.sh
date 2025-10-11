#!/bin/bash

# 데이터베이스 병합 스크립트
# 소스: 218.145.31.8:5432 (kidszzanggame DB)
# 대상: 218.145.31.8:5317 (neotrinity DB)

set -e

SOURCE_HOST="218.145.31.8"
SOURCE_PORT="5432"
SOURCE_USER="postgres.your-tenant-id"
SOURCE_PASS="so0ptmzb0pf"
SOURCE_DB="postgres"

TARGET_HOST="218.145.31.8"
TARGET_PORT="5317"
TARGET_USER="postgres"
TARGET_PASS="sbvotmdnjem"
TARGET_DB="postgres"

# 중복 테이블 (병합 시 제외)
EXCLUDE_TABLES="comments"

# 병합할 테이블 목록 (중복 제외)
TABLES=(
    "app_settings"
    "bbs_comments"
    "bbs_file"
    "cached_recommendations"
    "cached_trend_vector"
    "cached_user_vectors"
    "categories"
    "category_vectors"
    "chat_messages"
    "chat_reports"
    "chn_list"
    "contact_submissions"
    "game_statuses"
    "games"
    "general_settings"
    "posts"
    "profiles"
    "seo_metadata"
    "site_settings"
    "user_game_logs"
    "user_roles"
    "user_status"
)

echo "================================"
echo "데이터베이스 병합 작업 시작"
echo "================================"
echo "소스: ${SOURCE_HOST}:${SOURCE_PORT}"
echo "대상: ${TARGET_HOST}:${TARGET_PORT}"
echo "제외: ${EXCLUDE_TABLES}"
echo "================================"

# 임시 디렉토리 생성
DUMP_DIR="/tmp/db_migration_$(date +%Y%m%d_%H%M%S)"
mkdir -p ${DUMP_DIR}

echo "임시 디렉토리: ${DUMP_DIR}"

# 각 테이블 덤프 및 복원
for TABLE in "${TABLES[@]}"; do
    echo ""
    echo "처리 중: ${TABLE}"
    echo "---"
    
    # 테이블 구조 및 데이터 덤프
    echo "  1. 덤프 중..."
    PGPASSWORD="${SOURCE_PASS}" pg_dump \
        -h ${SOURCE_HOST} \
        -p ${SOURCE_PORT} \
        -U ${SOURCE_USER} \
        -d ${SOURCE_DB} \
        -t ${TABLE} \
        --no-owner \
        --no-privileges \
        --clean \
        --if-exists \
        -f "${DUMP_DIR}/${TABLE}.sql"
    
    if [ $? -eq 0 ]; then
        echo "  ✓ 덤프 완료"
        
        # 대상 DB에 복원
        echo "  2. 복원 중..."
        PGPASSWORD="${TARGET_PASS}" psql \
            -h ${TARGET_HOST} \
            -p ${TARGET_PORT} \
            -U ${TARGET_USER} \
            -d ${TARGET_DB} \
            -f "${DUMP_DIR}/${TABLE}.sql" \
            -v ON_ERROR_STOP=0 \
            > "${DUMP_DIR}/${TABLE}_restore.log" 2>&1
        
        if [ $? -eq 0 ]; then
            echo "  ✓ 복원 완료"
        else
            echo "  ⚠ 복원 중 경고 발생 (로그 확인: ${DUMP_DIR}/${TABLE}_restore.log)"
        fi
    else
        echo "  ✗ 덤프 실패"
    fi
done

echo ""
echo "================================"
echo "병합 작업 완료"
echo "================================"
echo "로그 디렉토리: ${DUMP_DIR}"
echo ""
echo "확인 명령어:"
echo "  PGPASSWORD='${TARGET_PASS}' psql -h ${TARGET_HOST} -p ${TARGET_PORT} -U ${TARGET_USER} -d ${TARGET_DB} -c '\dt'"
echo ""

