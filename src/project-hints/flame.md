# Flame

Flame is a self-hosted startpage/dashboard distributed as `pawelmalak/flame:latest`. It listens on port **5005**. Use an nginx reverse proxy to expose it at port 80.

No external database is needed — Flame uses SQLite stored at `/app/data`. Persist this with a named volume.

## Setup workflow

1. `mkdir -p ~/podium-projects/flame`
2. Write `docker-compose.yaml` and `nginx.conf` (see below).
3. `cd ~/podium-projects/flame && podium setup flame --no-startup`
4. `podium up flame`
5. Verify: `curl -sI http://flame/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  flame-app:
    image: pawelmalak/flame:latest
    restart: unless-stopped
    environment:
      PASSWORD: admin
    volumes:
      - flame-data:/app/data
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: flame
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - flame-app

volumes:
  flame-data:

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
        proxy_pass http://flame-app:5005;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Admin

- URL: `http://flame/`
- Password: `admin` (set via `PASSWORD` env var)
