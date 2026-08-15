# Gramps Web

**Image**: `ghcr.io/gramps-project/grampsweb:26.7.1`
**Port**: 5000 (via nginx proxy)
**Database**: Gramps' own SQLite/BSDDB tree in volumes + Redis (`podium-redis`, dbs 10/11) for Celery and rate limiting
**Credentials**: Create the owner account on first visit

## Key Notes
- Two containers share the same image and the same volume set: the web app and a `celery -A gramps_webapi.celery worker` companion (`gramps-web-celery`). Skipping the worker breaks imports, exports and media processing.
- Upstream bundles Valkey; here Celery points at the shared Redis instead: `GRAMPSWEB_CELERY_CONFIG__broker_url=redis://podium-redis:6379/10`, `..._result_backend` the same, `GRAMPSWEB_RATELIMIT_STORAGE_URI=redis://podium-redis:6379/11`.
- `GRAMPSWEB_TREE` names (and creates) the family tree on first boot.
- Eight named volumes are required — `/app/users`, `/app/indexdir`, `/app/thumbnail_cache`, `/app/cache`, `/app/secret`, `/root/.gramps/grampsdb`, `/app/media`, `/tmp`. `/app/secret` persists the Flask secret; losing it invalidates all sessions.
- Media uploads can be large; nginx allows 500M bodies.
- The installer exists: run `podium install gramps-web`.
