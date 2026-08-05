INSTALL_DISPLAY="Campfire (ONCE)"
INSTALL_CREDENTIALS="register on first visit — the first account becomes the admin"
INSTALL_NOTES="SQLite-backed: everything lives in the /rails/storage volume, no shared database is used."

write_files() {
    local secret_key_base der vapid_private vapid_public
    secret_key_base=$(openssl rand -hex 64)

    # VAPID keys are a P-256 key pair, base64url-encoded raw scalar / raw point.
    der=$(openssl ecparam -name prime256v1 -genkey -noout -outform DER 2>/dev/null | base64 | tr -d '\n')
    vapid_private=$(python3 -c "import base64; d=base64.b64decode('$der'); print(base64.urlsafe_b64encode(d[7:39]).decode().rstrip('='))")
    vapid_public=$(python3 -c "import base64; d=base64.b64decode('$der'); print(base64.urlsafe_b64encode(d[-65:]).decode().rstrip('='))")

    cat > docker-compose.yaml << EOF
services:
  app:
    image: ghcr.io/basecamp/once-campfire:1.4.9
    restart: unless-stopped
    environment:
      SECRET_KEY_BASE: "$secret_key_base"
      VAPID_PUBLIC_KEY: "$vapid_public"
      VAPID_PRIVATE_KEY: "$vapid_private"
      DISABLE_SSL: "true"
      SKIP_TELEMETRY: "true"
    volumes:
      - once-campfire-storage:/rails/storage

volumes:
  once-campfire-storage:
EOF
}
