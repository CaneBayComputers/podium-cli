INSTALL_DISPLAY="NocoBase"
INSTALL_CREDENTIALS="admin@nocobase.com / admin123"
INSTALL_NOTES="First boot installs the plugin set and can take several minutes."
INSTALL_READY_RETRIES=90

pre_install() {
    docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE nocobase;" 2>/dev/null || true
}

write_files() {
    local app_key
    app_key=$(openssl rand -hex 32)

    cat > docker-compose.yaml << EOF
services:
  app:
    image: nocobase/nocobase:2.1.36
    restart: unless-stopped
    init: true
    environment:
      APP_KEY: "$app_key"
      DB_DIALECT: postgres
      DB_HOST: podium-postgres
      DB_PORT: 5432
      DB_DATABASE: nocobase
      DB_USER: root
      DB_PASSWORD: password
      TZ: UTC
    volumes:
      - nocobase-storage:/app/nocobase/storage

volumes:
  nocobase-storage:
EOF
}
