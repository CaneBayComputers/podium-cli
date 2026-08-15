INSTALL_DISPLAY="Fizzy"
INSTALL_CREDENTIALS="sign up with any email on first visit"
INSTALL_NOTES="No SMTP is configured, so the 6-character sign-in code is printed in the logs: 'docker logs fizzy | grep -i code'."

write_files() {
    local secret_key_base
    secret_key_base=$(openssl rand -hex 64)

    cat > docker-compose.yaml << EOF
services:
  web:
    image: ghcr.io/basecamp/fizzy:sha-bbb6948
    restart: unless-stopped
    environment:
      SECRET_KEY_BASE: "$secret_key_base"
      DISABLE_SSL: "true"
      BASE_URL: http://fizzy
      MULTI_TENANT: "false"
    volumes:
      - fizzy-storage:/rails/storage

volumes:
  fizzy-storage:
EOF
}
