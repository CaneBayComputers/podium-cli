# Coolify

**Image**: `ghcr.io/coollabsio/coolify:latest`
**Port**: 8080 (nginx reverse proxy — internal PHP-FPM+nginx listens on 8080)
**Database**: PostgreSQL (`podium-postgres`) + Redis (`podium-redis`)
**Credentials**: Create first admin on first visit

## Key Notes
- The container's internal nginx listens on port 8080 (not 8000 despite APP_PORT=8000).
- Requires Docker socket: `/var/run/docker.sock:/var/run/docker.sock` — Coolify manages containers directly.
- `APP_KEY` must be `base64:<openssl rand -base64 32>`.
- Pusher keys (`PUSHER_APP_ID`, `PUSHER_APP_KEY`, `PUSHER_APP_SECRET`) are required random values for Soketi WebSockets.
- `AUTOUPDATE=false` prevents Coolify from updating itself inside the container.
- The installer exists: run `podium install coolify`.
