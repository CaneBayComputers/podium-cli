# ESPHome

**Image**: `ghcr.io/esphome/esphome:2026.7.3`
**Port**: 6052 (via nginx proxy)
**Database**: none — YAML configs live in the `esphome-config` volume
**Credentials**: admin / admin123

## Key Notes
- Since 2026.6.0 the image ships **ESPHome Device Builder**, not the old Python dashboard. Env vars are `ESPHOME_USERNAME` / `ESPHOME_PASSWORD` — the legacy bare `USERNAME`/`PASSWORD` and `ESPHOME_DASHBOARD_USE_PING` no longer do anything.
- Bridge networking (no `network_mode: host`) means no mDNS: device auto-discovery and `.local` resolution don't work, and devices without `use_address` or `manual_ip` show no status. Editing, compiling, logs and OTA-by-IP all work fine.
- WebSocket handshakes are rejected when `Origin` doesn't match the upstream `Host`, so nginx must send `Host $host` (the installer also sets `ESPHOME_TRUSTED_DOMAINS: esphome` as a belt-and-braces fallback) plus the usual upgrade headers and a long `proxy_read_timeout` — compile logs stream for minutes.
- Mount `/cache` as well as `/config`: PlatformIO/ESP-IDF toolchains are multiple GB and get re-downloaded on every restart otherwise.
- `/dev/ttyUSB*` and `privileged` are only needed for physical serial flashing, which this installer does not set up — use OTA.
- The installer exists: run `podium install esphome`.
