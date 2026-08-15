INSTALL_DISPLAY="Pterodactyl Panel"
INSTALL_CREDENTIALS="Create the admin user: docker exec -it pterodactyl php artisan p:user:make"
INSTALL_NOTES="Panel only — game servers additionally need a Wings daemon, which requires host Docker access and is not part of this install."

# Laravel migrations + seeders run on first boot.
INSTALL_READY_RETRIES=36

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS pterodactyl CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
}

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  app:
    image: ghcr.io/pterodactyl/panel:v1.15.0
    restart: unless-stopped
    environment:
      APP_ENV: production
      APP_ENVIRONMENT_ONLY: "false"
      APP_DEBUG: "false"
      APP_URL: http://pterodactyl
      APP_TIMEZONE: UTC
      APP_SERVICE_AUTHOR: noreply@example.com
      TRUSTED_PROXIES: "*"
      DB_HOST: podium-mariadb
      DB_PORT: "3306"
      DB_DATABASE: pterodactyl
      DB_USERNAME: root
      DB_PASSWORD: ""
      CACHE_DRIVER: redis
      SESSION_DRIVER: redis
      QUEUE_DRIVER: redis
      REDIS_HOST: podium-redis
      REDIS_PORT: "6379"
      MAIL_DRIVER: smtp
      MAIL_HOST: podium-mailhog
      MAIL_PORT: "1025"
      MAIL_ENCRYPTION: "false"
      MAIL_FROM: noreply@example.com
    volumes:
      - pterodactyl-var:/app/var
      - pterodactyl-logs:/app/storage/logs

volumes:
  pterodactyl-var:
  pterodactyl-logs:
EOF
}
