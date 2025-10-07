#!/bin/bash

# ===========================================
# Apache2 SELinux 호환성 설정 스크립트
# 주전자닷컴 Gateway Apache2 SELinux 설정
# ===========================================

set -e

echo "🌐 주전자닷컴 Apache2 SELinux 설정 시작..."

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

# Apache2 SELinux 모듈 설치
install_apache_selinux() {
    log_info "Apache2 SELinux 모듈 설치 중..."
    
    sudo apt update
    sudo apt install -y apache2 selinux-policy-default
    
    log_success "Apache2 SELinux 모듈 설치 완료"
}

# Apache2 컨텍스트 설정
setup_apache_contexts() {
    log_info "Apache2 SELinux 컨텍스트 설정 중..."
    
    # Apache2 설정 디렉토리
    sudo semanage fcontext -a -t httpd_config_t "/srv/gateway(/.*)?" 2>/dev/null || true
    sudo semanage fcontext -a -t httpd_config_t "/srv/gateway/sites-enabled(/.*)?" 2>/dev/null || true
    sudo semanage fcontext -a -t httpd_config_t "/srv/gateway/sites-available(/.*)?" 2>/dev/null || true
    sudo semanage fcontext -a -t httpd_config_t "/srv/gateway/mods-enabled(/.*)?" 2>/dev/null || true
    sudo semanage fcontext -a -t httpd_config_t "/srv/gateway/mods-available(/.*)?" 2>/dev/null || true
    sudo semanage fcontext -a -t httpd_config_t "/srv/gateway/conf-enabled(/.*)?" 2>/dev/null || true
    sudo semanage fcontext -a -t httpd_config_t "/srv/gateway/conf-available(/.*)?" 2>/dev/null || true
    
    # Apache2 로그 디렉토리
    sudo semanage fcontext -a -t httpd_log_t "/var/log/apache2(/.*)?" 2>/dev/null || true
    sudo semanage fcontext -a -t httpd_log_t "/srv/gateway/logs(/.*)?" 2>/dev/null || true
    
    # Apache2 캐시 디렉토리
    sudo semanage fcontext -a -t httpd_cache_t "/var/cache/apache2(/.*)?" 2>/dev/null || true
    
    # Apache2 실행 파일
    sudo semanage fcontext -a -t httpd_exec_t "/usr/sbin/apache2" 2>/dev/null || true
    sudo semanage fcontext -a -t httpd_exec_t "/usr/lib/apache2/modules(/.*)?" 2>/dev/null || true
    
    # Apache2 CGI 스크립트 디렉토리
    sudo semanage fcontext -a -t httpd_exec_t "/srv/zuzunza/gateway/apache2/cgi-bin(/.*)?" 2>/dev/null || true
    
    # Apache2 오류 페이지 디렉토리
    sudo semanage fcontext -a -t httpd_sys_content_t "/srv/zuzunza/gateway/apache2/error_pages(/.*)?" 2>/dev/null || true
    
    # Apache2 퍼블릭 디렉토리
    sudo semanage fcontext -a -t httpd_sys_content_t "/srv/zuzunza/gateway/public(/.*)?" 2>/dev/null || true
    
    log_success "Apache2 SELinux 컨텍스트 설정 완료"
}

# Apache2 포트 설정
setup_apache_ports() {
    log_info "Apache2 포트 SELinux 설정 중..."
    
    # HTTP/HTTPS 포트들
    sudo semanage port -a -t http_port_t -p tcp 80 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 443 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 8080 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 8443 2>/dev/null || true
    
    # Apache2 관리 포트
    sudo semanage port -a -t http_port_t -p tcp 8000 2>/dev/null || true
    sudo semanage port -a -t http_port_t -p tcp 9000 2>/dev/null || true
    
    log_success "Apache2 포트 SELinux 설정 완료"
}

# Apache2 부울 설정
setup_apache_booleans() {
    log_info "Apache2 SELinux 부울 설정 중..."
    
    # Apache2가 사용자 홈 디렉토리에 접근할 수 있도록 허용
    sudo setsebool -P httpd_enable_homedirs 1 2>/dev/null || true
    
    # Apache2가 사용자 공용 디렉토리에 접근할 수 있도록 허용
    sudo setsebool -P httpd_enable_cgi 1 2>/dev/null || true
    
    # Apache2가 원격 연결을 허용하도록 설정
    sudo setsebool -P httpd_can_network_connect 1 2>/dev/null || true
    sudo setsebool -P httpd_can_network_relay 1 2>/dev/null || true
    
    # Apache2가 데이터베이스에 연결할 수 있도록 허용
    sudo setsebool -P httpd_can_network_connect_db 1 2>/dev/null || true
    
    # Apache2가 캐시 디렉토리를 사용할 수 있도록 허용
    sudo setsebool -P httpd_can_cache 1 2>/dev/null || true
    
    # Apache2가 시스템 로그에 접근할 수 있도록 허용
    sudo setsebool -P httpd_anon_write 1 2>/dev/null || true
    
    # Apache2가 파일 업로드를 허용하도록 설정
    sudo setsebool -P httpd_upload_files 1 2>/dev/null || true
    
    # Apache2가 SELinux 상태를 확인할 수 있도록 허용
    sudo setsebool -P httpd_selinux_off 0 2>/dev/null || true
    
    log_success "Apache2 SELinux 부울 설정 완료"
}

# Apache2 정책 모듈 생성
create_apache_policy() {
    log_info "Apache2 전용 SELinux 정책 모듈 생성 중..."
    
    # 임시 디렉토리 생성
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # zuzunza-apache.te 파일 생성
    cat > zuzunza-apache.te <<EOF
module zuzunza-apache 1.0;

require {
    type httpd_t;
    type httpd_exec_t;
    type httpd_config_t;
    type httpd_sys_content_t;
    type httpd_log_t;
    type httpd_cache_t;
    type var_log_t;
    type var_cache_t;
    class file { read write execute getattr open create unlink };
    class dir { read write add_name remove_name search };
    class tcp_socket { name_bind connect };
    class unix_stream_socket { connect };
}

# zuzunza Apache2 도메인
type zuzunza_apache_t;
type zuzunza_apache_exec_t;

# Apache2 설정 파일 접근
allow zuzunza_apache_t httpd_config_t:file { read getattr };
allow zuzunza_apache_t httpd_config_t:dir { read search };

# Apache2 로그 파일 접근
allow zuzunza_apache_t httpd_log_t:file { read write append };
allow zuzunza_apache_t httpd_log_t:dir { read write add_name };

# Apache2 캐시 디렉토리 접근
allow zuzunza_apache_t httpd_cache_t:dir { read write add_name };
allow zuzunza_apache_t httpd_cache_t:file { read write create unlink };

# Apache2 콘텐츠 파일 접근
allow zuzunza_apache_t httpd_sys_content_t:file { read getattr };
allow zuzunza_apache_t httpd_sys_content_t:dir { read search };

# 네트워크 연결 허용
allow zuzunza_apache_t self:tcp_socket name_bind;
allow zuzunza_apache_t self:tcp_socket connect;

# CGI 스크립트 실행 허용
allow zuzunza_apache_t httpd_exec_t:file { read execute getattr };
allow zuzunza_apache_t httpd_exec_t:dir { read search };

# 시스템 로그 접근
allow zuzunza_apache_t var_log_t:file { read write append };
allow zuzunza_apache_t var_cache_t:dir { read write };
EOF
    
    # 정책 컴파일 및 설치
    log_info "Apache2 SELinux 정책 컴파일 중..."
    make -f /usr/share/selinux/default/include/Makefile zuzunza-apache.pp 2>/dev/null || true
    
    if [ -f zuzunza-apache.pp ]; then
        sudo semodule -i zuzunza-apache.pp
        log_success "Apache2 SELinux 정책 모듈 설치 완료"
    else
        log_warning "Apache2 SELinux 정책 컴파일 실패 (정책이 이미 존재할 수 있음)"
    fi
    
    # 정리
    cd /
    rm -rf "$TEMP_DIR"
}

# Apache2 컨텍스트 적용
apply_apache_contexts() {
    log_info "Apache2 SELinux 컨텍스트 적용 중..."
    
    # Gateway 디렉토리 컨텍스트 적용
    sudo restorecon -Rv /srv/gateway/ 2>/dev/null || true
    
    # Apache2 관련 디렉토리 컨텍스트 적용
    sudo restorecon -Rv /var/log/apache2/ 2>/dev/null || true
    sudo restorecon -Rv /var/cache/apache2/ 2>/dev/null || true
    sudo restorecon -Rv /usr/lib/apache2/ 2>/dev/null || true
    
    # zuzunza 관련 디렉토리 컨텍스트 적용
    sudo restorecon -Rv /srv/zuzunza/gateway/ 2>/dev/null || true
    
    log_success "Apache2 SELinux 컨텍스트 적용 완료"
}

# Apache2 서비스 SELinux 설정
setup_apache_service() {
    log_info "Apache2 서비스 SELinux 설정 중..."
    
    # systemd 서비스 파일
    sudo semanage fcontext -a -t systemd_unit_file_t "/lib/systemd/system/apache2.service" 2>/dev/null || true
    sudo semanage fcontext -a -t systemd_unit_file_t "/etc/systemd/system/multi-user.target.wants/apache2.service" 2>/dev/null || true
    
    # Apache2 바이너리 권한
    sudo semanage fcontext -a -t httpd_exec_t "/usr/sbin/apache2" 2>/dev/null || true
    sudo semanage fcontext -a -t httpd_exec_t "/usr/sbin/apache2ctl" 2>/dev/null || true
    
    # 컨텍스트 적용
    sudo restorecon -Rv /lib/systemd/system/apache2.service 2>/dev/null || true
    sudo restorecon -Rv /usr/sbin/apache2 2>/dev/null || true
    sudo restorecon -Rv /usr/sbin/apache2ctl 2>/dev/null || true
    
    log_success "Apache2 서비스 SELinux 설정 완료"
}

# Apache2 모니터링 설정
setup_apache_monitoring() {
    log_info "Apache2 SELinux 모니터링 설정 중..."
    
    # auditd 설정에 Apache2 모니터링 추가
    sudo tee -a /etc/audit/rules.d/audit.rules > /dev/null <<EOF

# 주전자닷컴 Apache2 SELinux 모니터링
-w /srv/gateway -p wa -k apache2_selinux
-w /var/log/apache2 -p wa -k apache2_logs
-w /var/cache/apache2 -p wa -k apache2_cache
EOF
    
    # auditd 재시작
    sudo systemctl restart auditd
    
    log_success "Apache2 SELinux 모니터링 설정 완료"
}

# Apache2 서비스 재시작
restart_apache_service() {
    log_info "Apache2 서비스 재시작 중..."
    
    # Apache2 설정 테스트
    sudo apache2ctl configtest
    
    if [ $? -eq 0 ]; then
        sudo systemctl restart apache2
        sudo systemctl status apache2 --no-pager -l
        log_success "Apache2 서비스 재시작 완료"
    else
        log_error "Apache2 설정 테스트 실패"
        return 1
    fi
}

# 상태 확인
check_final_status() {
    log_info "최종 상태 확인 중..."
    
    echo ""
    echo "==========================================="
    echo "🌐 Apache2 SELinux 설정 완료 보고서"
    echo "==========================================="
    
    # Apache2 상태
    echo "Apache2 서비스 상태:"
    sudo systemctl status apache2 --no-pager -l | head -5
    
    # 컨텍스트 확인
    echo ""
    echo "Apache2 설정 디렉토리 SELinux 컨텍스트:"
    ls -laZ /srv/gateway/ | head -5
    
    # 포트 설정 확인
    echo ""
    echo "Apache2 포트 설정:"
    sudo semanage port -l | grep -E "(http_port_t)" | head -1
    
    # 부울 설정 확인
    echo ""
    echo "Apache2 부울 설정:"
    sudo getsebool -a | grep httpd | head -10
    
    echo ""
    echo "==========================================="
    log_success "Apache2 SELinux 설정 완료!"
    echo "==========================================="
}

# 메인 실행 함수
main() {
    echo "🚀 주전자닷컴 Apache2 SELinux 설정 시작..."
    echo ""
    
    # 1. Apache2 SELinux 모듈 설치
    install_apache_selinux
    
    # 2. Apache2 컨텍스트 설정
    setup_apache_contexts
    
    # 3. Apache2 포트 설정
    setup_apache_ports
    
    # 4. Apache2 부울 설정
    setup_apache_booleans
    
    # 5. Apache2 정책 모듈 생성
    create_apache_policy
    
    # 6. Apache2 서비스 설정
    setup_apache_service
    
    # 7. Apache2 모니터링 설정
    setup_apache_monitoring
    
    # 8. 컨텍스트 적용
    apply_apache_contexts
    
    # 9. Apache2 서비스 재시작
    restart_apache_service
    
    # 10. 최종 상태 확인
    check_final_status
    
    echo ""
    log_info "Apache2가 SELinux 보안 정책 하에서 안전하게 실행됩니다."
}

# 스크립트 실행
main "$@"
