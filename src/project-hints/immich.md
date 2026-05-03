# Immich

**Image**: `ghcr.io/immich-app/immich-server:release`
**Port**: 2283 (via nginx proxy)
**Database**: Dedicated PostgreSQL container with pgvecto.rs (`tensorchord/pgvecto-rs:pg14-v0.2.0`) + Redis (`podium-redis`)
**Credentials**: First user to register becomes admin

## Key Notes
- Immich requires the `pgvecto.rs` extension for AI-powered search — use the dedicated image, NOT the shared `podium-postgres` which doesn't have this extension.
- Three services in compose: `immich-server`, `immich-db` (pgvecto-rs), `nginx`.
- The `immich-db` service will NOT be replaced by Podium's adapter (it's not named postgres/mysql/redis).
- DB env: `DB_HOSTNAME=immich-db`, `DB_USERNAME=postgres`, `DB_PASSWORD=postgres`, `DB_DATABASE_NAME=immich`.
- Redis: `REDIS_HOSTNAME=podium-redis` (uses shared Redis).
- Persist `/usr/src/app/upload` (server uploads) and `/var/lib/postgresql/data` (immich-db data).
- Allow 30+ seconds after `podium up` before the site responds — migrations run on startup.
- The installer exists: run `podium install immich`.
