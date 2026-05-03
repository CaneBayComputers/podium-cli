# Outline

**Image**: `outlinewiki/outline:latest`
**Port**: 3000 (via nginx proxy with WebSocket support)
**Database**: PostgreSQL (`podium-postgres`) + Redis (`podium-redis`)
**Credentials**: Configure an auth provider (Google/Slack/email) on first visit

## Key Notes
- Requires two secrets: `SECRET_KEY` and `UTILS_SECRET` (both random 64-char hex strings).
- Env: `DATABASE_URL=postgres://root:password@podium-postgres:5432/outline`, `REDIS_URL=redis://podium-redis:6379`.
- Set `URL=http://outline`, `PORT=3000`, `FORCE_HTTPS=false`, `PGSSLMODE=disable`.
- File storage: `FILE_STORAGE=local`, `STORAGE_LOCAL_PATH=/var/lib/outline/data`.
- **Outline requires an authentication provider** (Google OAuth, Slack, Microsoft, email/password) — configure via env vars before first use. Without auth, the site loads but login is not possible.
- nginx must include WebSocket upgrade headers.
- The installer exists: run `podium install outline`.
