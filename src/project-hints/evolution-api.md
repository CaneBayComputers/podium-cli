# Evolution API

**Image**: `evoapicloud/evolution-api:v2.3.7`
**Port**: 8080 (via nginx proxy) — REST API plus the `/manager` UI on the same port
**Database**: PostgreSQL (`podium-postgres`, database `evolution_api`, schema `evolution_api`) + Redis (`podium-redis`, db 8)
**Credentials**: API key `evolution123` — paste it into http://evolution-api/manager

## Key Notes
- The canonical image moved: `atendai/evolution-api` stopped at v2.2.3, current releases ship as `evoapicloud/evolution-api` (tags carry a `v` prefix).
- Prisma reads `DATABASE_CONNECTION_URI` directly; the `?schema=evolution_api` suffix is required and Prisma creates the schema. The entrypoint runs `prisma migrate deploy` and **exits 1 if it fails**, so a container that dies immediately means a DB problem — check `docker logs`.
- `CONFIG_SESSION_PHONE_VERSION` was a 2.2.x-only setting and must not be set on 2.3.x.
- `SERVER_URL` must be the externally visible URL (`http://evolution-api`) — it is used for QR pairing callbacks and by the manager UI.
- WhatsApp session state lives in the `evolution-instances` volume (`/evolution/instances`); deleting it forces re-pairing every instance.
- Redis is required for instance caching; `CACHE_REDIS_PREFIX_KEY=evolution` plus db 8 keeps it out of other projects' keyspace.
- The installer exists: run `podium install evolution-api`.
