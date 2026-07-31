INSTALL_DISPLAY="Grocy"
INSTALL_CREDENTIALS="admin / admin"

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  grocy:
    image: lscr.io/linuxserver/grocy:latest
    restart: unless-stopped
    environment:
      PUID: 1000
      PGID: 1000
      TZ: UTC
    volumes:
      - grocy-config:/config

volumes:
  grocy-config:
EOF
}
