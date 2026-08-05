# PG Back Web

Web UI for scheduled PostgreSQL backups — cron schedules, local or S3 destinations, restore and download from the browser.

**Image**: `eduardolat/pgbackweb:0.5.1`
**Port**: 8085 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, db `pgbackweb`) for its own metadata
**Credentials**: the first visit asks you to create the initial user

## Key Notes
- `PBW_POSTGRES_CONN_STRING` is where PG Back Web stores **its own** state — it is not the database being backed up. Backup sources are added later in the UI.
- `?sslmode=disable` is required: `podium-postgres` does not serve TLS and the Go driver otherwise tries to negotiate it.
- `PBW_ENCRYPTION_KEY` encrypts stored connection strings and PGP settings. Changing it after the fact orphans every saved credential, so it is generated once at install.
- Backups land in `/backups` inside the container — that is the volume to keep. S3 destinations bypass it entirely.
- Downloading/restoring a dump streams through nginx, hence `client_max_body_size 0`, buffering off, and a long read timeout.
- The image supports pg_dump for PostgreSQL 13–18, so it can back up Podium's own `podium-postgres` (17).
- The installer exists: run `podium install pgbackweb`.
