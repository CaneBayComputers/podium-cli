# Odoo

**Image**: `odoo:19.0`
**Port**: 8069 (behind the `nginx` reverse proxy); 8072 for the websocket/longpolling worker
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password)
**Credentials**: Set during database creation on first visit

## Key Notes
- Odoo creates its own database from the built-in database manager, so there is no `pre_install`. This works because the shared `root` Postgres user is a superuser and therefore has `CREATEDB`.
- The DB settings are passed BOTH as env vars (`HOST`/`PORT`/`USER`/`PASSWORD`) and as `--db_*` command flags — the env vars alone are ignored once you override `command:`.
- `--proxy-mode` is required because Odoo sits behind nginx; without it Odoo builds redirect URLs from the wrong host.
- Live chat / real-time bus needs the separate `/websocket` location proxied to port 8072 — plain `/` on 8069 is not enough.
- `--without-demo=all` skips the sample data; drop it if you want a populated demo database.
- First database creation takes several minutes; the long `proxy_read_timeout` values exist for exactly that.
- The installer exists: run `podium install odoo`.
