# Redash

**Image**: `redash/redash:latest`
**Port**: 5000 (server service, via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password) + Redis (`podium-redis`)
**Credentials**: Set on first visit (create admin account)

## Key Notes
- Requires three separate services all using the same image: `redash-server` (command: server), `redash-worker` (command: worker), `redash-scheduler` (command: scheduler).
- `REDASH_DATABASE_URL: postgresql://root:password@podium-postgres:5432/redash` — full connection URL format.
- `REDASH_REDIS_URL: redis://podium-redis:6379/3` — use a non-default Redis DB (e.g. /3) to avoid collision with other services.
- `REDASH_SECRET_KEY` and `REDASH_COOKIE_SECRET` — generate each with `openssl rand -hex 32`.
- The server depends on both worker and scheduler being up (`depends_on`).
- nginx proxies to `redash-server:5000`; include WebSocket upgrade headers.
- Create DB first: `docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE redash;"`
- No volumes needed (all state in PostgreSQL).
- The installer exists: run `podium install redash`.
