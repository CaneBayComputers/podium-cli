INSTALL_DISPLAY="Trilium Notes"
INSTALL_NOTES="Set your login password on first visit."

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  trilium-app:
    image: zadam/trilium:latest
    restart: unless-stopped
    volumes:
      - trilium-data:/home/node/trilium-data

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - trilium-app

volumes:
  trilium-data:
EOF

    cat > nginx.conf << 'NGINX'
server {
    listen 80;
    location / {
        proxy_pass http://trilium-app:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
NGINX
}
