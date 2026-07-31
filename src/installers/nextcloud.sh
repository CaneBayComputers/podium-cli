INSTALL_DISPLAY="Nextcloud"
INSTALL_NOTES="Complete the admin account setup on first visit."

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
}

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  nextcloud-app:
    image: nextcloud:latest
    restart: unless-stopped
    environment:
      MYSQL_HOST: podium-mariadb
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: root
      MYSQL_PASSWORD: ""
      REDIS_HOST: podium-redis
      REDIS_HOST_PORT: 6379
      NEXTCLOUD_TRUSTED_DOMAINS: nextcloud
      OVERWRITEHOST: nextcloud
      OVERWRITEPROTOCOL: http
    volumes:
      - nextcloud-data:/var/www/html

volumes:
  nextcloud-data:
EOF
}
