# Directus

**Image**: `directus/directus:latest`
**Port**: 8055 (via nginx proxy with WebSocket support)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password) + Redis (`podium-redis`)
**Credentials**: `admin@example.com / admin123` (set via `ADMIN_EMAIL` / `ADMIN_PASSWORD`)

## Key Notes
- `DB_CLIENT: pg` (PostgreSQL) — use `pg`, not `postgres` or `postgresql`.
- `KEY` and `SECRET` are required — generate with `openssl rand -hex 16` and `openssl rand -hex 32`.
- Redis for caching: `CACHE_ENABLED: "true"`, `CACHE_STORE: redis`, `REDIS: redis://podium-redis:6379`.
- `WEBSOCKETS_ENABLED: "true"` — nginx must include WebSocket upgrade headers.
- `PUBLIC_URL: http://directus` must match the Podium hostname exactly.
- Create DB first: `docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE directus;"`
- Persist `directus-uploads` and `directus-extensions` volumes.
- nginx proxy_read_timeout should be high (86400s) for long-running WebSocket connections.
- The installer exists: run `podium install directus`.
