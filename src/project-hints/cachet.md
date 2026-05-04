# Cachet

**Image**: `cachethq/docker:latest`
**Port**: 8000 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password)
**Credentials**: Set in setup wizard on first visit

## Key Notes
- Generate APP_KEY: `base64:$(openssl rand -base64 32)`.
- `DB_DRIVER: pgsql` (not `DB_CONNECTION` as in Laravel — Cachet uses its own env var name).
- `CACHE_DRIVER: apc` and `SESSION_DRIVER: apc` — Cachet uses APC (APCu) by default; do not set these to `file` or `redis`.
- `TRUSTED_PROXIES: "*"` is needed for nginx proxy to work correctly.
- `MAIL_DRIVER: smtp` with `MAIL_HOST: podium-mailhog` and `MAIL_PORT: 1025` for local email.
- Create DB first: `docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE cachet;"`
- No volumes needed (all state lives in the database).
- The installer exists: run `podium install cachet`.
