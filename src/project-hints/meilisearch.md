# Meilisearch

**Image**: `getmeili/meilisearch:latest`
**Port**: 7700 (via nginx proxy)
**Database**: None (embedded; persists to `/meili_data`)
**Credentials**: Master key only (no user accounts — API key-based auth)

## Key Notes
- `MEILI_ENV: production` — required to enforce API key authentication (without it, the API is open).
- `MEILI_MASTER_KEY` — generate with `openssl rand -hex 32`; all API requests must include this key.
- The master key is printed during install — save it to use with client apps.
- nginx WebSocket upgrade headers and a high `proxy_read_timeout` (86400) are recommended for streaming search.
- Persist `meilisearch-data` at `/meili_data`.
- The installer exists: run `podium install meilisearch`.
