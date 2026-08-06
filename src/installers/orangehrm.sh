INSTALL_DISPLAY="OrangeHRM"
INSTALL_CREDENTIALS="Set during the web install wizard"
INSTALL_NOTES="Web installer only. When it asks for the database use host podium-mariadb, port 3306, database orangehrm, user orangehrm, password orangehrm."

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "
        CREATE DATABASE IF NOT EXISTS orangehrm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        CREATE USER IF NOT EXISTS 'orangehrm'@'%' IDENTIFIED BY 'orangehrm';
        ALTER USER 'orangehrm'@'%' IDENTIFIED BY 'orangehrm';
        GRANT ALL PRIVILEGES ON orangehrm.* TO 'orangehrm'@'%';
        FLUSH PRIVILEGES;
    "
}

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  app:
    image: orangehrm/orangehrm:5.9
    restart: unless-stopped
    environment:
      PHP_MEMORY_LIMIT: 512M
    volumes:
      - orangehrm-app:/var/www/html

volumes:
  orangehrm-app:
EOF
}
