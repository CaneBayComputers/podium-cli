INSTALL_DISPLAY="ClassicPress"
INSTALL_CREDENTIALS="set your admin account in the five-minute install on first visit"
INSTALL_NOTES="Config env vars use the CLASSICPRESS_ prefix, not WORDPRESS_, and the default table prefix is cp_."

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS classicpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
}

write_files() {
    local auth_key secure_auth_key logged_in_key nonce_key auth_salt secure_auth_salt logged_in_salt nonce_salt
    auth_key=$(openssl rand -hex 32)
    secure_auth_key=$(openssl rand -hex 32)
    logged_in_key=$(openssl rand -hex 32)
    nonce_key=$(openssl rand -hex 32)
    auth_salt=$(openssl rand -hex 32)
    secure_auth_salt=$(openssl rand -hex 32)
    logged_in_salt=$(openssl rand -hex 32)
    nonce_salt=$(openssl rand -hex 32)

    cat > docker-compose.yaml << EOF
services:
  app:
    image: classicpress/classicpress:php8.4-apache
    restart: unless-stopped
    environment:
      CLASSICPRESS_DB_HOST: podium-mariadb:3306
      CLASSICPRESS_DB_NAME: classicpress
      CLASSICPRESS_DB_USER: root
      CLASSICPRESS_DB_PASSWORD: ""
      CLASSICPRESS_DB_CHARSET: utf8mb4
      CLASSICPRESS_TABLE_PREFIX: cp_
      CLASSICPRESS_AUTH_KEY: "$auth_key"
      CLASSICPRESS_SECURE_AUTH_KEY: "$secure_auth_key"
      CLASSICPRESS_LOGGED_IN_KEY: "$logged_in_key"
      CLASSICPRESS_NONCE_KEY: "$nonce_key"
      CLASSICPRESS_AUTH_SALT: "$auth_salt"
      CLASSICPRESS_SECURE_AUTH_SALT: "$secure_auth_salt"
      CLASSICPRESS_LOGGED_IN_SALT: "$logged_in_salt"
      CLASSICPRESS_NONCE_SALT: "$nonce_salt"
    volumes:
      - classicpress-data:/var/www/html

volumes:
  classicpress-data:
EOF
}
