INSTALL_DISPLAY="Easy!Appointments"
INSTALL_CREDENTIALS="set your admin account in the installation wizard on first visit"
INSTALL_NOTES="First visit lands on /index.php/installation — fill in the form to create the schema and admin user."

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS easyappointments CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
}

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  app:
    image: alextselegidis/easyappointments:1.6.0
    restart: unless-stopped
    environment:
      BASE_URL: http://easyappointments
      DEBUG_MODE: "FALSE"
      DB_HOST: podium-mariadb
      DB_NAME: easyappointments
      DB_USERNAME: root
      DB_PASSWORD: ""
      MAIL_PROTOCOL: smtp
      MAIL_SMTP_HOST: podium-mailhog
      MAIL_SMTP_PORT: "1025"
      MAIL_SMTP_CRYPTO: ""
      MAIL_FROM_ADDRESS: noreply@easyappointments.local
      MAIL_FROM_NAME: Easy!Appointments
EOF
}
