INSTALL_DISPLAY="Hoppscotch"
INSTALL_CREDENTIALS="first account to sign in at /admin becomes the admin"
INSTALL_NOTES="Runs in subpath mode: app at /, admin dashboard at /admin, backend at /backend."

pre_install() {
    docker exec -e PGPASSWORD=password podium-postgres psql -U root -d postgres \
      -c "CREATE DATABASE \"hoppscotch\";" 2>/dev/null || true
}

write_files() {
    local encryption_key
    encryption_key=$(openssl rand -hex 16)

    cat > docker-compose.yaml << EOF
services:
  app:
    image: hoppscotch/hoppscotch:2026.7.0
    restart: unless-stopped
    environment:
      ENABLE_SUBPATH_BASED_ACCESS: "true"
      DATABASE_URL: postgresql://root:password@podium-postgres:5432/hoppscotch
      DATA_ENCRYPTION_KEY: "$encryption_key"
      WHITELISTED_ORIGINS: "http://hoppscotch,app://hoppscotch,app://localhost_3200"
      TRUST_PROXY: "true"
      VITE_BASE_URL: http://hoppscotch
      VITE_SHORTCODE_BASE_URL: http://hoppscotch
      VITE_ADMIN_URL: http://hoppscotch/admin
      VITE_BACKEND_GQL_URL: http://hoppscotch/backend/graphql
      VITE_BACKEND_WS_URL: ws://hoppscotch/backend/graphql
      VITE_BACKEND_API_URL: http://hoppscotch/backend/v1
EOF
}
