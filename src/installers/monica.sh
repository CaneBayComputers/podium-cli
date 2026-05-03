INSTALL_DISPLAY="Monica CRM"
INSTALL_NOTES="Register your account on first visit — no default credentials."

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS monica;"
}

write_files() {
    local app_key
    app_key="base64:$(openssl rand -base64 32)"

    cat > docker-compose.yaml << EOF
services:
  monica-app:
    image: monica:latest
    restart: unless-stopped
    environment:
      APP_ENV: production
      APP_KEY: "$app_key"
      APP_URL: http://monica
      APP_FORCE_HTTPS: "false"
      DB_CONNECTION: mysql
      DB_HOST: podium-mariadb
      DB_PORT: 3306
      DB_DATABASE: monica
      DB_USERNAME: root
      DB_PASSWORD: ""
      CACHE_DRIVER: redis
      SESSION_DRIVER: redis
      QUEUE_CONNECTION: redis
      REDIS_HOST: podium-redis
      REDIS_PORT: 6379
    volumes:
      - monica-data:/var/www/html/storage

volumes:
  monica-data:
EOF
}
