# LimeSurvey

LimeSurvey is distributed as `martialblog/limesurvey:latest`. It is an online survey platform that listens on port **8080**. Use an nginx reverse proxy to expose it at port 80.

Use the shared MariaDB, but create a dedicated user — the `martialblog/limesurvey` image requires a **non-empty** database password and will fail with an empty root password:
```bash
docker exec podium-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS limesurvey; CREATE USER IF NOT EXISTS 'limesurvey'@'%' IDENTIFIED BY 'limesurvey'; GRANT ALL PRIVILEGES ON limesurvey.* TO 'limesurvey'@'%'; FLUSH PRIVILEGES;"
```

## Setup workflow

1. Create DB user: `docker exec podium-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS limesurvey; CREATE USER IF NOT EXISTS 'limesurvey'@'%' IDENTIFIED BY 'limesurvey'; GRANT ALL PRIVILEGES ON limesurvey.* TO 'limesurvey'@'%'; FLUSH PRIVILEGES;"`
2. `mkdir -p ~/podium-projects/limesurvey`
2. Write `docker-compose.yaml` and `nginx.conf` (see below).
3. `cd ~/podium-projects/limesurvey && podium setup limesurvey --no-startup`
4. `podium up limesurvey`
5. Verify: `curl -sI http://limesurvey/` — expect HTTP 200 or 302.

## docker-compose.yaml

```yaml
services:
  limesurvey-app:
    image: martialblog/limesurvey:latest
    restart: unless-stopped
    environment:
      DB_TYPE: mysql
      DB_HOST: podium-mariadb
      DB_PORT: 3306
      DB_NAME: limesurvey
      DB_USERNAME: limesurvey
      DB_PASSWORD: "limesurvey"
      ADMIN_USER: admin
      ADMIN_NAME: Administrator
      ADMIN_EMAIL: admin@example.com
      ADMIN_PASSWORD: admin123
      PUBLIC_URL: http://limesurvey
    volumes:
      - limesurvey-upload:/var/www/html/upload
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: limesurvey
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - limesurvey-app

volumes:
  limesurvey-upload:

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
        proxy_pass http://limesurvey-app:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Admin

- URL: `http://limesurvey/`
- Credentials: `admin` / `admin123`
