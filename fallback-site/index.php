<?php
/**
 * Zuzunza Fallback Site - Modern Dynamic Design
 * PHP-based dynamic fallback page with server health monitoring
 */

// 설정
define('MAIN_SERVER_HOST', '127.0.0.1');
define('MAIN_SERVER_PORT', 5688);
define('HEALTH_CHECK_TIMEOUT', 2);
define('LOG_FILE', __DIR__ . '/logs/fallback.log');
define('DB_HOST', '127.0.0.1');
define('DB_PORT', 5497);
define('DB_NAME', 'postgres');
define('DB_USER', 'postgres');
define('DB_PASS', 'sbvotmdnjem');

// 로그 디렉토리 생성
if (!is_dir(__DIR__ . '/logs')) {
    @mkdir(__DIR__ . '/logs', 0755, true);
}

/**
 * 로그 기록
 */
function logMessage($message, $level = 'INFO') {
    $timestamp = date('Y-m-d H:i:s');
    $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    $logEntry = "[$timestamp] [$level] [IP: $ip] $message" . PHP_EOL;
    @file_put_contents(LOG_FILE, $logEntry, FILE_APPEND | LOCK_EX);
}

/**
 * 메인 서버 상태 체크 (Socket)
 */
function checkMainServerSocket() {
    $fp = @fsockopen(MAIN_SERVER_HOST, MAIN_SERVER_PORT, $errno, $errstr, HEALTH_CHECK_TIMEOUT);
    if ($fp) {
        fclose($fp);
        return true;
    }
    return false;
}

/**
 * 메인 서버 HTTP 헬스체크
 */
function checkMainServerHTTP() {
    $ch = curl_init('http://' . MAIN_SERVER_HOST . ':' . MAIN_SERVER_PORT . '/');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => HEALTH_CHECK_TIMEOUT,
        CURLOPT_CONNECTTIMEOUT => HEALTH_CHECK_TIMEOUT,
        CURLOPT_NOBODY => true,
        CURLOPT_FOLLOWLOCATION => false,
    ]);
    
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return $httpCode >= 200 && $httpCode < 500;
}

/**
 * 데이터베이스 연결 체크
 */
function checkDatabaseConnection() {
    try {
        $dsn = "pgsql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME;
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_TIMEOUT => 2,
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        ]);
        $pdo->query('SELECT 1');
        return true;
    } catch (PDOException $e) {
        return false;
    }
}

/**
 * Redis 연결 체크
 */
function checkRedisConnection() {
    try {
        if (class_exists('Redis')) {
            $redis = new Redis();
            $redis->connect('127.0.0.1', 6379, 2);
            $redis->ping();
            $redis->close();
            return true;
        }
    } catch (Exception $e) {
        return false;
    }
    return false;
}

/**
 * 시스템 상태 정보 수집
 */
function getSystemStatus() {
    $status = [
        'main_server' => [
            'socket' => checkMainServerSocket(),
            'http' => checkMainServerHTTP(),
        ],
        'database' => checkDatabaseConnection(),
        'redis' => checkRedisConnection(),
        'timestamp' => time(),
        'server_load' => sys_getloadavg(),
        'memory_usage' => [
            'used' => memory_get_usage(true),
            'peak' => memory_get_peak_usage(true),
        ],
    ];
    
    return $status;
}

// API 요청 처리
if (isset($_GET['api']) && $_GET['api'] === 'status') {
    header('Content-Type: application/json');
    $status = getSystemStatus();
    
    // 메인 서버가 살아있으면 리다이렉트 필요
    if ($status['main_server']['socket'] || $status['main_server']['http']) {
        $status['action'] = 'redirect';
        $status['redirect_url'] = 'https://www.zuzunza.com';
    } else {
        $status['action'] = 'stay';
        logMessage('Main server is down - serving fallback page', 'WARNING');
    }
    
    echo json_encode($status);
    exit;
}

// 페이지 로드 로그
logMessage('Fallback page served - Main server is down', 'WARNING');

// 시스템 상태 수집
$systemStatus = getSystemStatus();
$isMainServerUp = $systemStatus['main_server']['socket'] || $systemStatus['main_server']['http'];
$isDatabaseUp = $systemStatus['database'];
$isRedisUp = $systemStatus['redis'];

// 예상 복구 시간 계산 (단순화)
$estimatedTime = '5-10분';
$serverLoadStatus = $systemStatus['server_load'][0] < 2 ? '낮음' : ($systemStatus['server_load'][0] < 5 ? '보통' : '높음');
?>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zuzunza - 곧 돌아올게요! 🎨</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Black+Han+Sans&family=Noto+Sans+KR:wght@400;500;700;900&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Noto Sans KR', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #ff6b9d 0%, #c44569 50%, #8e44ad 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #fff;
            overflow: hidden;
            position: relative;
        }

        /* 배경 애니메이션 도형들 */
        .bg-shapes {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            overflow: hidden;
            z-index: 1;
        }

        .shape {
            position: absolute;
            opacity: 0.6;
            animation: float 6s ease-in-out infinite;
        }

        .shape:nth-child(1) {
            top: 10%;
            left: 10%;
            width: 60px;
            height: 60px;
            background: #ffeb3b;
            border-radius: 50%;
            animation-delay: 0s;
        }

        .shape:nth-child(2) {
            top: 60%;
            left: 80%;
            width: 0;
            height: 0;
            border-left: 40px solid transparent;
            border-right: 40px solid transparent;
            border-bottom: 70px solid #00bcd4;
            animation-delay: 1s;
        }

        .shape:nth-child(3) {
            top: 80%;
            left: 15%;
            width: 50px;
            height: 50px;
            background: #4caf50;
            transform: rotate(45deg);
            animation-delay: 2s;
        }

        .shape:nth-child(4) {
            top: 20%;
            left: 75%;
            width: 0;
            height: 0;
            border-left: 30px solid transparent;
            border-right: 30px solid transparent;
            border-bottom: 50px solid #ff9800;
            animation-delay: 1.5s;
        }

        .shape:nth-child(5) {
            top: 40%;
            left: 5%;
            width: 70px;
            height: 70px;
            background: transparent;
            border: 5px solid #e91e63;
            border-radius: 50%;
            animation-delay: 3s;
        }

        .shape:nth-child(6) {
            top: 15%;
            left: 45%;
            width: 40px;
            height: 40px;
            background: #03a9f4;
            clip-path: polygon(50% 0%, 0% 100%, 100% 100%);
            animation-delay: 2.5s;
        }

        .shape:nth-child(7) {
            top: 70%;
            left: 60%;
            width: 55px;
            height: 55px;
            background: #cddc39;
            border-radius: 10px;
            animation-delay: 1.8s;
        }

        .shape:nth-child(8) {
            top: 30%;
            left: 88%;
            font-size: 50px;
            animation-delay: 0.5s;
        }

        .shape:nth-child(9) {
            top: 85%;
            left: 85%;
            font-size: 40px;
            animation-delay: 2.2s;
        }

        @keyframes float {
            0%, 100% {
                transform: translateY(0) rotate(0deg);
            }
            50% {
                transform: translateY(-30px) rotate(180deg);
            }
        }

        /* 메인 컨테이너 */
        .container {
            position: relative;
            z-index: 10;
            text-align: center;
            max-width: 1200px;
            padding: 40px 20px;
        }

        /* 로고 */
        .logo {
            display: inline-flex;
            align-items: center;
            gap: 15px;
            background: rgba(255, 255, 255, 0.95);
            padding: 20px 35px;
            border-radius: 60px;
            margin-bottom: 50px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
            animation: slideDown 0.8s ease-out;
        }

        .logo-icon {
            font-size: 36px;
        }

        .logo-text {
            font-family: 'Black Han Sans', sans-serif;
            font-size: 32px;
            background: linear-gradient(135deg, #ff6b9d, #c44569);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateY(-50px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        /* 메인 타이틀 */
        .main-title {
            font-family: 'Black Han Sans', sans-serif;
            font-size: 120px;
            line-height: 1;
            margin-bottom: 30px;
            text-shadow: 
                5px 5px 0px rgba(0, 0, 0, 0.1),
                10px 10px 20px rgba(0, 0, 0, 0.2);
            animation: scaleUp 0.8s ease-out 0.2s both;
        }

        .title-line {
            display: block;
        }

        @keyframes scaleUp {
            from {
                opacity: 0;
                transform: scale(0.8);
            }
            to {
                opacity: 1;
                transform: scale(1);
            }
        }

        /* 가격 표시 */
        .price-tag {
            display: inline-block;
            background: #fff;
            color: #ff6b9d;
            padding: 15px 40px;
            border-radius: 50px;
            font-size: 36px;
            font-weight: 900;
            margin-bottom: 30px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            animation: bounce 1s ease-in-out 0.4s both;
        }

        @keyframes bounce {
            0%, 100% {
                transform: translateY(0);
            }
            50% {
                transform: translateY(-20px);
            }
        }

        /* 설명 텍스트 */
        .description {
            font-size: 18px;
            line-height: 1.8;
            margin-bottom: 40px;
            max-width: 600px;
            margin-left: auto;
            margin-right: auto;
            opacity: 0.95;
            animation: fadeIn 0.8s ease-out 0.6s both;
        }

        @keyframes fadeIn {
            from {
                opacity: 0;
            }
            to {
                opacity: 0.95;
            }
        }

        /* 시스템 상태 카드 */
        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 20px;
            max-width: 700px;
            margin: 40px auto;
            animation: fadeIn 0.8s ease-out 0.8s both;
        }

        .status-card {
            background: rgba(255, 255, 255, 0.15);
            backdrop-filter: blur(10px);
            border: 2px solid rgba(255, 255, 255, 0.3);
            border-radius: 20px;
            padding: 25px 20px;
            transition: all 0.3s ease;
        }

        .status-card:hover {
            transform: translateY(-5px);
            background: rgba(255, 255, 255, 0.25);
            box-shadow: 0 15px 40px rgba(0, 0, 0, 0.3);
        }

        .status-icon {
            font-size: 36px;
            margin-bottom: 10px;
        }

        .status-label {
            font-size: 14px;
            opacity: 0.9;
            margin-bottom: 8px;
        }

        .status-value {
            font-size: 16px;
            font-weight: 700;
        }

        .status-indicator {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            margin-left: 8px;
            animation: pulse 2s infinite;
        }

        .status-indicator.up {
            background: #4ade80;
            box-shadow: 0 0 10px #4ade80;
        }

        .status-indicator.down {
            background: #f87171;
            box-shadow: 0 0 10px #f87171;
        }

        @keyframes pulse {
            0%, 100% {
                opacity: 1;
            }
            50% {
                opacity: 0.5;
            }
        }

        /* 버튼 */
        .cta-button {
            display: inline-block;
            background: #fff;
            color: #ff6b9d;
            padding: 18px 50px;
            border-radius: 50px;
            font-size: 20px;
            font-weight: 900;
            text-decoration: none;
            text-transform: uppercase;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            transition: all 0.3s ease;
            cursor: pointer;
            border: none;
            animation: fadeIn 0.8s ease-out 1s both;
        }

        .cta-button:hover {
            transform: translateY(-3px);
            box-shadow: 0 15px 40px rgba(0, 0, 0, 0.3);
            background: #ffeb3b;
        }

        /* 푸터 정보 */
        .footer-info {
            margin-top: 50px;
            padding-top: 30px;
            border-top: 2px solid rgba(255, 255, 255, 0.3);
            font-size: 14px;
            opacity: 0.8;
            animation: fadeIn 0.8s ease-out 1.2s both;
        }

        .footer-info a {
            color: #ffeb3b;
            text-decoration: none;
            font-weight: 700;
            transition: all 0.3s ease;
        }

        .footer-info a:hover {
            text-decoration: underline;
        }

        .last-check {
            margin-top: 15px;
            font-size: 12px;
            opacity: 0.7;
        }

        /* 반응형 */
        @media (max-width: 768px) {
            .main-title {
                font-size: 60px;
            }

            .logo-text {
                font-size: 24px;
            }

            .logo-icon {
                font-size: 28px;
            }

            .price-tag {
                font-size: 24px;
                padding: 12px 30px;
            }

            .description {
                font-size: 16px;
            }

            .status-grid {
                grid-template-columns: 1fr 1fr;
            }

            .cta-button {
                font-size: 16px;
                padding: 15px 40px;
            }
        }
    </style>
</head>
<body>
    <!-- 배경 애니메이션 도형들 -->
    <div class="bg-shapes">
        <div class="shape"></div>
        <div class="shape"></div>
        <div class="shape"></div>
        <div class="shape"></div>
        <div class="shape"></div>
        <div class="shape"></div>
        <div class="shape"></div>
        <div class="shape">⭐</div>
        <div class="shape">✨</div>
    </div>

    <!-- 메인 컨테이너 -->
    <div class="container">
        <!-- 로고 -->
        <div class="logo">
            <span class="logo-icon">🎨</span>
            <span class="logo-text">ZUZUNZA</span>
        </div>

        <!-- 메인 타이틀 -->
        <h1 class="main-title">
            <span class="title-line">잠시만</span>
            <span class="title-line">기다려</span>
            <span class="title-line">주세요</span>
        </h1>

        <!-- 가격 태그 (예상 시간으로 변경) -->
        <div class="price-tag">⏱️ <?= $estimatedTime ?></div>

        <!-- 설명 -->
        <p class="description">
            더 멋진 서비스를 준비하고 있어요!<br>
            잠시 후 돌아올 테니 조금만 기다려주세요 🚀<br>
            곧 만나요! ✨
        </p>

        <!-- 시스템 상태 그리드 -->
        <div class="status-grid">
            <div class="status-card">
                <div class="status-icon">🌐</div>
                <div class="status-label">웹 서버</div>
                <div class="status-value">
                    <?= $isMainServerUp ? '정상' : '점검중' ?>
                    <span class="status-indicator <?= $isMainServerUp ? 'up' : 'down' ?>"></span>
                </div>
            </div>

            <div class="status-card">
                <div class="status-icon">💾</div>
                <div class="status-label">데이터베이스</div>
                <div class="status-value">
                    <?= $isDatabaseUp ? '정상' : '점검중' ?>
                    <span class="status-indicator <?= $isDatabaseUp ? 'up' : 'down' ?>"></span>
                </div>
            </div>

            <div class="status-card">
                <div class="status-icon">⚡</div>
                <div class="status-label">캐시 서버</div>
                <div class="status-value">
                    <?= $isRedisUp ? '정상' : '점검중' ?>
                    <span class="status-indicator <?= $isRedisUp ? 'up' : 'down' ?>"></span>
                </div>
            </div>

            <div class="status-card">
                <div class="status-icon">📊</div>
                <div class="status-label">서버 부하</div>
                <div class="status-value">
                    <?= $serverLoadStatus ?>
                    <span class="status-indicator up"></span>
                </div>
            </div>
        </div>

        <!-- CTA 버튼 -->
        <button class="cta-button" onclick="checkServerStatus()">
            🔄 새로고침
        </button>

        <!-- 푸터 정보 -->
        <div class="footer-info">
            <p id="status-message">
                자동으로 복구를 확인하고 있어요 ⏳
            </p>
            <p class="last-check" id="last-check">
                마지막 확인: 방금 전
            </p>
            <p style="margin-top: 20px;">
                긴급 문의: <a href="mailto:admin@zuzunza.com">admin@zuzunza.com</a>
            </p>
            <p style="margin-top: 10px; font-size: 11px; opacity: 0.5;">
                Server: <?= gethostname() ?> | PHP <?= PHP_VERSION ?> | <?= date('Y-m-d H:i:s') ?>
            </p>
        </div>
    </div>

    <script>
        let checkInterval = null;
        let lastCheckTime = Date.now();

        // 서버 상태 확인
        function checkServerStatus() {
            fetch('/?api=status&t=' + Date.now())
                .then(response => response.json())
                .then(data => {
                    lastCheckTime = Date.now();
                    updateLastCheckTime();
                    
                    console.log('🔍 Server status:', data);
                    
                    // 메인 서버가 복구되면 리다이렉트
                    if (data.action === 'redirect') {
                        document.getElementById('status-message').innerHTML = 
                            '✅ <strong>서버 복구 완료!</strong> 곧 이동합니다... 🎉';
                        
                        // 축하 효과
                        document.body.style.animation = 'fadeOut 1s ease-in-out';
                        
                        setTimeout(() => {
                            window.location.href = data.redirect_url;
                        }, 1500);
                    }
                })
                .catch(error => {
                    console.error('❌ Status check failed:', error);
                    lastCheckTime = Date.now();
                    updateLastCheckTime();
                });
        }

        // 마지막 확인 시간 업데이트
        function updateLastCheckTime() {
            const elapsed = Math.floor((Date.now() - lastCheckTime) / 1000);
            const lastCheckEl = document.getElementById('last-check');
            
            if (elapsed < 10) {
                lastCheckEl.textContent = '마지막 확인: 방금 전 ✨';
            } else if (elapsed < 60) {
                lastCheckEl.textContent = `마지막 확인: ${elapsed}초 전 ⏱️`;
            } else {
                const minutes = Math.floor(elapsed / 60);
                lastCheckEl.textContent = `마지막 확인: ${minutes}분 전 ⏰`;
            }
        }

        // 5초마다 서버 상태 확인
        checkInterval = setInterval(checkServerStatus, 5000);

        // 1초마다 마지막 확인 시간 업데이트
        setInterval(updateLastCheckTime, 1000);

        // 페이지 로드 시 즉시 체크
        setTimeout(checkServerStatus, 500);

        // 페이드아웃 애니메이션
        const style = document.createElement('style');
        style.textContent = `
            @keyframes fadeOut {
                to {
                    opacity: 0;
                    transform: scale(0.95);
                }
            }
        `;
        document.head.appendChild(style);
    </script>
</body>
</html>
