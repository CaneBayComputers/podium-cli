# Nextcloud

**Image**: `nextcloud:latest`
**Port**: 80 (no nginx proxy — direct port-80 service)
**Database**: MariaDB (`podium-mariadb`, user=root, password=empty) + Redis (`podium-redis`)
**Credentials**: Set on first visit (admin account creation wizard)

## Key Notes
- Single-service compose — Podium assigns the VPC IP directly to the nextcloud container.
- Env: `MYSQL_HOST=podium-mariadb`, `MYSQL_DATABASE=nextcloud`, `MYSQL_USER=root`, `MYSQL_PASSWORD=` (empty).
- Add Redis: `REDIS_HOST=podium-redis`, `REDIS_HOST_PORT=6379`.
- Set `NEXTCLOUD_TRUSTED_DOMAINS=nextcloud` and `OVERWRITEHOST=nextcloud`, `OVERWRITEPROTOCOL=http`.
- First visit runs the installation wizard to set up the admin account.
- Persist `/var/www/html` as a named volume.
- The installer exists: run `podium install nextcloud`.
