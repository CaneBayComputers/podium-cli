# Baby Buddy

**Image**: `lscr.io/linuxserver/babybuddy:latest`
**Port**: 8000 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password)
**Credentials**: `admin / admin` (default linuxserver image credentials)

## Key Notes
- Uses the LinuxServer image — set `PUID: 1000` and `PGID: 1000` for file permission compatibility.
- `SECRET_KEY` — generate with `openssl rand -hex 32`.
- `DB_ENGINE: django.db.backends.postgresql` (full Django engine path, not just `postgresql`).
- `CSRF_TRUSTED_ORIGINS: http://babybuddy` is required for form submissions through the proxy.
- `ALLOWED_HOSTS: babybuddy,localhost,127.0.0.1` — must include the Podium hostname.
- Email: `EMAIL_HOST: podium-mailhog`, `EMAIL_PORT: 1025`.
- Create DB first: `docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE babybuddy;"`
- Persist `babybuddy-config` volume at `/config`.
- The installer exists: run `podium install babybuddy`.
