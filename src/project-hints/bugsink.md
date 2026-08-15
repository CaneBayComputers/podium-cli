# Bugsink

Self-hosted, Sentry-SDK-compatible error tracker built for small teams — single Django process, no Celery.

**Image**: `bugsink/bugsink:2.5.0` (+ `nginx:1.29-alpine` proxy)
**Port**: 8000 inside the app container (via nginx proxy on 80)
**Database**: PostgreSQL (`podium-postgres`, db `bugsink`)
**Credentials**: admin@example.com / admin123

## Key Notes
- `BASE_URL` must exactly equal the origin you browse to (`http://bugsink`). `ALLOWED_HOSTS` is derived from it, so **hitting the container by IP returns a bare 400** — that is correct behaviour, not a broken install. Always browse by hostname.
- `SECRET_KEY` must be a long random string; upstream samples prefix theirs with `django-insecure-`, which you should not copy.
- `CREATE_SUPERUSER` takes `email:password` and only runs on the first boot. Change the password afterwards.
- `BEHIND_HTTPS_PROXY: "false"` is required for plain HTTP, otherwise Django builds https:// URLs and the login loop never completes.
- Bugsink defaults to SQLite at `/data/db.sqlite3`; setting `DATABASE_URL` switches it to Postgres and no volume is then needed.
- Uses its own in-process "snappea" queue, so there is no separate worker container — one app container is the whole app.
- The installer exists: run `podium install bugsink`.
