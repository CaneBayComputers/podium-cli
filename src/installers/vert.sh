INSTALL_DISPLAY="VERT"
INSTALL_CREDENTIALS="no login required"
INSTALL_NOTES="Image, audio and document conversion run in the browser and work fine; video conversion needs a separate vertd daemon and is not wired up."

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  app:
    image: ghcr.io/vert-sh/vert:sha-e1c83ba
    restart: unless-stopped
EOF
}
