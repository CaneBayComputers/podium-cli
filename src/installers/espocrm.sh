INSTALL_DISPLAY="EspoCRM"
INSTALL_CREDENTIALS="admin / admin123"
INSTALL_NOTES="First boot builds the database and takes ~60 seconds. The daemon sidecar runs scheduled jobs, workflows and email fetching."

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "
        CREATE DATABASE IF NOT EXISTS espocrm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        CREATE USER IF NOT EXISTS 'espocrm'@'%' IDENTIFIED BY 'espocrm';
        ALTER USER 'espocrm'@'%' IDENTIFIED BY 'espocrm';
        GRANT ALL PRIVILEGES ON espocrm.* TO 'espocrm'@'%';
        FLUSH PRIVILEGES;
    "
}

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  app:
    image: espocrm/espocrm:10.0.3-apache
    restart: unless-stopped
    environment:
      ESPOCRM_DATABASE_PLATFORM: Mysql
      ESPOCRM_DATABASE_HOST: podium-mariadb
      ESPOCRM_DATABASE_PORT: 3306
      ESPOCRM_DATABASE_NAME: espocrm
      ESPOCRM_DATABASE_USER: espocrm
      ESPOCRM_DATABASE_PASSWORD: espocrm
      ESPOCRM_ADMIN_USERNAME: admin
      ESPOCRM_ADMIN_PASSWORD: admin123
      ESPOCRM_SITE_URL: http://espocrm
    volumes:
      - espocrm-data:/var/www/html/data
      - espocrm-custom:/var/www/html/custom
      - espocrm-client-custom:/var/www/html/client/custom

  espocrm-daemon:
    image: espocrm/espocrm:10.0.3-apache
    restart: unless-stopped
    entrypoint: docker-daemon.sh
    environment:
      ESPOCRM_DATABASE_PLATFORM: Mysql
      ESPOCRM_DATABASE_HOST: podium-mariadb
      ESPOCRM_DATABASE_PORT: 3306
      ESPOCRM_DATABASE_NAME: espocrm
      ESPOCRM_DATABASE_USER: espocrm
      ESPOCRM_DATABASE_PASSWORD: espocrm
    volumes:
      - espocrm-data:/var/www/html/data
      - espocrm-custom:/var/www/html/custom
      - espocrm-client-custom:/var/www/html/client/custom
    depends_on:
      - app

volumes:
  espocrm-data:
  espocrm-custom:
  espocrm-client-custom:
EOF
}
