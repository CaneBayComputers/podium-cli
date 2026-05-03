# Stirling PDF

Stirling PDF is distributed as `frooodle/s-pdf:latest`. It is a web-based PDF manipulation tool that listens on port **8080**. Use an nginx reverse proxy to expose it at port 80.

No external database or special configuration is needed.

## Setup workflow

1. `mkdir -p ~/podium-projects/stirling-pdf`
2. Write `docker-compose.yaml` and `nginx.conf` (see below).
3. `cd ~/podium-projects/stirling-pdf && podium setup stirling-pdf --no-startup`
4. `podium up stirling-pdf`
5. Verify: `curl -sI http://stirling-pdf/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  stirling-pdf-app:
    image: frooodle/s-pdf:latest
    restart: unless-stopped
    environment:
      DOCKER_ENABLE_SECURITY: "false"
      SECURITY_ENABLE_LOGIN: "false"
    volumes:
      - stirling-training:/usr/share/tesseract-ocr/5/tessdata
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: stirling-pdf
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - stirling-pdf-app

volumes:
  stirling-training:

networks:
  default:
    external: true
    name: podium-cli_vpc
```

## nginx.conf

```nginx
server {
    listen 80;
    client_max_body_size 100M;
    location / {
        proxy_pass http://stirling-pdf-app:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 300s;
    }
}
```

## Admin

- URL: `http://stirling-pdf/`
- No login required by default.
