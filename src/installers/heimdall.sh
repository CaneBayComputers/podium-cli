INSTALL_DISPLAY="Heimdall"

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  heimdall:
    image: lscr.io/linuxserver/heimdall:2.7.6
    restart: unless-stopped
    environment:
      PUID: 1000
      PGID: 1000
      TZ: Etc/UTC
      ALLOW_INTERNAL_REQUESTS: "true"
    volumes:
      - heimdall-config:/config

volumes:
  heimdall-config:
EOF
}
