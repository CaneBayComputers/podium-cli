# Traccar

Open-source GPS tracking platform — fleet/asset dashboard with maps, geofences and reports.

**Image**: `traccar/traccar:6.14.5` (+ `nginx:1.29-alpine` proxy)
**Port**: 8082 inside the app container (via nginx proxy on 80)
**Database**: none — embedded H2 file database under `/opt/traccar/data`
**Credentials**: admin / admin

## Key Notes
- The web UI and REST API work **standalone on 8082 alone**. The 50+ device-protocol ports (5000-5150 TCP/UDP) only exist so real GPS hardware can phone in; they are deliberately not published here, so this install is dashboard-only.
- The image ships a working `traccar.xml` with H2, so it boots with **zero environment variables**. MySQL/Postgres only take effect if you also set `CONFIG_USE_ENVIRONMENT_VARIABLES=true` — setting `DATABASE_*` alone is silently ignored.
- Persist both `/opt/traccar/data` (the H2 database files) and `/opt/traccar/logs`.
- Tag variants exist (`-alpine`, `-debian`, `-ubuntu`); the plain numeric tag is the default build.
- Change the `admin` password immediately in Settings → Users; the default is well known.
- The installer exists: run `podium install traccar`.
