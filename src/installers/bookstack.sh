INSTALL_DISPLAY="BookStack"
INSTALL_CREDENTIALS="admin@admin.com / password"

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS bookstack CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
}

write_files() {
    local app_key
    app_key="base64:$(openssl rand -base64 32)"

    cat > docker-compose.yaml << EOF
services:
  bookstack-app:
    image: lscr.io/linuxserver/bookstack:latest
    restart: unless-stopped
    environment:
      PUID: 1000
      PGID: 1000
      TZ: UTC
      APP_URL: http://bookstack
      APP_KEY: "$app_key"
      DB_HOST: podium-mariadb
      DB_PORT: 3306
      DB_DATABASE: bookstack
      DB_USERNAME: root
      DB_PASSWORD: ""
    volumes:
      - bookstack-config:/config

volumes:
  bookstack-config:
EOF
}
