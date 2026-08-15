# Chibisafe

Self-hosted file uploader and gallery with albums, tags and a browser extension.

**Image**: `chibisafe/chibisafe:v6.5.5` + `chibisafe/chibisafe-server:v6.5.5` (behind `nginx:alpine`)
**Port**: 8001 frontend / 8000 API (both via the nginx proxy on 80)
**Database**: None (SQLite under `/app/database`)
**Credentials**: admin / admin

## Key Notes
- Three services, and the proxy is **mandatory** — the frontend (8001) and the API (8000) are separate containers and neither serves the other's routes.
- The frontend service is named `chibisafe-frontend`, not `chibisafe`. A service named exactly `chibisafe` would collide with the `container_name: chibisafe` Podium puts on the entry point, giving one hostname two containers and randomly routed requests.
- nginx replaces upstream's Caddy and must reproduce its three rules: `/api/*` and `/docs*` to the server, everything else static-first out of `/app/uploads` then falling back to the frontend. That's why `chibisafe-uploads` is mounted read-only into nginx too — uploaded files are served directly by the proxy, not by the app.
- Default login is literally `admin`/`admin`. Change it on first login.
- Migrations are applied automatically on server start.
- The installer exists: run `podium install chibisafe`.
