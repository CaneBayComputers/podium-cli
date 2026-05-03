# Paperless-ngx

**Image**: `ghcr.io/paperless-ngx/paperless-ngx:latest`
**Port**: 8000 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`) + Redis (`podium-redis`)
**Credentials**: admin / admin (auto-created on first start)

## Key Notes
- Env: `PAPERLESS_DBHOST=podium-postgres`, `PAPERLESS_DBPORT=5432`, `PAPERLESS_DBUSER=root`, `PAPERLESS_DBPASS=password`, `PAPERLESS_DBNAME=paperless`, `PAPERLESS_REDIS=redis://podium-redis:6379`.
- Set `PAPERLESS_SECRET_KEY` to a random 50-char string.
- Set `PAPERLESS_URL=http://paperless`.
- Persist four volumes: `/usr/src/paperless/data`, `/media`, `/export`, `/consume`.
- Default admin login is `admin` / `admin` unless overridden with `PAPERLESS_ADMIN_USER` / `PAPERLESS_ADMIN_PASSWORD`.
- The installer exists: run `podium install paperless`.
