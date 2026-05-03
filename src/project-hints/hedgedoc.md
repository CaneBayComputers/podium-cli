# HedgeDoc

**Image**: `quay.io/hedgedoc/hedgedoc:latest`
**Port**: 3000 (via nginx proxy with WebSocket support)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password)
**Credentials**: No default — register on first visit

## Key Notes
- DB connection via single URL: `CMD_DB_URL=postgres://root:password@podium-postgres:5432/hedgedoc`.
- Required: `CMD_DOMAIN=hedgedoc`, `CMD_URL_ADDPORT=false`, `CMD_PROTOCOL_USESSL=false`.
- Set `CMD_SESSION_SECRET` to a random string.
- nginx must include WebSocket upgrade headers (HedgeDoc uses Socket.IO).
- Allow anonymous access: `CMD_ALLOW_ANONYMOUS=true` (disable for private instances).
- Persist `/hedgedoc/public/uploads`.
- The installer exists: run `podium install hedgedoc`.
