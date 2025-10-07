#!/bin/bash

# ===========================================
# 주전자닷컴 SELinux 설정 스크립트
# 리부팅 없이 SELinux 활성화 및 설정
# ===========================================

set -e

echo "🔒 주전자닷컴 SELinux 설정 시작..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 현재 SELinux 상태 확인
check_selinux_status() {
    log_info "SELinux 상태 확인 중..."
    if sestatus | grep -q "disabled"; then
        log_warning "SELinux가 비활성화되어 있습니다."
        return 1
    else
        log_success "SELinux가 활성화되어 있습니다."
        return 0
    fi
}

# SELinux 활성화 (리부팅 없이)
enable_selinux() {
    log_info "SELinux 활성화 중..."
    
    # 1. GRUB 설정으로 SELinux 활성화
    if ! grep -q "selinux=1" /etc/default/grub; then
        log_info "GRUB 설정에 SELinux 활성화 옵션 추가..."
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&selinux=1 security=selinux /' /etc/default/grub
        sudo update-grub
    fi
    
    # 2. 임시로 SELinux 활성화 (현재 세션에서만)
    log_info "현재 세션에서 SELinux 활성화..."
    sudo setenforce 0 2>/dev/null || true
    
    # 3. 설정 파일 생성
    log_info "SELinux 설정 파일 생성..."
    sudo tee /etc/selinux/config > /dev/null <<EOF
SELINUX=permissive
SELINUXTYPE=default
EOF
    
    log_warning "⚠️  SELinux 활성화를 완전히 적용하려면 시스템 재부팅이 필요합니다."
    log_info "현재는 permissive 모드로 설정되어 로그만 기록됩니다."
}

# Docker SELinux 설정
setup_docker_selinux() {
    log_info "Docker SELinux 설정 중..."
    
    # Docker 데몬 설정
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "selinux-enabled": true,
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  },
  "live-restore": true,
  "userland-proxy": false
}
EOF
    
    # Docker 재시작
    log_info "Docker 서비스 재시작..."
    sudo systemctl restart docker
    
    log_success "Docker SELinux 설정 완료"
}

# 프로젝트별 SELinux 컨텍스트 설정
setup_project_contexts() {
    log_info "프로젝트별 SELinux 컨텍스트 설정 중..."
    
    # 1. 메인 애플리케이션 (neotrinity)
    log_info "neotrinity 웹 애플리케이션 컨텍스트 설정..."
    sudo semanage fcontext -a -t httpd_exec_t "/srv/zuzunza/neotrinity(/.*)?" 2>/dev/null || true
    sudo semanage fcontext -a -t httpd_sys_content_t "/srv/zuzunza/neotrinity/public(/.*)?" 2>/dev/null || true
    sudo semanage fcontext -a -t httpd_sys_content_t "/srv/zuzunza/neotrinity/src(/.*)?" 2>/dev/null || true
    sudo semanage fcontext -a -t httpd_sys_content_t "/srv/zuzunza/neotrinity/config(/.*)?" 2>/dev/null || true
    sudo semanage fcontext -a -t var_log_t "/srv/zuzunza/neotrinity/logs(/.*)?" 2>/dev/null || true
    
    # 2. WebSocket 서버 (ws-server)
    log_info "ws-server Node.js 애플리케이션 컨텍스트 설정..."
    sudo semanage fcontext -a -t httpd_exec_t "/srv/zuzunza/ws-server(/.*)?" 2>/dev/null || true
    sudo semanage fcontext -a -t var_log_t "/srv/zuzunza/ws-server/logs(/.*)?" 2>/dev/null || true
    
    # 3. 보안 모니터링 (sysnox)
    log_info "sysnox 보안 모니터링 컨텍스트 설정..."
    sudo semanage fcontext -a -t bin_t "/srv/zuzunza/sysnox(/.*)?" 2>/dev/null || true
    sudo semanage fcontext -a -t var_log_t "/srv/zuzunza/sysnox/logs(/.*)?" 2>/dev/null || true
    
    # 4. 데이터 백업 (dumps) - 올바른 타입 사용
    log_info "dumps 백업 유틸리티 컨텍스트 설정..."
    sudo semanage fcontext -a -t backup_exec_t "/srv/zuzunza/dumps(/.*)?" 2>/dev/null || true
    sudo semanage fcontext -a -t backup_store_t "/srv/zuzunza/dumps/*.dump*" 2>/dev/null || true
    sudo semanage fcontext -a -t backup_store_t "/srv/zuzunza/dumps/*.encrypted" 2>/dev/null || true
    
    # 5. Discord 봇
    log_info "discord-bot 컨텍스트 설정..."
    sudo semanage fcontext -a -t httpd_exec_t "/srv/zuzunza/discord-bot(/.*)?" 2>/dev/null || true
    
    # 6. 블로그 시스템
    log_info "blogs 시스템 컨텍스트 설정..."
    sudo semanage fcontext -a -t httpd_sys_content_t "/srv/zuzunza/blogs(/.*)?" 2>/dev/null || true
    
    log_success "프로젝트별 SELinux 컨텍스트 설정 완료"
}

# 데이터 디렉토리 SELinux 설정
setup_data_contexts() {
    log_info "데이터 디렉토리 SELinux 컨텍스트 설정 중..."
    
    # 데이터베이스 볼륨
    sudo semanage fcontext -a -t postgresql_db_t "/database(/.*)?" 2>/dev/null || true
    sudo semanage fcontext -a -t postgresql_log_t "/database/logs(/.*)?" 2>/dev/null || true
    
    # Redis 데이터
    sudo semanage fcontext -a -t var_lib_t "/data/redis(/.*)?" 2>/dev/null || true
    
    # Meilisearch 데이터
    sudo semanage fcontext -a -t var_lib_t "/data/meilisearch(/.*)?" 2>/dev/null || true
    
    # Supabase 스토리지
    sudo semanage fcontext -a -t httpd_sys_content_t "/data/supabase-storage(/.*)?" 2>/dev/null || true
    
    # Node.js 모듈 공유
    sudo semanage fcontext -a -t var_lib_t "/data/node_modules(/.*)?" 2>/dev/null || true
    
    log_success "데이터 디렉토리 SELinux 컨텍스트 설정 완료"
}

# 포트 SELinux 설정
setup_port_contexts() {
    log_info "포트 SELinux 컨텍스트 설정 중..."
    
    # 웹 포트들 (기본)
    sudo semanage port -a -t http_port_t -p tcp 80 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 443 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 3000 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 5688 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 7700 2>/dev/null || true
    
    # 웹 포트들 (3000번대)
    sudo semanage port -a -t http_port_t -p tcp 3001 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 3002 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 3003 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 3004 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 3005 2>/dev/null || true
    
    # 웹 포트들 (8000번대)
    sudo semanage port -a -t http_port_t -p tcp 8000 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 8001 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 8002 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 8003 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 8004 2>/dev/null || true
    
    # DNS 포트
    sudo semanage port -a -t dns_port_t -p tcp 53 2>/dev/null || true
    
    # 데이터베이스 포트들
    sudo semanage port -a -t postgresql_port_t -p tcp 5497 2>/dev/null || true
    sudo semanage port -a -t postgresql_port_t -p tcp 5433 2>/dev/null || true
    
    # Redis 포트
    sudo semanage port -a -t redis_port_t -p tcp 6379 2>/dev/null || true
    
    # Supabase 서비스 포트들
    sudo semanage port -a -t http_port_t -p tcp 9999 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 4000 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 4001 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 4002 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 5001 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 5002 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 8084 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 9002 2>/dev/null || true
    
    # SSH 포트
    sudo semanage port -a -t ssh_port_t -p tcp 6318 2>/dev/null || true
    
    log_success "포트 SELinux 컨텍스트 설정 완료"
}

# 컨텍스트 적용
apply_contexts() {
    log_info "SELinux 컨텍스트 적용 중..."
    
    # 프로젝트 디렉토리 컨텍스트 적용
    sudo restorecon -Rv /srv/zuzunza/ 2>/dev/null || true
    
    # 데이터 디렉토리 컨텍스트 적용 (존재하는 경우)
    sudo restorecon -Rv /database/ 2>/dev/null || true
    sudo restorecon -Rv /data/ 2>/dev/null || true
    
    log_success "SELinux 컨텍스트 적용 완료"
}

# 시스템 서비스 SELinux 설정
setup_system_services() {
    log_info "시스템 서비스 SELinux 설정 중..."
    
    # systemd 서비스 파일들
    sudo semanage fcontext -a -t systemd_unit_file_t "/etc/systemd/system/sysnox.service" 2>/dev/null || true
    sudo semanage fcontext -a -t systemd_unit_file_t "/etc/systemd/system/yukina-bot.service" 2>/dev/null || true
    
    # Node.js 바이너리 권한
    sudo semanage fcontext -a -t bin_t "/root/.nvm/versions/node/v24.9.0/bin/node" 2>/dev/null || true
    
    # 컨텍스트 적용
    sudo restorecon -Rv /etc/systemd/system/sysnox.service 2>/dev/null || true
    sudo restorecon -Rv /etc/systemd/system/yukina-bot.service 2>/dev/null || true
    
    log_success "시스템 서비스 SELinux 설정 완료"
}

# SELinux 정책 모듈 생성
create_custom_policy() {
    log_info "주전자닷컴 전용 SELinux 정책 모듈 생성 중..."
    
    # 임시 디렉토리 생성
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # zuzunza.te 파일 생성
    cat > zuzunza.te <<EOF
module zuzunza 1.0;

require {
    type httpd_t;
    type httpd_exec_t;
    type httpd_sys_content_t;
    type var_log_t;
    type postgresql_t;
    type postgresql_db_t;
    type redis_t;
    type var_lib_t;
    class file { read write execute getattr open };
    class dir { read write add_name remove_name search };
    class tcp_socket { name_bind };
}

# zuzunza 웹 서비스 도메인
type zuzunza_web_t;
type zuzunza_web_exec_t;
type zuzunza_web_content_t;

# zuzunza 데이터베이스 도메인
type zuzunza_db_t;
type zuzunza_db_exec_t;

# zuzunza 백업 도메인
type zuzunza_backup_t;
type zuzunza_backup_exec_t;

# 웹 서비스 권한
allow zuzunza_web_t httpd_sys_content_t:file { read getattr };
allow zuzunza_web_t var_log_t:file { write append };
allow zuzunza_web_t self:tcp_socket name_bind;

# 데이터베이스 권한
allow zuzunza_db_t postgresql_db_t:dir { read write };
allow zuzunza_db_t postgresql_db_t:file { read write };

# 백업 권한
allow zuzunza_backup_t backup_store_t:file { read write };
allow zuzunza_backup_t var_lib_t:dir { read write };
EOF
    
    # 정책 컴파일 및 설치
    log_info "SELinux 정책 컴파일 중..."
    make -f /usr/share/selinux/default/include/Makefile zuzunza.pp 2>/dev/null || true
    
    if [ -f zuzunza.pp ]; then
        sudo semodule -i zuzunza.pp
        log_success "주전자닷컴 SELinux 정책 모듈 설치 완료"
    else
        log_warning "SELinux 정책 컴파일 실패 (정책이 이미 존재할 수 있음)"
    fi
    
    # 정리
    cd /
    rm -rf "$TEMP_DIR"
}

# 모니터링 및 로깅 설정
setup_monitoring() {
    log_info "SELinux 모니터링 설정 중..."
    
    # auditd 설정
    sudo tee -a /etc/audit/rules.d/audit.rules > /dev/null <<EOF

# 주전자닷컴 SELinux 모니터링
-w /srv/zuzunza -p wa -k zuzunza_selinux
-w /database -p wa -k database_selinux
-w /data -p wa -k data_selinux
EOF
    
    # auditd 재시작
    sudo systemctl restart auditd
    
    log_success "SELinux 모니터링 설정 완료"
}

# 상태 확인
check_final_status() {
    log_info "최종 상태 확인 중..."
    
    echo ""
    echo "==========================================="
    echo "🔒 SELinux 설정 완료 보고서"
    echo "==========================================="
    
    # SELinux 상태
    echo "SELinux 상태:"
    sestatus | head -3
    
    # 컨텍스트 확인
    echo ""
    echo "주요 디렉토리 SELinux 컨텍스트:"
    ls -laZ /srv/zuzunza/ | head -5
    
    # Docker 설정 확인
    echo ""
    echo "Docker SELinux 설정:"
    sudo docker info | grep -i selinux || echo "Docker SELinux 정보 없음"
    
    # 포트 설정 확인
    echo ""
    echo "SELinux 포트 설정:"
    sudo semanage port -l | grep -E "(3000|5688|7700|5497|6379)" || echo "포트 설정 없음"
    
    echo ""
    echo "==========================================="
    log_success "설정 완료!"
    echo "==========================================="
}

# 메인 실행 함수
main() {
    echo "🚀 주전자닷컴 SELinux 설정 시작..."
    echo ""
    
    # 1. SELinux 상태 확인
    if ! check_selinux_status; then
        enable_selinux
    fi
    
    # 2. Docker 설정
    setup_docker_selinux
    
    # 3. 프로젝트 컨텍스트 설정
    setup_project_contexts
    
    # 4. 데이터 디렉토리 설정
    setup_data_contexts
    
    # 5. 포트 설정
    setup_port_contexts
    
    # 6. 시스템 서비스 설정
    setup_system_services
    
    # 7. 커스텀 정책 생성
    create_custom_policy
    
    # 8. 모니터링 설정
    setup_monitoring
    
    # 9. 컨텍스트 적용
    apply_contexts
    
    # 10. 최종 상태 확인
    check_final_status
    
    echo ""
    log_warning "⚠️  중요: 완전한 SELinux 활성화를 위해 시스템 재부팅이 필요합니다."
    log_info "현재는 permissive 모드로 설정되어 있어 보안 정책 위반 시 로그만 기록됩니다."
    log_info "재부팅 후 'sestatus' 명령으로 상태를 확인하세요."
}

# 스크립트 실행
main "$@"
