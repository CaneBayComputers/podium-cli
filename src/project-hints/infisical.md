# Infisical

Open-source secrets management platform.

**Image**: `infisical/infisical:v0.162.16`
**Port**: 8080 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password, db `infisical`) + Redis db 3
**Credentials**: register on first visit — the first account becomes the instance admin

## Key Notes
- `ENCRYPTION_KEY` must be exactly 32 hex chars (`openssl rand -hex 16`) and `AUTH_SECRET` a base64 32-byte value (`openssl rand -base64 32`). Changing `ENCRYPTION_KEY` later makes every stored secret unreadable.
- Both Postgres *and* Redis are required — Infisical will not boot without `REDIS_URL`.
- The standalone image runs `migration:latest` during startup, so the first boot takes noticeably longer and the proxy returns 502 until it is done.
- `SITE_URL` must match how you reach it (`http://infisical`) or invite/verification links and the OAuth callbacks point at the wrong host.
- The installer exists: run `podium install infisical`.
