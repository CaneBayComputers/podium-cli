# linkding (plus)

Minimal self-hosted bookmark manager — this is the **plus** build, which adds full-page HTML snapshot archiving.

**Image**: `sissbruecker/linkding:1.45.0-plus`
**Port**: 9090 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, db `linkding_plus`)
**Credentials**: `admin` / `admin123`

## Key Notes
- The `-plus` tag is the same app plus a bundled Chromium and `monolith`, used for local HTML snapshots. It is noticeably larger and hungrier than the plain image — that is the whole reason to choose it.
- `LD_SUPERUSER_NAME` alone creates a superuser **without a usable password**; `LD_SUPERUSER_PASSWORD` must be set too or the login form can never authenticate.
- Postgres mode needs the whole `LD_DB_*` set. `LD_DB_PASSWORD` has no default and is mandatory for anything other than SQLite.
- `LD_CSRF_TRUSTED_ORIGINS` must list the URL used in the browser, otherwise Django rejects the login POST with a CSRF failure.
- Snapshots and (in SQLite mode) the database live in `/etc/linkding/data` — keep that volume even on Postgres.
- The installer exists: run `podium install linkding-plus`.
