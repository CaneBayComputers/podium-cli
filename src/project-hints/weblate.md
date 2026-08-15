# Weblate

Web-based continuous localization platform with tight Git integration.

**Image**: `weblate/weblate:2026.8.0.0` (behind `nginx:alpine`)
**Port**: 8080 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, db `weblate`, user=root, password=password) + `podium-redis` (db 1)
**Credentials**: admin / admin123

## Key Notes
- The app service is named **`translate-server`**, not `weblate-app`. Podium's web-service regex is `^(nginx|web|app|api|server|frontend|backend|http)` and *any* `weblate-*` name matches on `web`, which would give the project IP to the app container instead of nginx. Don't rename it back.
- Both `POSTGRES_DB` and `POSTGRES_DATABASE` are set — older Weblate containers read the latter, current ones the former.
- The image runs as UID 1000 and exposes 8080, so it can't take port 80 directly.
- First boot runs Django migrations and builds static files; expect several minutes of 502s from the proxy before it answers.
- Celery workers, the scheduler and the web server all run inside this one container — no separate worker service is needed.
- `WEBLATE_ADMIN_PASSWORD` applies only when the admin user is first created.
- The installer exists: run `podium install weblate`.
