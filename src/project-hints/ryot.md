# Ryot

"Roll Your Own Tracker" — one app for tracking movies, shows, books, games, podcasts, workouts and measurements.

**Image**: `ignisda/ryot:v10.4.2` (+ `nginx:1.29-alpine` proxy)
**Port**: 8000 inside the app container (via nginx proxy on 80)
**Database**: PostgreSQL (`podium-postgres`, db `ryot`) — PG 15+ required, no SQLite option
**Credentials**: Register on first visit; the first user becomes admin

## Key Notes
- Ryot tags releases as `vX.Y.Z` and also publishes rolling `vX` / `vX.Y` tags. Mirrored identically on Docker Hub (`ignisda/ryot`) and GHCR (`ghcr.io/ignisda/ryot`).
- `DATABASE_URL` and `SERVER_ADMIN_ACCESS_TOKEN` are both marked REQUIRED upstream; the app will not start without them.
- `SERVER_BACKEND_PORT` can move the listener, but proxying to 8000 is the tested path.
- `FRONTEND_URL` is used to build links in notifications and integration callbacks — set it to `http://ryot`.
- Ryot is stateless apart from Postgres; media metadata is fetched live from TMDB / IGDB / Open Library, so it needs outbound internet. Provider API keys are optional — missing ones just disable that source.
- The installer exists: run `podium install ryot`.
