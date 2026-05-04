# Healthchecks

**Image**: `healthchecks/healthchecks:latest`
**Port**: 8000 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password)
**Credentials**: `admin@example.com / admin123` (set via `SUPERUSER_EMAIL` / `SUPERUSER_PASSWORD`)

## Key Notes
- `DB: postgres` (not `postgresql`) — use the short form.
- `SECRET_KEY` — generate with `openssl rand -hex 32`.
- `ALLOWED_HOSTS: healthchecks,localhost,127.0.0.1` — must include the Podium hostname.
- `SITE_ROOT: http://healthchecks` — used in ping URLs shown to users.
- `REGISTRATION_OPEN: "False"` — prevents public signups in local dev.
- Email: `EMAIL_HOST: podium-mailhog`, `EMAIL_PORT: 1025`, `EMAIL_USE_TLS: "False"`.
- Create DB first: `docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE healthchecks;"`
- Persist `healthchecks-data` volume.
- The installer exists: run `podium install healthchecks`.
