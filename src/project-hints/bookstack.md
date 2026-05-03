# BookStack

Do **not** clone the BookStack source repo (`BookStackApp/BookStack`). It ships only a
dev Dockerfile that builds from source — slow, heavy, and fragile in Podium.

Use the **LinuxServer.io** pre-built image instead: `lscr.io/linuxserver/bookstack`.
It runs Apache on port 80 (no nginx proxy needed), uses MariaDB, and installs in seconds.

## Setup workflow

1. Create the database on Podium's shared MariaDB:
   ```
   podium mysql -e "CREATE DATABASE IF NOT EXISTS bookstack CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
   ```
2. Create `~/podium-projects/bookstack/` with the docker-compose below.
3. `cd ~/podium-projects/bookstack && podium setup bookstack --no-startup`
4. `podium up bookstack`
5. Verify with `curl -sI http://bookstack/` — expect a 302 redirect to `/login`.

## docker-compose.yaml

```yaml
services:
  bookstack:
    image: lscr.io/linuxserver/bookstack:latest
    container_name: bookstack
    restart: unless-stopped
    environment:
      PUID: 1000
      PGID: 1000
      APP_URL: http://bookstack
      DB_HOST: podium-mariadb
      DB_PORT: 3306
      DB_DATABASE: bookstack
      DB_USERNAME: root
      DB_PASSWORD: ""
    volumes:
      - bookstack-config:/config
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>

volumes:
  bookstack-config:

networks:
  default:
    external: true
    name: podium-cli_vpc
```

The container listens on port 80 internally; Podium assigns the static VPC IP directly
to the bookstack service (no nginx proxy needed).

## Admin

- Login URL: `http://bookstack/login`
- Default credentials: `admin@admin.com` / `password`
- Change the password immediately after first login.
