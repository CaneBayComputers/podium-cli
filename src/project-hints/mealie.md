# Mealie

Mealie is a self-hosted recipe manager distributed as `ghcr.io/mealie-recipes/mealie:latest`. It listens on port **9000**. Use an nginx reverse proxy to expose it at port 80.

No external database is needed — Mealie uses SQLite by default. Persist `/app/data` with a named volume.

## Setup workflow

1. `mkdir -p ~/podium-projects/mealie`
2. Write `docker-compose.yaml` and `nginx.conf` (see below).
3. `cd ~/podium-projects/mealie && podium setup mealie --no-startup`
4. `podium up mealie`
5. Verify: `curl -sI http://mealie/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  mealie-app:
    image: ghcr.io/mealie-recipes/mealie:latest
    restart: unless-stopped
    environment:
      BASE_URL: http://mealie
      ALLOW_SIGNUP: "true"
      TZ: UTC
    volumes:
      - mealie-data:/app/data
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: mealie
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - mealie-app

volumes:
  mealie-data:

networks:
  default:
    external: true
    name: podium-cli_vpc
```

## nginx.conf

```nginx
server {
    listen 80;
    location / {
        proxy_pass http://mealie-app:9000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Admin

- URL: `http://mealie/`
- Default credentials: `changeme@example.com` / `MyPassword`
