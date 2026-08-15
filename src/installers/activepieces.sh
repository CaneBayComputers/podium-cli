INSTALL_DISPLAY="Activepieces"
INSTALL_CREDENTIALS="Register on first visit (first user becomes the platform admin)"
INSTALL_NOTES="Community edition. Piece metadata is fetched from Activepieces Cloud on first boot, so the flow builder needs internet access."

pre_install() {
    docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE activepieces;" 2>/dev/null || true
}

write_files() {
    local encryption_key jwt_secret
    encryption_key=$(openssl rand -hex 16)
    jwt_secret=$(openssl rand -hex 32)

    cat > .env << EOF
AP_ENGINE_EXECUTABLE_PATH=dist/packages/engine/main.js
AP_ENVIRONMENT=prod
AP_FRONTEND_URL=http://activepieces
AP_ENCRYPTION_KEY=$encryption_key
AP_JWT_SECRET=$jwt_secret
AP_EXECUTION_MODE=UNSANDBOXED
AP_DB_TYPE=POSTGRES
AP_POSTGRES_HOST=podium-postgres
AP_POSTGRES_PORT=5432
AP_POSTGRES_DATABASE=activepieces
AP_POSTGRES_USERNAME=root
AP_POSTGRES_PASSWORD=password
AP_QUEUE_MODE=REDIS
AP_REDIS_HOST=podium-redis
AP_REDIS_PORT=6379
AP_WEBHOOK_TIMEOUT_SECONDS=30
AP_TRIGGER_DEFAULT_POLL_INTERVAL=5
AP_FLOW_TIMEOUT_SECONDS=600
AP_TELEMETRY_ENABLED=false
AP_TEMPLATES_SOURCE_URL=https://cloud.activepieces.com/api/v1/flow-templates
EOF

    cat > docker-compose.yaml << 'EOF'
services:
  app:
    image: activepieces/activepieces:0.86.3
    restart: unless-stopped
    env_file: .env
    environment:
      AP_CONTAINER_TYPE: APP
    volumes:
      - activepieces-cache:/usr/src/app/cache

  worker:
    image: activepieces/activepieces:0.86.3
    restart: unless-stopped
    env_file: .env
    environment:
      AP_CONTAINER_TYPE: WORKER
    volumes:
      - activepieces-cache:/usr/src/app/cache
    depends_on:
      - app

volumes:
  activepieces-cache:
EOF
}
