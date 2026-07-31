INSTALL_DISPLAY="Vaultwarden"
INSTALL_NOTES="Create an account on first visit. Enable admin panel by adding ADMIN_TOKEN env var."

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  vaultwarden:
    image: vaultwarden/server:1.37.1
    restart: unless-stopped
    environment:
      WEBSOCKET_ENABLED: "true"
      SIGNUPS_ALLOWED: "true"
    volumes:
      - vaultwarden-data:/data

volumes:
  vaultwarden-data:
EOF
}
