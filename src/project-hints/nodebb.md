# NodeBB

Modern Node.js forum software.

**Image**: `ghcr.io/nodebb/nodebb:4.9.0`
**Port**: 4567 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password, db `nodebb`)
**Credentials**: `admin` / `admin123456`

## Key Notes
- **Use PostgreSQL, not `podium-mongo`.** NodeBB builds its Mongo URI without `authSource`, so it authenticates against the `nodebb` database instead of `admin` and the shared root user always fails auth. Postgres needs no extensions — NodeBB creates its own `legacy_*` tables.
- Unattended setup uses the discrete `NODEBB_*` vars (`NODEBB_DB`, `NODEBB_DB_HOST/PORT/NAME/USER/PASSWORD`, `NODEBB_ADMIN_USERNAME/PASSWORD/EMAIL`, `NODEBB_URL`). **Do not use the `SETUP` JSON var** — the entrypoint then execs `nodebb setup` and exits every time, which turns `restart: unless-stopped` into a restart loop.
- Expected first-boot behavior: the container runs `nodebb install`, writes `/opt/config/config.json`, and **exits**; the restart policy starts it again and it serves the forum. One restart is normal, not a failure.
- The entrypoint runs `npm install` on every start, so boots are slow and `/opt/config`, `/usr/src/app/build` and `/usr/src/app/public/uploads` must be writable volumes.
- `NODEBB_URL` must match the browser URL exactly (`http://nodebb`, no trailing slash) or assets/sockets break.
- The installer exists: run `podium install nodebb`.
