INSTALL_DISPLAY="Gotify"
INSTALL_CREDENTIALS="admin / admin123"
INSTALL_NOTES="Change the admin password after first login — Gotify has no forced password reset."

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  app:
    image: gotify/server:3.0.0
    restart: unless-stopped
    environment:
      GOTIFY_DEFAULTUSER_NAME: admin
      GOTIFY_DEFAULTUSER_PASS: admin123
      TZ: UTC
    volumes:
      - gotify-data:/app/data

volumes:
  gotify-data:
EOF
}
