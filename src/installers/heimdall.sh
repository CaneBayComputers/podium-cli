INSTALL_DISPLAY="Heimdall"

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  heimdall:
    image: lscr.io/linuxserver/heimdall:latest
    restart: unless-stopped
    environment:
      PUID: 1000
      PGID: 1000
      TZ: UTC
    volumes:
      - heimdall-config:/config

volumes:
  heimdall-config:
EOF
}
