INSTALL_DISPLAY="Koel"
INSTALL_CREDENTIALS="admin@example.com / KoelAdmin123"
INSTALL_NOTES="Place your music files in the koel-music volume then scan from the admin panel at http://koel/."

# Shared between pre_install and write_files
KOEL_APP_KEY="base64:$(openssl rand -base64 32)"

pre_install() {
    docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE koel;" 2>/dev/null || true

    # Koel's init writes back to .env which can't be bind-mounted writable on all hosts.
    # Instead, run a one-off migration container with env vars directly, then use SKIP_INIT.
    docker run --rm --network podium-cli_vpc \
        --entrypoint /bin/sh \
        -e APP_KEY="$KOEL_APP_KEY" \
        -e APP_URL="http://koel" \
        -e DB_CONNECTION="pgsql" \
        -e DB_HOST="podium-postgres" \
        -e DB_PORT="5432" \
        -e DB_DATABASE="koel" \
        -e DB_USERNAME="root" \
        -e DB_PASSWORD="password" \
        -e FORCE_HTTPS="false" \
        -e ADMIN_EMAIL="admin@example.com" \
        -e ADMIN_NAME="Admin" \
        -e ADMIN_PASSWORD="KoelAdmin123" \
        -e MEMORY_LIMIT="512" \
        phanan/koel:latest \
        -c "php artisan migrate --no-interaction && php artisan db:seed --no-interaction" 2>/dev/null || true
}

write_files() {
    cat > .env << ENV
APP_KEY=$KOEL_APP_KEY
APP_URL=http://koel
DB_CONNECTION=pgsql
DB_HOST=podium-postgres
DB_PORT=5432
DB_DATABASE=koel
DB_USERNAME=root
DB_PASSWORD=password
FORCE_HTTPS=false
ADMIN_EMAIL=admin@example.com
ADMIN_NAME=Admin
ADMIN_PASSWORD=KoelAdmin123
MEMORY_LIMIT=512
ENV

    cat > docker-compose.yaml << 'EOF'
services:
  koel-app:
    image: phanan/koel:latest
    restart: unless-stopped
    env_file: ./.env
    environment:
      SKIP_INIT: "1"
    volumes:
      - koel-music:/music
      - koel-search-indexes:/var/www/html/storage/search-indexes

volumes:
  koel-music:
  koel-search-indexes:
EOF
}
