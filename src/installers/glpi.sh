INSTALL_DISPLAY="GLPI"
INSTALL_CREDENTIALS="glpi / glpi"
INSTALL_NOTES="Headless auto-install runs on first boot; change the four default accounts (glpi, tech, normal, post-only) right away."

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "
        CREATE DATABASE IF NOT EXISTS glpi CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        CREATE USER IF NOT EXISTS 'glpi'@'%' IDENTIFIED BY 'glpi';
        GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'%';
        GRANT SELECT ON mysql.time_zone_name TO 'glpi'@'%';
        FLUSH PRIVILEGES;
    "
}

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  app:
    image: glpi/glpi:11.0.8
    restart: unless-stopped
    environment:
      GLPI_DB_HOST: podium-mariadb
      GLPI_DB_PORT: 3306
      GLPI_DB_NAME: glpi
      GLPI_DB_USER: glpi
      GLPI_DB_PASSWORD: glpi
      GLPI_SKIP_AUTOINSTALL: "false"
      GLPI_SKIP_AUTOUPDATE: "false"
      GLPI_CRONTAB_ENABLED: "1"
    volumes:
      - glpi-data:/var/glpi

volumes:
  glpi-data:
EOF
}
