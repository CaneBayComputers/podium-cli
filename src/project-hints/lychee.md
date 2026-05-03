# Lychee

Lychee is a self-hosted photo management system distributed as `lycheeorg/lychee:latest`. It listens on port **8000** (not port 80). Use an nginx reverse proxy to expose it at port 80.

**Three requirements before starting:**

1. **APP_KEY** — Lychee requires a Laravel app key. Generate one:
   ```bash
   openssl rand -base64 32
   ```
   Prefix with `base64:` → e.g. `base64:abc123...`

2. **Dedicated DB user** — Lychee's entrypoint rejects an empty password. Create a dedicated user:
   ```bash
   docker exec podium-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS lychee; CREATE USER IF NOT EXISTS 'lychee'@'%' IDENTIFIED BY 'lycheepass'; GRANT ALL PRIVILEGES ON lychee.* TO 'lychee'@'%'; FLUSH PRIVILEGES;"
   ```

3. **Port 8000** — the default CMD starts on port 8000. Use an nginx proxy or override the CMD to `--port=80`.

## Setup workflow

1. Generate APP_KEY: `openssl rand -base64 32` → prepend `base64:`
2. Create DB: `docker exec podium-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS lychee; CREATE USER IF NOT EXISTS 'lychee'@'%' IDENTIFIED BY 'lycheepass'; GRANT ALL PRIVILEGES ON lychee.* TO 'lychee'@'%'; FLUSH PRIVILEGES;"`
3. `mkdir -p ~/podium-projects/lychee`
4. Write `docker-compose.yaml` and `nginx.conf` (see below).
5. `cd ~/podium-projects/lychee && podium setup lychee --no-startup`
6. `podium up lychee`
7. Verify: `curl -sI http://lychee/` — expect HTTP 200 or 302.

## docker-compose.yaml

```yaml
services:
  lychee-app:
    image: lycheeorg/lychee:latest
    restart: unless-stopped
    environment:
      DB_CONNECTION: mysql
      DB_HOST: podium-mariadb
      DB_PORT: 3306
      DB_DATABASE: lychee
      DB_USERNAME: lychee
      DB_PASSWORD: "lycheepass"
      APP_URL: http://lychee
      APP_KEY: "base64:REPLACE_WITH_GENERATED_KEY"
      TIMEZONE: UTC
    volumes:
      - lychee-uploads:/var/www/html/public/uploads
      - lychee-sym:/var/www/html/public/sym
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: lychee
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - lychee-app

volumes:
  lychee-uploads:
  lychee-sym:

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
        proxy_pass http://lychee-app:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Admin

- URL: `http://lychee/`
- Install wizard appears on first visit at `/install/admin` — create admin account there.
