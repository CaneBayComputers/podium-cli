INSTALL_DISPLAY="Strapi"
INSTALL_NOTES="Visit http://strapi/admin to create the admin account on first launch. First startup takes ~60 seconds while Strapi builds."

pre_install() {
    docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE strapi;" 2>/dev/null || true
}

write_files() {
    local app_keys api_token_salt admin_jwt_secret transfer_token_salt jwt_secret
    app_keys="$(openssl rand -hex 16),$(openssl rand -hex 16)"
    api_token_salt=$(openssl rand -hex 16)
    admin_jwt_secret=$(openssl rand -hex 32)
    transfer_token_salt=$(openssl rand -hex 16)
    jwt_secret=$(openssl rand -hex 32)

    cat > docker-compose.yaml << EOF
services:
  strapi-app:
    image: naskio/strapi:latest
    restart: unless-stopped
    environment:
      DATABASE_CLIENT: postgres
      DATABASE_HOST: podium-postgres
      DATABASE_PORT: 5432
      DATABASE_NAME: strapi
      DATABASE_USERNAME: root
      DATABASE_PASSWORD: password
      APP_KEYS: "$app_keys"
      API_TOKEN_SALT: $api_token_salt
      ADMIN_JWT_SECRET: $admin_jwt_secret
      TRANSFER_TOKEN_SALT: $transfer_token_salt
      JWT_SECRET: $jwt_secret
      NODE_ENV: production
    volumes:
      - strapi-uploads:/opt/app/public/uploads

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - strapi-app

volumes:
  strapi-uploads:
EOF

    cat > nginx.conf << 'NGINX'
server {
    listen 80;
    client_max_body_size 100M;
    location / {
        proxy_pass http://strapi-app:1337;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 300;
    }
}
NGINX
}
