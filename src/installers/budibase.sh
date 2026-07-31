INSTALL_DISPLAY="Budibase"
INSTALL_CREDENTIALS="admin@example.com / Budibase123!"
INSTALL_NOTES="Internal CouchDB and Redis are bundled — no external database needed."

write_files() {
    local jwt_secret enc_key
    jwt_secret=$(openssl rand -hex 32)
    enc_key=$(openssl rand -hex 32)

    cat > docker-compose.yaml << EOF
services:
  budibase-app:
    image: budibase/budibase:latest
    restart: unless-stopped
    environment:
      JWT_SECRET: $jwt_secret
      ENCRYPTION_KEY: $enc_key
      BB_ADMIN_USER_EMAIL: admin@example.com
      BB_ADMIN_USER_PASSWORD: Budibase123!
    volumes:
      - budibase-data:/data

volumes:
  budibase-data:
EOF
}
