INSTALL_DISPLAY="ntfy"
INSTALL_CREDENTIALS="no login — anonymous read-write on every topic by default"
INSTALL_NOTES="Publish with: curl -d 'hello' http://ntfy/mytopic"

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  app:
    image: binwiederhier/ntfy:v2.27.0
    restart: unless-stopped
    command: serve
    environment:
      NTFY_BASE_URL: http://ntfy
      NTFY_LISTEN_HTTP: ":80"
      NTFY_BEHIND_PROXY: "true"
      NTFY_CACHE_FILE: /var/cache/ntfy/cache.db
      NTFY_CACHE_DURATION: "12h"
      NTFY_ATTACHMENT_CACHE_DIR: /var/cache/ntfy/attachments
      NTFY_AUTH_FILE: /var/lib/ntfy/user.db
      NTFY_AUTH_DEFAULT_ACCESS: read-write
      NTFY_ENABLE_LOGIN: "true"
    volumes:
      - ntfy-cache:/var/cache/ntfy
      - ntfy-data:/var/lib/ntfy

volumes:
  ntfy-cache:
  ntfy-data:
EOF
}
