# Checkmate

Uptime, infrastructure and page-speed monitoring with incident pages (formerly BlueWave Uptime).

**Image**: `ghcr.io/bluewave-labs/checkmate:3.10.0` (+ `nginx:1.29-alpine` proxy)
**Port**: 52345 inside the app container (via nginx proxy on 80)
**Database**: MongoDB (`podium-mongo`, db `checkmate`)
**Credentials**: Register on first visit

## Key Notes
- Current builds are a single **all-in-one** image. The older split images (`checkmate-client`, `checkmate-backend`, `checkmate-mongo`) and the pre-rename `bluewaveuptime/uptime_*` images are dead — several are no longer even pullable.
- Podium's MongoDB requires auth, so the connection string needs credentials **and** `authSource=admin`: `mongodb://root:password@podium-mongo:27017/checkmate?authSource=admin`. Omitting `authSource` fails with an auth error.
- Upstream's compose declares `JWT_SECRET=${JWT_SECRET:?set JWT_SECRET in your environment}` — with no value, `docker compose` itself refuses to start before the app is even reached. This installer bakes a generated secret into the compose file instead.
- `CLIENT_HOST` must equal the browsing origin (`http://checkmate`) or the SPA calls the wrong API host.
- The container also exposes 52346 internally for its `/livez` health check; do not proxy to it.
- The app is stateless — all state lives in MongoDB, so no volumes are needed.
- The installer exists: run `podium install checkmate`.
