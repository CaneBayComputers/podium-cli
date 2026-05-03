INSTALL_DISPLAY="Mattermost"
INSTALL_NOTES="Create the System Admin account on first visit."

pre_install() {
    docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE mattermost;" 2>/dev/null || true
}

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  mattermost-app:
    image: mattermost/mattermost-team-edition:latest
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp
    environment:
      TZ: UTC
      MM_SQLSETTINGS_DRIVERNAME: postgres
      MM_SQLSETTINGS_DATASOURCE: "postgres://root:password@podium-postgres:5432/mattermost?sslmode=disable&connect_timeout=10"
      MM_BLEVESETTINGS_INDEXDIR: /mattermost/bleve-indexes
      MM_SERVICESETTINGS_SITEURL: http://mattermost
      MM_SERVICESETTINGS_LISTENADDRESS: ":8065"
    volumes:
      - mattermost-config:/mattermost/config:rw
      - mattermost-data:/mattermost/data:rw
      - mattermost-logs:/mattermost/logs:rw
      - mattermost-plugins:/mattermost/plugins:rw
      - mattermost-client-plugins:/mattermost/client/plugins:rw
      - mattermost-bleve-indexes:/mattermost/bleve-indexes:rw

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - mattermost-app

volumes:
  mattermost-config:
  mattermost-data:
  mattermost-logs:
  mattermost-plugins:
  mattermost-client-plugins:
  mattermost-bleve-indexes:
EOF

    cat > nginx.conf << 'NGINX'
upstream mattermost_backend {
    server mattermost-app:8065;
    keepalive 32;
}

server {
    listen 80;
    client_max_body_size 100M;

    location ~ /api/v[0-9]+/(users/)?websocket$ {
        proxy_pass http://mattermost_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }

    location / {
        proxy_pass http://mattermost_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 600s;
    }
}
NGINX
}
