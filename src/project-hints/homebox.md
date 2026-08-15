# Homebox

Home and small-office inventory manager — track items, locations, labels, warranties and attachments.

**Image**: `ghcr.io/sysadminsmedia/homebox:0.21.0` (+ `nginx:1.29-alpine` proxy)
**Port**: 7745 inside the app container (via nginx proxy on 80)
**Database**: none — embedded SQLite under `/data`
**Credentials**: Register on first visit

## Key Notes
- The maintained image is `sysadminsmedia/homebox`; the original `hay-kot/homebox` is abandoned. Do not use the old one.
- `HBOX_AUTH_API_KEY_PEPPER` is **mandatory** — the binary refuses to start without it, and rotating it invalidates every issued API key. Generate once with `openssl rand -hex 32`.
- `HBOX_WEB_PORT` exists but upstream explicitly says not to change it under Docker; proxy to 7745 instead.
- Tag variants: plain, `-rootless` (needs `chown 65532:65532` on the data dir) and `-hardened` (distroless, no shell, no MQTT client). The plain tag is the right default.
- `/data` holds both the SQLite database and uploaded attachments — persist it or you lose everything.
- Postgres is supported via `HBOX_DATABASE_DRIVER=postgres`, but `HBOX_DATABASE_SSL_MODE` defaults to `require` and must be set to `disable` for a local instance. SQLite is simpler and is what this installer uses.
- The installer exists: run `podium install homebox`.
