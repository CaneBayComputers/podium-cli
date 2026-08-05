INSTALL_DISPLAY="Dolibarr ERP/CRM"
INSTALL_CREDENTIALS="admin / admin123"
INSTALL_NOTES="First boot runs the auto-installer and takes ~60 seconds before the login page appears."

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "
        CREATE DATABASE IF NOT EXISTS dolibarr CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        CREATE USER IF NOT EXISTS 'dolibarr'@'%' IDENTIFIED BY 'dolibarr';
        GRANT ALL PRIVILEGES ON dolibarr.* TO 'dolibarr'@'%';
        FLUSH PRIVILEGES;
    "
}

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  app:
    image: dolibarr/dolibarr:23.0.3
    restart: unless-stopped
    environment:
      DOLI_DB_TYPE: mysqli
      DOLI_DB_HOST: podium-mariadb
      DOLI_DB_HOST_PORT: 3306
      DOLI_DB_NAME: dolibarr
      DOLI_DB_USER: dolibarr
      DOLI_DB_PASSWORD: dolibarr
      DOLI_ADMIN_LOGIN: admin
      DOLI_ADMIN_PASSWORD: admin123
      DOLI_URL_ROOT: http://dolibarr
      DOLI_INSTALL_AUTO: 1
      DOLI_PROD: 1
      DOLI_CRON: 0
      PHP_INI_MEMORY_LIMIT: 512M
    volumes:
      - dolibarr-documents:/var/www/documents
      - dolibarr-custom:/var/www/html/custom

volumes:
  dolibarr-documents:
  dolibarr-custom:
EOF
}
