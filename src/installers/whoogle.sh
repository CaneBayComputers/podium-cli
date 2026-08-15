INSTALL_DISPLAY="Whoogle Search"
INSTALL_CREDENTIALS="No login — set WHOOGLE_USER/WHOOGLE_PASS to require one"
INSTALL_NOTES="A metasearch front-end for Google; it needs outbound internet access and can be rate-limited by Google."

write_files() {
    cat > docker-compose.yaml << 'EOF'
services:
  whoogle-app:
    image: benbusby/whoogle-search:1.2.4
    restart: unless-stopped
    pids_limit: 50
    environment:
      EXPOSE_PORT: "5000"
      WHOOGLE_CONFIG_THEME: system
      WHOOGLE_CONFIG_GET_ONLY: "1"
      WHOOGLE_RESULTS_PER_PAGE: "10"
    tmpfs:
      - /config:size=10M,uid=927,gid=927,mode=1700
      - /var/lib/tor:size=15M,uid=927,gid=927,mode=1700
      - /run/tor:size=1M,uid=927,gid=927,mode=1700

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - whoogle-app
EOF

    cat > nginx.conf << 'NGINX'
server {
    listen 80;
    location / {
        proxy_pass http://whoogle-app:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
    }
}
NGINX
}
