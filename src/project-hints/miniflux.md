# Miniflux

Miniflux is distributed as `miniflux/miniflux:latest`. It is a minimalist RSS reader that listens on port **8080**. Use an nginx reverse proxy to expose it at port 80.

**Critical**: Miniflux supports **PostgreSQL only** — it does NOT support MySQL/MariaDB. Use the shared `podium-postgres` service (host `podium-postgres`, port `5432`, user `root`, password `password`). Create the database first:
```bash
docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE miniflux;"
```

## Setup workflow

1. Create the database: `docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE miniflux;"`
2. `mkdir -p ~/podium-projects/miniflux`
3. Write `docker-compose.yaml` and `nginx.conf` (see below).
4. `cd ~/podium-projects/miniflux && podium setup miniflux --no-startup`
5. `podium up miniflux`
6. Verify: `curl -sI http://miniflux/` — expect HTTP 200 or 302.

## docker-compose.yaml

```yaml
services:
  miniflux-app:
    image: miniflux/miniflux:latest
    restart: unless-stopped
    environment:
      DATABASE_URL: postgres://root:password@podium-postgres:5432/miniflux?sslmode=disable
      RUN_MIGRATIONS: "1"
      CREATE_ADMIN: "1"
      ADMIN_USERNAME: admin
      ADMIN_PASSWORD: admin123
      BASE_URL: http://miniflux/
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: miniflux
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - miniflux-app

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
        proxy_pass http://miniflux-app:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Admin

- URL: `http://miniflux/`
- Credentials: `admin` / `admin123`
