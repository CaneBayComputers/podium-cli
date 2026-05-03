# Snipe-IT

Snipe-IT is distributed as `snipe/snipe-it:latest`. It is an IT asset management system that serves on port **80** (no nginx proxy needed).

**Critical**: Snipe-IT requires a valid `APP_KEY` — a 32-character base64 Laravel application key. Generate one before starting the container:
```bash
docker run --rm snipe/snipe-it php artisan key:generate --show
```
Copy the output (looks like `base64:...`) and set it as the `APP_KEY` environment variable.

Use the shared MariaDB: host `podium-mariadb`, port `3306`, user `root`, password `` (empty).

## Setup workflow

1. Generate APP_KEY: `docker run --rm snipe/snipe-it php artisan key:generate --show`
2. `mkdir -p ~/podium-projects/snipe-it`
3. Write `docker-compose.yaml` (see below), substituting the generated APP_KEY.
4. `cd ~/podium-projects/snipe-it && podium setup snipe-it --no-startup`
5. `podium up snipe-it`
6. Wait ~60 seconds for first-run migrations to complete.
7. Verify: `curl -sI http://snipe-it/` — expect HTTP 200 or 302.

## docker-compose.yaml

```yaml
services:
  snipe-it:
    image: snipe/snipe-it:latest
    container_name: snipe-it
    restart: unless-stopped
    environment:
      APP_ENV: production
      APP_DEBUG: "false"
      APP_KEY: "base64:REPLACE_WITH_GENERATED_KEY"
      APP_URL: http://snipe-it
      DB_CONNECTION: mysql
      DB_HOST: podium-mariadb
      DB_PORT: 3306
      DB_DATABASE: snipeit
      DB_USERNAME: root
      DB_PASSWORD: ""
      MAIL_DRIVER: log
    volumes:
      - snipeit-data:/var/lib/snipeit
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>

volumes:
  snipeit-data:

networks:
  default:
    external: true
    name: podium-cli_vpc
```

Create the database before starting:
```bash
docker exec podium-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS snipeit;"
```

## Admin

- URL: `http://snipe-it/`
- Setup wizard appears on first visit — create admin account there.
