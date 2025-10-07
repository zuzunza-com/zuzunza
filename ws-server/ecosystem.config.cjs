module.exports = {
  apps: [
    {
      name: 'ws-server',
      script: 'dist/server.js',
      instances: 1,
      exec_mode: 'fork',
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        SOCKET_PORT: 5689
      },
      env_development: {
        NODE_ENV: 'development',
        SOCKET_PORT: 5689
      },
      env_production: {
        NODE_ENV: 'production',
        SOCKET_PORT: 5689
      },
      error_file: './logs/err.log',
      out_file: './logs/out.log',
      log_file: './logs/combined.log',
      time: true,
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 4000
    }
  ]
}
