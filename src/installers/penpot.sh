INSTALL_DISPLAY="Penpot"
INSTALL_NOTES="Open-source design tool. Register at http://penpot/ to create your account. Email verification is disabled."

pre_install() {
    docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE penpot;" 2>/dev/null || true
}

write_files() {
    local secret_key
    secret_key=$(openssl rand -base64 32)

    cat > .env << EOF
PENPOT_VERSION=latest
PENPOT_PUBLIC_URI=http://penpot
PENPOT_SECRET_KEY=$secret_key
EOF

    cat > docker-compose.yaml << 'EOF'
services:
  penpot-frontend:
    image: penpotapp/frontend:${PENPOT_VERSION:-latest}
    restart: unless-stopped
    user: root
    command:
      - /bin/bash
      - -lc
      - "sed -i 's/listen 8080/listen 80/g; s/listen \\[::\\]:8080/listen [::]:80/g' /etc/nginx/nginx.conf /etc/nginx/conf.d/default.conf 2>/dev/null; exec nginx -g 'daemon off;'"
    environment:
      PENPOT_FLAGS: disable-email-verification enable-registration enable-login disable-secure-session-cookies
      PENPOT_PUBLIC_URI: ${PENPOT_PUBLIC_URI:-http://penpot}
      PENPOT_BACKEND_URI: http://penpot-backend:6060
      PENPOT_EXPORTER_URI: http://penpot-exporter:6061
    volumes:
      - penpot-assets:/opt/data/assets
    depends_on:
      - penpot-backend
      - penpot-exporter

  penpot-backend:
    image: penpotapp/backend:${PENPOT_VERSION:-latest}
    restart: unless-stopped
    environment:
      PENPOT_FLAGS: disable-email-verification enable-registration enable-login disable-secure-session-cookies
      PENPOT_SECRET_KEY: ${PENPOT_SECRET_KEY}
      PENPOT_PUBLIC_URI: ${PENPOT_PUBLIC_URI:-http://penpot}
      PENPOT_DATABASE_URI: postgresql://podium-postgres/penpot
      PENPOT_DATABASE_USERNAME: root
      PENPOT_DATABASE_PASSWORD: password
      PENPOT_REDIS_URI: redis://podium-redis/0
      PENPOT_OBJECTS_STORAGE_BACKEND: fs
      PENPOT_OBJECTS_STORAGE_FS_DIRECTORY: /opt/data/assets
      PENPOT_TELEMETRY_ENABLED: "false"
      PENPOT_SMTP_ENABLED: "false"
    volumes:
      - penpot-assets:/opt/data/assets

  penpot-exporter:
    image: penpotapp/exporter:${PENPOT_VERSION:-latest}
    restart: unless-stopped
    environment:
      PENPOT_PUBLIC_URI: http://penpot-frontend
      PENPOT_REDIS_URI: redis://podium-redis/0

volumes:
  penpot-assets:
EOF
}
