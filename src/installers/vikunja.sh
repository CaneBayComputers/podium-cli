INSTALL_DISPLAY="Vikunja"
INSTALL_NOTES="First user to register becomes admin."

pre_install() {
    docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS vikunja;"
}

write_files() {
    local jwt_secret
    jwt_secret=$(openssl rand -hex 32)

    cat > docker-compose.yaml << EOF
services:
  vikunja-app:
    image: vikunja/vikunja:latest
    restart: unless-stopped
    environment:
      VIKUNJA_DATABASE_TYPE: mysql
      VIKUNJA_DATABASE_HOST: podium-mariadb
      VIKUNJA_DATABASE_USER: root
      VIKUNJA_DATABASE_PASSWORD: ""
      VIKUNJA_DATABASE_DATABASE: vikunja
      VIKUNJA_SERVICE_JWTSECRET: "$jwt_secret"
      VIKUNJA_SERVICE_FRONTENDURL: http://vikunja/
    volumes:
      - vikunja-files:/app/vikunja/files

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - vikunja-app

volumes:
  vikunja-files:
EOF

    cat > nginx.conf << 'NGINX'
server {
    listen 80;
    location / {
        proxy_pass http://vikunja-app:3456;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX
}
