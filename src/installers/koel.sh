INSTALL_DISPLAY="Koel"
INSTALL_CREDENTIALS="admin@example.com / KoelAdmin123"
INSTALL_NOTES="Place your music files in the koel-music volume then scan from the admin panel."

pre_install() {
    docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE koel;" 2>/dev/null || true
}

write_files() {
    local app_key
    app_key="base64:$(openssl rand -base64 32)"

    cat > docker-compose.yaml << EOF
services:
  koel-app:
    image: phanan/koel:latest
    restart: unless-stopped
    environment:
      APP_KEY: $app_key
      APP_URL: http://koel
      DB_CONNECTION: pgsql
      DB_HOST: podium-postgres
      DB_PORT: 5432
      DB_DATABASE: koel
      DB_USERNAME: root
      DB_PASSWORD: password
      FORCE_HTTPS: "false"
      ADMIN_EMAIL: admin@example.com
      ADMIN_NAME: Admin
      ADMIN_PASSWORD: KoelAdmin123
      MEMORY_LIMIT: 512
    volumes:
      - koel-music:/music
      - koel-search-indexes:/var/www/html/storage/search-indexes

volumes:
  koel-music:
  koel-search-indexes:
EOF
}
