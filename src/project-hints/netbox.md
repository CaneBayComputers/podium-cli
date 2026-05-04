# NetBox

**Image**: `netboxcommunity/netbox:latest`
**Port**: 8080 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password) + Redis (`podium-redis`)
**Credentials**: `admin / admin` (set via `SUPERUSER_NAME` / `SUPERUSER_PASSWORD`)

## Key Notes
- `SECRET_KEY` must be at least 50 characters — use `openssl rand -hex 32` (produces 64 hex chars, always safe). Do NOT use `openssl rand -base64 37 | tr -d "=+/"` which can produce fewer than 50 chars after stripping.
- Requires a `netbox-worker` sidecar running `manage.py rqworker` — without it, background jobs (webhooks, reports) silently fail.
- Redis is used for both the task queue and cache — configure `REDIS_*` and `REDIS_CACHE_*` separately with different `REDIS_DATABASE` values (e.g. 4 and 5).
- `SKIP_SUPERUSER: "false"` on the main container creates the admin; set `SKIP_SUPERUSER: "true"` on the worker to avoid duplicate creation.
- `CSRF_TRUSTED_ORIGINS: http://netbox` is required for POST requests behind the proxy.
- Create DB first: `docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE netbox;"`
- Persist `netbox-media`, `netbox-reports`, `netbox-scripts` volumes (share between app and worker).
- The installer exists: run `podium install netbox`.
