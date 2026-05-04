INSTALL_DISPLAY="Roundcube"
INSTALL_NOTES="Roundcube is a webmail client. It requires an IMAP server to log in. In dev, MailHog is pre-configured as the outbound SMTP server."

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS roundcube CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
}

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  roundcube-app:
    image: roundcube/roundcubemail:latest
    restart: unless-stopped
    environment:
      ROUNDCUBEMAIL_DB_TYPE: mysql
      ROUNDCUBEMAIL_DB_HOST: podium-mariadb
      ROUNDCUBEMAIL_DB_PORT: 3306
      ROUNDCUBEMAIL_DB_NAME: roundcube
      ROUNDCUBEMAIL_DB_USER: root
      ROUNDCUBEMAIL_DB_PASSWORD: ""
      ROUNDCUBEMAIL_SMTP_SERVER: podium-mailhog
      ROUNDCUBEMAIL_SMTP_PORT: 1025
      ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE: 25M
    volumes:
      - roundcube-data:/var/roundcube

volumes:
  roundcube-data:
EOF
}
