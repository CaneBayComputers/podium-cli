INSTALL_DISPLAY="Kanboard"
INSTALL_CREDENTIALS="admin / admin"

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  kanboard:
    image: kanboard/kanboard:latest
    restart: unless-stopped
    volumes:
      - kanboard-data:/var/www/app/data
      - kanboard-plugins:/var/www/app/plugins

volumes:
  kanboard-data:
  kanboard-plugins:
EOF
}
