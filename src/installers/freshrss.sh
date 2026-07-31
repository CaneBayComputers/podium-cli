INSTALL_DISPLAY="FreshRSS"
INSTALL_NOTES="Run the web installer on first visit to create your admin account."

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  freshrss:
    image: freshrss/freshrss:latest
    restart: unless-stopped
    environment:
      TZ: UTC
      CRON_MIN: "1,31"
    volumes:
      - freshrss-data:/var/www/FreshRSS/data
      - freshrss-extensions:/var/www/FreshRSS/extensions

volumes:
  freshrss-data:
  freshrss-extensions:
EOF
}
