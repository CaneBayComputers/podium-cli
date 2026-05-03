# n8n

**Image**: `n8nio/n8n:latest`
**Port**: 5678 (via nginx proxy with WebSocket support)
**Database**: SQLite by default (file-based), PostgreSQL optional
**Credentials**: Create owner account on first visit

## Key Notes
- Env: `N8N_HOST=n8n`, `N8N_PORT=5678`, `N8N_PROTOCOL=http`, `WEBHOOK_URL=http://n8n/`.
- nginx must include WebSocket upgrade headers (n8n uses WebSockets for the editor).
- Persist `/home/node/.n8n` for workflows, credentials, and execution history.
- For production use, switch to PostgreSQL: set `DB_TYPE=postgresdb`, `DB_POSTGRESDB_HOST=podium-postgres`, etc.
- The installer exists: run `podium install n8n`.
