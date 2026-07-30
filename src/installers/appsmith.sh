INSTALL_DISPLAY="Appsmith"
INSTALL_CREDENTIALS="create the admin account on first visit"
INSTALL_NOTES="Low-code internal-tool builder. First boot takes 60-90s while it initialises. Apps are built in the browser UI, not in this project directory."

# first boot initialises its bundled stack, so the default 75s readiness window is not enough.
INSTALL_READY_RETRIES=30

write_files() {
    cat > docker-compose.yaml << 'COMPOSE'
services:
  app:
    image: appsmith/appsmith-ce:v2.2
    restart: unless-stopped
    environment:
      - APPSMITH_MAIL_ENABLED=false
      - APPSMITH_DISABLE_TELEMETRY=true
      - APPSMITH_DISABLE_INTERCOM=true
    volumes:
      - appsmith-stacks:/appsmith-stacks

volumes:
  appsmith-stacks:
COMPOSE
}
