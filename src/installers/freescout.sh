INSTALL_DISPLAY="FreeScout"
INSTALL_CREDENTIALS="admin@freescout.local / freescout-admin"
INSTALL_NOTES="FreeScout is a help desk / shared inbox. Visit http://$PROJECT_NAME/ to access."

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS freescout CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    # FreeScout requires a dedicated DB user — the tiredofit image rejects root
    docker exec podium-mariadb mariadb -u root -e "
        CREATE USER IF NOT EXISTS 'freescout'@'%' IDENTIFIED BY 'freescout';
        GRANT ALL PRIVILEGES ON freescout.* TO 'freescout'@'%';
        FLUSH PRIVILEGES;
    "
}

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  freescout-app:
    image: tiredofit/freescout:latest
    restart: unless-stopped
    environment:
      ADMIN_EMAIL: admin@freescout.local
      ADMIN_FIRST_NAME: Admin
      ADMIN_LAST_NAME: User
      ADMIN_PASS: freescout-admin
      APPLICATION_NAME: FreeScout
      SITE_URL: http://freescout
      SETUP_TYPE: AUTO
      DB_TYPE: mysql
      DB_HOST: podium-mariadb
      DB_PORT: 3306
      DB_NAME: freescout
      DB_USER: freescout
      DB_PASS: freescout
      DB_SSL: "FALSE"
      ENABLE_AUTO_UPDATE: "FALSE"
      DISPLAY_ERRORS: "FALSE"
      TZ: UTC
    volumes:
      - freescout-data:/data
      - freescout-logs:/www/logs

volumes:
  freescout-data:
  freescout-logs:
EOF
}
