# Joplin Server

Sync backend for the Joplin note-taking apps, with a light web UI.

**Image**: `joplin/server:3.7.1`
**Port**: 22300 (via nginx proxy)
**Database**: PostgreSQL `joplin` on podium-postgres
**Credentials**: admin@localhost / admin

## Key Notes
- The default admin password is literally `admin` — change it on first login.
- `APP_BASE_URL` must exactly match the hostname you reach it on. Joplin rejects any other Host with `Invalid origin` and answers **404 on every path**, including `/login` — it looks completely dead rather than misconfigured. The installer hardcodes `http://joplin`, so if you install under a different project name (`podium install joplin notes`) you must edit `APP_BASE_URL` to match or nothing will load.
- A healthy instance answers `/` with a 302 to `/login`.
- Postgres connection details are six separate `POSTGRES_*` variables, not a DSN.
- In the Joplin desktop/mobile app choose "Joplin Server" as the sync target and point it at `http://joplin/`.
- The installer exists: run `podium install joplin`.
