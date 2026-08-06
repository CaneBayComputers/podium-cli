INSTALL_DISPLAY="Mixpost Lite"
INSTALL_CREDENTIALS="admin@example.com / changeme"
INSTALL_NOTES="Runs its queue workers and scheduler internally via supervisor — no extra worker container is needed."

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "
        CREATE DATABASE IF NOT EXISTS mixpost CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        CREATE USER IF NOT EXISTS 'mixpost'@'%' IDENTIFIED BY 'mixpost';
        ALTER USER 'mixpost'@'%' IDENTIFIED BY 'mixpost';
        GRANT ALL PRIVILEGES ON mixpost.* TO 'mixpost'@'%';
        FLUSH PRIVILEGES;
    "
}

write_files() {
    local app_key
    app_key="base64:$(openssl rand -base64 32)"

    cat > docker-compose.yaml << EOF
services:
  app:
    image: inovector/mixpost:v2.6.0
    restart: unless-stopped
    environment:
      APP_NAME: Mixpost
      APP_KEY: "$app_key"
      APP_DEBUG: "false"
      APP_URL: http://mixpost
      DB_HOST: podium-mariadb
      DB_PORT: 3306
      DB_DATABASE: mixpost
      DB_USERNAME: mixpost
      DB_PASSWORD: mixpost
      REDIS_HOST: podium-redis
      REDIS_PORT: 6379
      MAIL_MAILER: smtp
      MAIL_HOST: podium-mailhog
      MAIL_PORT: 1025
      MAIL_FROM_ADDRESS: mixpost@example.com
      MAIL_FROM_NAME: Mixpost
    volumes:
      - mixpost-storage:/var/www/html/storage/app
      - mixpost-logs:/var/www/html/storage/logs

volumes:
  mixpost-storage:
  mixpost-logs:
EOF
}
