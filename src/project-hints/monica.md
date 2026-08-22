# Monica

**Image**: `monica:latest`
**Port**: 80 (no nginx proxy — direct port-80 service)
**Database**: MariaDB (`zeltro-mariadb`, user=root, password=empty) + Redis (`zeltro-redis`)
**Credentials**: Register on first visit (no default account)

## Key Notes
- Single-service compose — Zeltro assigns the VPC IP directly to the monica container.
- Requires `APP_KEY` (Laravel key). Generate with: `docker run --rm monica php artisan key:generate --show`
  or use `base64:$(openssl rand -base64 32)`.
- Env: `APP_ENV=production`, `APP_URL=http://monica`, `DB_HOST=zeltro-mariadb`, `DB_DATABASE=monica`, `DB_USERNAME=root`, `DB_PASSWORD=` (empty).
- Cache/session/queue: `CACHE_DRIVER=redis`, `SESSION_DRIVER=redis`, `QUEUE_CONNECTION=redis`, `REDIS_HOST=zeltro-redis`.
- Migrations run automatically on startup.
- The installer exists: run `zeltro install monica`.
