# Umami

Umami is a privacy-focused analytics platform. Use image `ghcr.io/umami-software/umami:postgresql-latest`. It listens on port **3000**. Use an nginx reverse proxy to expose it at port 80.

**Critical**: Umami supports **PostgreSQL only** — use the `postgresql-latest` tag. Use the shared `podium-postgres` service (host `podium-postgres`, port `5432`, user `root`, password `password`).

Create the database first:
```bash
docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE umami;"
```

`APP_SECRET` must be set to any random string (at least 32 characters).

## Setup workflow

1. Create DB: `docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE umami;"`
2. `mkdir -p ~/podium-projects/umami`
3. Write `docker-compose.yaml` and `nginx.conf` (see below).
4. `cd ~/podium-projects/umami && podium setup umami --no-startup`
5. `podium up umami`
6. Verify: `curl -sI http://umami/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  umami-app:
    image: ghcr.io/umami-software/umami:postgresql-latest
    restart: unless-stopped
    environment:
      DATABASE_URL: postgresql://root:password@podium-postgres:5432/umami
      APP_SECRET: "random-secret-string-at-least-32-chars-long"
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: umami
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - umami-app

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
        proxy_pass http://umami-app:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Admin

- URL: `http://umami/`
- Default credentials: `admin` / `umami`
