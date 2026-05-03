# Redmine

Redmine is distributed as `redmine:latest`. It is a project management tool that listens on port **3000**. Use an nginx reverse proxy to expose it at port 80.

Use the shared MariaDB: host `podium-mariadb`, port `3306`, user `root`, password `` (empty).

Create the database before starting:
```bash
docker exec podium-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS redmine CHARACTER SET utf8mb4;"
```

Redmine runs database migrations automatically on first start — wait 30–60 seconds before verifying.

## Setup workflow

1. Create DB: `docker exec podium-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS redmine CHARACTER SET utf8mb4;"`
2. `mkdir -p ~/podium-projects/redmine`
3. Write `docker-compose.yaml` and `nginx.conf` (see below).
4. `cd ~/podium-projects/redmine && podium setup redmine --no-startup`
5. `podium up redmine`
6. Wait 60 seconds for initial setup to complete.
7. Verify: `curl -sI http://redmine/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  redmine-app:
    image: redmine:latest
    restart: unless-stopped
    environment:
      REDMINE_DB_MYSQL: podium-mariadb
      REDMINE_DB_PORT: 3306
      REDMINE_DB_USERNAME: root
      REDMINE_DB_PASSWORD: ""
      REDMINE_DB_DATABASE: redmine
      REDMINE_SECRET_KEY_BASE: "supersecretkeybase1234567890abcdef"
    volumes:
      - redmine-files:/usr/src/redmine/files
      - redmine-plugins:/usr/src/redmine/plugins
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: redmine
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - redmine-app

volumes:
  redmine-files:
  redmine-plugins:

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
        proxy_pass http://redmine-app:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Admin

- URL: `http://redmine/`
- Default credentials: `admin` / `admin` (forced to change on first login)
