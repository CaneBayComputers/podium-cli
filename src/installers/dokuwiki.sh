INSTALL_DISPLAY="DokuWiki"
INSTALL_CREDENTIALS="Create the admin at http://dokuwiki/install.php"
INSTALL_NOTES="Delete install.php from the container once setup finishes: podium exec dokuwiki rm /app/dokuwiki/install.php"
INSTALL_READY_RETRIES=30

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  app:
    image: lscr.io/linuxserver/dokuwiki:version-2026-07-14a
    restart: unless-stopped
    environment:
      PUID: 1000
      PGID: 1000
      TZ: Etc/UTC
    volumes:
      - dokuwiki-config:/config

volumes:
  dokuwiki-config:
EOF
}
