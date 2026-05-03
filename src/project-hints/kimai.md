# Kimai

Kimai is an open-source time-tracking application. Use image `kimai/kimai2:apache`. The Apache-based image listens on port **8001**. Use an nginx reverse proxy to expose it at port 80.

Use the shared MariaDB: host `podium-mariadb`, port `3306`, user `root`, password `` (empty).

`APP_SECRET` must be set to any random string.

After the container starts, create the admin user:
```bash
docker exec kimai-app console kimai:user:create admin admin@example.com ROLE_SUPER_ADMIN admin123
```

## Setup workflow

1. `mkdir -p ~/podium-projects/kimai`
2. Write `docker-compose.yaml` and `nginx.conf` (see below).
3. `cd ~/podium-projects/kimai && podium setup kimai --no-startup`
4. `podium up kimai`
5. Create admin user (see above).
6. Verify: `curl -sI http://kimai/` — expect HTTP 200 or 302.

## docker-compose.yaml

```yaml
services:
  kimai-app:
    image: kimai/kimai2:apache
    container_name: kimai-app
    restart: unless-stopped
    environment:
      APP_ENV: prod
      TRUSTED_HOSTS: kimai
      ADMINMAIL: admin@example.com
      ADMINPASS: admin123
      DATABASE_URL: mysql://root:@podium-mariadb:3306/kimai
      APP_SECRET: "a-random-secret-string-12345"
    volumes:
      - kimai-data:/opt/kimai/var/data
      - kimai-plugins:/opt/kimai/var/plugins
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: kimai
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - kimai-app

volumes:
  kimai-data:
  kimai-plugins:

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
        proxy_pass http://kimai-app:8001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Admin

- URL: `http://kimai/`
- Credentials: `admin@example.com` / `admin123`
