INSTALL_DISPLAY="File Browser"
INSTALL_CREDENTIALS="admin / random password printed in the container log on first boot"
INSTALL_NOTES="Grab the generated password from the logs, or set your own: docker exec -it <container> filebrowser users update admin --password newpass -d /database/filebrowser.db"

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  app:
    image: filebrowser/filebrowser:v2.63.23
    restart: unless-stopped
    environment:
      FB_PORT: 80
      FB_BASEURL: ""
      FB_ROOT: /srv
      FB_DATABASE: /database/filebrowser.db
    volumes:
      - filebrowser-config:/config
      - filebrowser-database:/database
      - filebrowser-files:/srv

volumes:
  filebrowser-config:
  filebrowser-database:
  filebrowser-files:
EOF
}
