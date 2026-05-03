# Vikunja

Vikunja is distributed as `vikunja/vikunja:latest`. It is a self-hosted task manager that listens on port **3456**. Use an nginx reverse proxy to expose it at port 80.

Use the shared MariaDB: host `podium-mariadb`, port `3306`, user `root`, password `` (empty).

Create the database before starting:
```bash
docker exec podium-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS vikunja;"
```

`VIKUNJA_SERVICE_JWTSECRET` must be set to any random string (at least 32 characters).

## Setup workflow

1. Create DB: `docker exec podium-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS vikunja;"`
2. `mkdir -p ~/podium-projects/vikunja`
3. Write `docker-compose.yaml` and `nginx.conf` (see below).
4. `cd ~/podium-projects/vikunja && podium setup vikunja --no-startup`
5. `podium up vikunja`
6. Verify: `curl -sI http://vikunja/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  vikunja-app:
    image: vikunja/vikunja:latest
    restart: unless-stopped
    environment:
      VIKUNJA_DATABASE_TYPE: mysql
      VIKUNJA_DATABASE_HOST: podium-mariadb
      VIKUNJA_DATABASE_USER: root
      VIKUNJA_DATABASE_PASSWORD: ""
      VIKUNJA_DATABASE_DATABASE: vikunja
      VIKUNJA_SERVICE_JWTSECRET: "a-very-secret-random-string-here-1234"
      VIKUNJA_SERVICE_FRONTENDURL: http://vikunja/
    volumes:
      - vikunja-files:/app/vikunja/files
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: vikunja
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - vikunja-app

volumes:
  vikunja-files:

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
        proxy_pass http://vikunja-app:3456;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Admin

- URL: `http://vikunja/`
- Register an account on first visit — the first user becomes admin.
