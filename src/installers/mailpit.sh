INSTALL_DISPLAY="Mailpit"
INSTALL_CREDENTIALS="no login required"
INSTALL_NOTES="SMTP sink on mailpit:1025 — point an app's mail host at it, then read the messages at http://mailpit/"

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  app:
    image: axllent/mailpit:v1.30.6
    restart: unless-stopped
    environment:
      MP_UI_BIND_ADDR: "[::]:80"
      MP_SMTP_BIND_ADDR: "[::]:1025"
      MP_DATABASE: /data/mailpit.db
      MP_MAX_MESSAGES: "5000"
      MP_SMTP_AUTH_ACCEPT_ANY: "true"
      MP_SMTP_AUTH_ALLOW_INSECURE: "true"
    volumes:
      - mailpit-data:/data

volumes:
  mailpit-data:
EOF
}
