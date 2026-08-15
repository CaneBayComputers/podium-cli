# LibreSpeed

Self-hosted HTML5 network speed test, no Flash/Java/websockets.

**Image**: `ghcr.io/librespeed/speedtest:6.2.0` (behind `nginx:alpine`)
**Port**: 8080 (via nginx proxy — the "port 80" in upstream docs is the *host* side of `80:8080`)
**Database**: None (telemetry disabled)
**Credentials**: none

## Key Notes
- The container listens on **8080**, not 80. Upstream's `docker run -p 80:8080` misleads people into thinking otherwise.
- The proxy sets `client_max_body_size 0` and `proxy_request_buffering off` — the upload test streams a large body and nginx would otherwise buffer it to disk and skew the result.
- `TELEMETRY: "false"` keeps it stateless. Turning telemetry on requires `DB_TYPE` plus `DB_HOSTNAME`/`DB_NAME`/`DB_USERNAME`/`DB_PASSWORD` pointed at `podium-postgres`, and the schema has to be created by hand first.
- Numbers reflect the Docker bridge, not your real WAN link.
- The installer exists: run `podium install librespeed`.
