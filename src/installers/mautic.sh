INSTALL_DISPLAY="Mautic"
INSTALL_CREDENTIALS="Visit http://mautic/ to complete setup wizard"
INSTALL_NOTES="First visit shows the install wizard. Mautic requires a dedicated database user."

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS mautic CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    docker exec podium-mariadb mariadb -u root -e "
        CREATE USER IF NOT EXISTS 'mautic'@'%' IDENTIFIED BY 'MauticDbPass123!';
        GRANT ALL PRIVILEGES ON mautic.* TO 'mautic'@'%';
        FLUSH PRIVILEGES;
    "
}

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  mautic-app:
    image: mautic/mautic:5-apache
    restart: unless-stopped
    environment:
      MAUTIC_DB_HOST: podium-mariadb
      MAUTIC_DB_PORT: "3306"
      MAUTIC_DB_DATABASE: mautic
      MAUTIC_DB_USER: mautic
      MAUTIC_DB_PASSWORD: "MauticDbPass123!"
      MAUTIC_URL: http://mautic
      DOCKER_MAUTIC_ROLE: mautic_web
      DOCKER_MAUTIC_RUN_MIGRATIONS: "true"
      PHP_INI_VALUE_MEMORY_LIMIT: 512M
    volumes:
      - mautic-data:/var/www/html
      - mautic-config:/var/www/html/config
      - mautic-logs:/var/www/html/var/logs
      - mautic-media:/var/www/html/docroot/media

volumes:
  mautic-data:
  mautic-config:
  mautic-logs:
  mautic-media:
EOF
}
