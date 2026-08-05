INSTALL_DISPLAY="Paymenter"
INSTALL_CREDENTIALS="Create the admin user: docker exec -it paymenter php artisan app:user:create"
INSTALL_NOTES="No admin account is created automatically — run the artisan command above, then log in at /admin."

# Composer-free but still a Laravel boot: migrations + seeders run on first start.
INSTALL_READY_RETRIES=36

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS paymenter CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
}

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  app:
    image: ghcr.io/paymenter/paymenter:v1.5.7
    restart: unless-stopped
    environment:
      APP_ENV: production
      APP_DEBUG: "false"
      APP_URL: http://paymenter
      APP_TIMEZONE: UTC
      DB_CONNECTION: mariadb
      DB_HOST: podium-mariadb
      DB_PORT: "3306"
      DB_DATABASE: paymenter
      DB_USERNAME: root
      DB_PASSWORD: ""
      CACHE_STORE: redis
      QUEUE_CONNECTION: redis
      SESSION_DRIVER: file
      REDIS_CLIENT: phpredis
      REDIS_HOST: podium-redis
      REDIS_PORT: "6379"
      MAIL_MAILER: smtp
      MAIL_HOST: podium-mailhog
      MAIL_PORT: "1025"
      MAIL_FROM_ADDRESS: paymenter@localhost
      MAIL_FROM_NAME: Paymenter
      PAYMENTER_SKIP_DEFAULT: "false"
    volumes:
      - paymenter-var:/app/var
      - paymenter-storage:/app/storage
      - paymenter-themes:/app/themes
      - paymenter-extensions:/app/extensions

volumes:
  paymenter-var:
  paymenter-storage:
  paymenter-themes:
  paymenter-extensions:
EOF
}
