# Shlink

**Image**: `shlinkio/shlink:stable`
**Port**: 8080 (via nginx proxy)
**Database**: MariaDB (`podium-mariadb`, user=root, password=empty)
**Credentials**: API key only (no web UI — use Shlink Web Client or CLI)

## Key Notes
- `DB_DRIVER: maria` — use `maria`, not `mysql`. The `mysql` driver causes errors with this image.
- `SKIP_INITIAL_GEOLITE_DOWNLOAD: "true"` — skips downloading the GeoLite2 database on startup (avoids a slow first start requiring a MaxMind API key).
- `INITIAL_API_KEY` — generate with `openssl rand -hex 32`; printed during install for use with the Shlink Web Client.
- `DEFAULT_BASE_URL_REDIRECT` — set to a valid URL (e.g. `http://shlink/rest/v3/health`) so requests to `/` return 302 instead of 404, which makes health checks pass.
- `TRUSTED_PROXIES: 1` — required when behind an nginx proxy.
- `DEFAULT_DOMAIN: shlink` must match the Podium hostname.
- No volumes needed (DB stores everything).
- The installer exists: run `podium install shlink`.
