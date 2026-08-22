# wger

**Image**: `wger/server:latest`
**Port**: 80 (no nginx proxy — direct port-80 service, with optional celery workers)
**Database**: PostgreSQL (`zeltro-postgres`) + Redis (`zeltro-redis`)
**Credentials**: admin / admin1234 (auto-created via env)

## Key Notes
- wger uses a config file (`config/prod.env`) not inline env vars.
- Has three services: `web`, `celery_worker`, `celery_beat` — all use the same image and env file.
- DB config: `DJANGO_DB_ENGINE=django.db.backends.postgresql`, `DJANGO_DB_HOST=zeltro-postgres`, `DJANGO_DB_DATABASE=wger`, `DJANGO_DB_USER=root`, `DJANGO_DB_PASSWORD=password`.
- Redis: `CELERY_BROKER=redis://zeltro-redis:6379/2`, `DJANGO_CACHE_LOCATION=redis://zeltro-redis:6379/1`.
- The `web` service name is picked correctly by Zeltro's adapter (matches the `^web` pattern).
- Set `SITE_URL=http://wger` and `WGER_PORT=80`.
- Auto-creates superuser via `DJANGO_SUPERUSER_*` env vars.
- Startup is slow (healthcheck `start_period: 300s`) — wait up to 5 minutes for first response.
- The installer exists: run `zeltro install wger`.
