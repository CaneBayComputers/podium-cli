INSTALL_DISPLAY="Audiobookshelf"
INSTALL_NOTES="Visit http://$PROJECT_NAME/ to create the admin account on first launch."

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  audiobookshelf-app:
    image: ghcr.io/advplyr/audiobookshelf:latest
    restart: unless-stopped
    volumes:
      - audiobookshelf-config:/config
      - audiobookshelf-metadata:/metadata
      - audiobookshelf-audiobooks:/audiobooks
      - audiobookshelf-podcasts:/podcasts

volumes:
  audiobookshelf-config:
  audiobookshelf-metadata:
  audiobookshelf-audiobooks:
  audiobookshelf-podcasts:
EOF
}
