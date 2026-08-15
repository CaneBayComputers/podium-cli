INSTALL_DISPLAY="BudgE"
INSTALL_CREDENTIALS="Register on first visit"
INSTALL_NOTES="Upstream is alpha-quality. Data lives in SQLite under /config — no external database is used."

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  web:
    image: lscr.io/linuxserver/budge:0.0.9-ls189
    restart: unless-stopped
    environment:
      PUID: "1000"
      PGID: "1000"
      TZ: "Etc/UTC"
    volumes:
      - budge-config:/config

volumes:
  budge-config:
EOF
}
