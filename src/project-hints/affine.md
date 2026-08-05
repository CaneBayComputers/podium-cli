# AFFiNE

Local-first knowledge base blending docs, whiteboards and databases (a Notion/Miro hybrid).

**Image**: `ghcr.io/toeverything/affine:0.27.0` (migration + server) with an `nginx:1.29-alpine` proxy
**Port**: 3010 inside the server container (via nginx proxy on 80)
**Database**: PostgreSQL (`podium-postgres`, db `affine`) + Redis (`podium-redis`)
**Credentials**: Register on first visit — you land on `/admin/setup` to create the server owner

## Key Notes
- Upstream's compose ships `pgvector/pgvector:pg16`, but **pgvector is not required** with `AFFINE_INDEXER_ENABLED=false`. Verified: all 8 migrations and the server boot clean on Podium's vanilla PostgreSQL 17.
- GHCR publishes numeric tags (`0.26.x`, `0.27.x`) plus floating `stable`/`canary`. GitHub Releases mostly shows canary/beta entries, so read the *registry* tag list, not the releases page, to find a pinnable stable version.
- `affine-migration` is a one-shot: it runs `node ./scripts/self-host-predeploy.js` and exits. The server must wait on `service_completed_successfully` or it races the schema.
- Both containers need the same `/root/.affine/storage` and `/root/.affine/config` volumes.
- `REDIS_SERVER_HOST` defaults to `localhost` — it must be set explicitly or the server hangs.
- `AFFINE_SERVER_EXTERNAL_URL` must match the browsing URL (`http://affine`) or invite/share links point at the wrong origin.
- The proxy needs WebSocket upgrade headers — AFFiNE syncs documents over a socket.
- A "Copilot embedding client is not configured" warning at boot is normal without an AI provider key.
- The installer exists: run `podium install affine`.
