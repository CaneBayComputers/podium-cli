INSTALL_DISPLAY="BookStack"
INSTALL_CREDENTIALS="admin@admin.com / password"

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS bookstack CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    docker volume rm bookstack_bookstack-config 2>/dev/null || true
}

write_files() {
    local app_key
    app_key="base64:$(openssl rand -base64 32)"

    # Write .env directly — the linuxserver/bookstack image copies a template .env with
    # placeholder values that Laravel reads instead of the container env vars.
    mkdir -p bookstack-config/www
    cat > bookstack-config/www/.env << ENV
APP_KEY=$app_key
APP_URL=http://bookstack
DB_HOST=podium-mariadb
DB_PORT=3306
DB_DATABASE=bookstack
DB_USERNAME=root
DB_PASSWORD=
MAIL_DRIVER=log
ENV

    cat > docker-compose.yaml << EOF
services:
  bookstack-app:
    image: lscr.io/linuxserver/bookstack:latest
    restart: unless-stopped
    environment:
      PUID: 1000
      PGID: 1000
      TZ: UTC
    volumes:
      - ./bookstack-config:/config
EOF
}
