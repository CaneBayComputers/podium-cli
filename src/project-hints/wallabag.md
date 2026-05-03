# Wallabag

Wallabag is a self-hosted read-it-later application distributed as `wallabag/wallabag:latest`. It serves on port **80** — no nginx proxy needed.

Use the shared MariaDB: host `podium-mariadb`, port `3306`, user `root`, password `` (empty).

## Setup workflow

1. `mkdir -p ~/podium-projects/wallabag`
2. Write `docker-compose.yaml` (see below).
3. `cd ~/podium-projects/wallabag && podium setup wallabag --no-startup`
4. `podium up wallabag`
5. First run installs/migrates — wait ~30 seconds.
6. Verify: `curl -sI http://wallabag/` — expect HTTP 200 or 302.

## docker-compose.yaml

```yaml
services:
  wallabag:
    image: wallabag/wallabag:latest
    container_name: wallabag
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ""
      SYMFONY__ENV__DATABASE_DRIVER: pdo_mysql
      SYMFONY__ENV__DATABASE_HOST: podium-mariadb
      SYMFONY__ENV__DATABASE_PORT: 3306
      SYMFONY__ENV__DATABASE_NAME: wallabag
      SYMFONY__ENV__DATABASE_USER: root
      SYMFONY__ENV__DATABASE_PASSWORD: ""
      SYMFONY__ENV__DOMAIN_NAME: http://wallabag
      SYMFONY__ENV__SERVER_NAME: "Wallabag"
      SYMFONY__ENV__FOSUSER_REGISTRATION: "true"
      POPULATE_DATABASE: "true"
    volumes:
      - wallabag-images:/var/www/wallabag/web/assets/images
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>

volumes:
  wallabag-images:

networks:
  default:
    external: true
    name: podium-cli_vpc
```

## Admin

- URL: `http://wallabag/`
- Default credentials: `wallabag` / `wallabag`
