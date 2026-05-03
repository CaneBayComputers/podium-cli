# Lychee

Lychee is a self-hosted photo management system distributed as `lycheeorg/lychee:latest`. It serves on port **80** — no nginx proxy needed.

Use the shared MariaDB: host `podium-mariadb`, port `3306`, user `root`, password `` (empty).

## Setup workflow

1. `mkdir -p ~/podium-projects/lychee`
2. Write `docker-compose.yaml` (see below).
3. `cd ~/podium-projects/lychee && podium setup lychee --no-startup`
4. `podium up lychee`
5. Verify: `curl -sI http://lychee/` — expect HTTP 200 or 302.

## docker-compose.yaml

```yaml
services:
  lychee:
    image: lycheeorg/lychee:latest
    container_name: lychee
    restart: unless-stopped
    environment:
      DB_CONNECTION: mysql
      DB_HOST: podium-mariadb
      DB_PORT: 3306
      DB_DATABASE: lychee
      DB_USERNAME: root
      DB_PASSWORD: ""
      APP_URL: http://lychee
      TIMEZONE: UTC
    volumes:
      - lychee-uploads:/var/www/html/public/uploads
      - lychee-sym:/var/www/html/public/sym
      - lychee-dist:/var/www/html/dist
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>

volumes:
  lychee-uploads:
  lychee-sym:
  lychee-dist:

networks:
  default:
    external: true
    name: podium-cli_vpc
```

## Admin

- URL: `http://lychee/`
- Setup wizard on first visit — create admin account there.
