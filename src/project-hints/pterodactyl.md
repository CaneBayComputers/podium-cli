# Pterodactyl Panel

Game-server management panel. This installs the **panel** (the web app) only.

**Image**: `ghcr.io/pterodactyl/panel:v1.15.0` (nginx + php-fpm inside, listening on port 80)
**Port**: 80
**Database**: MariaDB (`podium-mariadb`, db `pterodactyl`) + Redis (`podium-redis`) for cache/session/queue
**Credentials**: none by default — `docker exec -it pterodactyl php artisan p:user:make` (answer yes to "administrator")

## Key Notes
- The entrypoint runs `php artisan migrate --seed --force` on every boot, so first start takes a while; it does **not** create a user.
- Do **not** set `LE_EMAIL`. When it is present the entrypoint switches to the SSL nginx config and runs certbot in standalone mode, which fails without a public domain and leaves the container without a listener on port 80.
- `/app/var` holds the generated `APP_KEY` and `HASHIDS_SALT` — keep it on a volume or every session and encrypted value is invalidated on restart. Leave both env vars unset and let the entrypoint generate them.
- `APP_ENVIRONMENT_ONLY=false` makes Laravel read config from the environment rather than expecting a full `.env`.
- Actually running game servers needs **Wings** on a host with Docker socket access, its own ports, and a real node registration — out of scope for a Podium project. The panel alone is fully usable for browsing/administration.
- The installer exists: run `podium install pterodactyl`.
