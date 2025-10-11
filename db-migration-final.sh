#!/bin/bash

# 최종 DB 병합 스크립트 (UUID 함수 문제 해결)

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

# 재시도할 테이블
RETRY_TABLES=(
    "bbs_comments"
    "user_game_logs"
)

DUMP_DIR="/tmp/db_migration_final_$(date +%Y%m%d_%H%M%S)"
mkdir -p ${DUMP_DIR}

echo "================================"
echo "최종 테이블 병합"
echo "================================"

for TABLE in "${RETRY_TABLES[@]}"; do
    echo ""
    echo "처리 중: ${TABLE}"
    echo "---"
    
    # 테이블 구조 덤프
    echo "  1. 테이블 구조 덤프..."
    PGPASSWORD="${SOURCE_PASS}" pg_dump \
        -h ${SOURCE_HOST} \
        -p ${SOURCE_PORT} \
        -U ${SOURCE_USER} \
        -d ${SOURCE_DB} \
        -t ${TABLE} \
        --schema-only \
        --no-owner \
        --no-privileges \
        --clean \
        --if-exists \
        -f "${DUMP_DIR}/${TABLE}_schema.sql"
    
    # UUID 함수 참조 수정
    sed -i 's/extensions\.uuid_generate_v4()/public.uuid_generate_v4()/g' "${DUMP_DIR}/${TABLE}_schema.sql"
    sed -i 's/uuid_generate_v4()/public.uuid_generate_v4()/g' "${DUMP_DIR}/${TABLE}_schema.sql"
    
    # 구조 복원
    echo "  2. 테이블 구조 복원..."
    PGPASSWORD="${TARGET_PASS}" psql \
        -h ${TARGET_HOST} \
        -p ${TARGET_PORT} \
        -U ${TARGET_USER} \
        -d ${TARGET_DB} \
        -f "${DUMP_DIR}/${TABLE}_schema.sql" \
        > "${DUMP_DIR}/${TABLE}_schema_restore.log" 2>&1
    
    # 데이터 덤프 (INSERT 방식)
    echo "  3. 데이터 덤프 (INSERT)..."
    PGPASSWORD="${SOURCE_PASS}" pg_dump \
        -h ${SOURCE_HOST} \
        -p ${SOURCE_PORT} \
        -U ${SOURCE_USER} \
        -d ${SOURCE_DB} \
        -t ${TABLE} \
        --data-only \
        --inserts \
        --no-owner \
        --no-privileges \
        -f "${DUMP_DIR}/${TABLE}_data.sql"
    
    # 데이터 복원
    echo "  4. 데이터 복원..."
    PGPASSWORD="${TARGET_PASS}" psql \
        -h ${TARGET_HOST} \
        -p ${TARGET_PORT} \
        -U ${TARGET_USER} \
        -d ${TARGET_DB} \
        -f "${DUMP_DIR}/${TABLE}_data.sql" \
        > "${DUMP_DIR}/${TABLE}_data_restore.log" 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  ✓ 복원 완료"
        
        # 데이터 건수 확인
        ROW_COUNT=$(PGPASSWORD="${TARGET_PASS}" psql \
            -h ${TARGET_HOST} \
            -p ${TARGET_PORT} \
            -U ${TARGET_USER} \
            -d ${TARGET_DB} \
            -t -c "SELECT COUNT(*) FROM ${TABLE};" 2>&1 | tr -d ' ')
        echo "  → ${TABLE}: ${ROW_COUNT} rows"
    else
        echo "  ⚠ 복원 중 경고 (로그: ${DUMP_DIR}/${TABLE}_data_restore.log)"
    fi
done

echo ""
echo "================================"
echo "최종 병합 작업 완료"
echo "================================"
echo ""

# 모든 병합된 테이블 확인
echo "병합된 테이블 목록:"
PGPASSWORD="${TARGET_PASS}" psql \
    -h ${TARGET_HOST} \
    -p ${TARGET_PORT} \
    -U ${TARGET_USER} \
    -d ${TARGET_DB} \
    -c "SELECT tablename FROM pg_tables WHERE schemaname='public' AND tablename IN ('app_settings', 'bbs_comments', 'bbs_file', 'cached_recommendations', 'categories', 'category_vectors', 'games', 'game_statuses', 'posts', 'profiles', 'seo_metadata', 'site_settings', 'user_game_logs', 'user_roles', 'user_status') ORDER BY tablename;"

echo ""
echo "주요 테이블 데이터 건수:"
PGPASSWORD="${TARGET_PASS}" psql \
    -h ${TARGET_HOST} \
    -p ${TARGET_PORT} \
    -U ${TARGET_USER} \
    -d ${TARGET_DB} \
    -c "SELECT 'games' as table_name, COUNT(*) FROM games
        UNION ALL SELECT 'posts', COUNT(*) FROM posts
        UNION ALL SELECT 'profiles', COUNT(*) FROM profiles
        UNION ALL SELECT 'bbs_comments', COUNT(*) FROM bbs_comments
        UNION ALL SELECT 'user_game_logs', COUNT(*) FROM user_game_logs
        ORDER BY table_name;"

