INSTALL_DISPLAY="Matomo"
INSTALL_CREDENTIALS="Set credentials during setup wizard"
INSTALL_NOTES="First visit shows the installation wizard. Complete it to set your admin account."

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS matomo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
}

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  matomo-app:
    image: matomo:apache
    restart: unless-stopped
    environment:
      MATOMO_DATABASE_HOST: podium-mariadb
      MATOMO_DATABASE_ADAPTER: mysql
      MATOMO_DATABASE_USERNAME: root
      MATOMO_DATABASE_PASSWORD: ""
      MATOMO_DATABASE_DBNAME: matomo
      MATOMO_DATABASE_TABLES_PREFIX: matomo_
      PHP_MEMORY_LIMIT: 512M
    volumes:
      - matomo-data:/var/www/html

volumes:
  matomo-data:
EOF
}
