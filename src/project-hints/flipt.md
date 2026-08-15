# Flipt

**Image**: `flipt/flipt:v2.11.0`
**Port**: 8080 (via nginx proxy) — UI and HTTP API; the gRPC port 9000 is not exposed
**Database**: none — Flipt v2 keeps flag state in a git repo it initializes inside `/var/opt/flipt`
**Credentials**: None; authentication is disabled by default

## Key Notes
- **The v2 default storage backend is `memory`** — every flag disappears on restart unless you set `FLIPT_STORAGE_DEFAULT_BACKEND_TYPE=local` *and* `FLIPT_STORAGE_DEFAULT_BACKEND_PATH`. Setting `local` without a path makes config validation fail outright.
- No external git remote is needed: with `local`, Flipt creates a bare git repo in that path on first boot. That directory is the only thing worth backing up.
- The container runs as uid 100 / gid 1000. A named volume at `/var/opt/flipt` inherits the image's `flipt:flipt` ownership and works; a bind mount would need `chown 100:1000` first.
- No license key is required — startup logs a `no license key provided` warning and the UI serves normally. Only Pro integrations need one.
- `FLIPT_META_TELEMETRY_ENABLED=false` and `FLIPT_META_CHECK_FOR_UPDATES=false` keep it from phoning home and from writing to a `$HOME` that does not exist in the image.
- The upstream repo's root `docker-compose.yml` is a dev file that builds from source — do not copy it.
- The installer exists: run `podium install flipt`.
