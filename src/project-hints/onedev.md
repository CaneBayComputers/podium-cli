# OneDev

Self-hosted Git server with built-in CI/CD and issue tracking.

**Image**: `1dev/server:16.4.1`
**Port**: 6610 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password, db `onedev`)
**Credentials**: `admin` / `admin123`

## Key Notes
- Database config uses lowercase `hibernate_*` env vars and OneDev's **own** dialect class: `hibernate_dialect=io.onedev.server.persistence.PostgreSQLDialect` (a stock Hibernate dialect will not work).
- Never omit the port in `hibernate_connection_url` — at startup OneDev opens a TCP socket to that host:port to discover its cluster IP and aborts with "Unable to discover cluster ip from database connection url" if it can't.
- `initial_user` / `initial_password` / `initial_email` / `initial_server_url` skip the web setup wizard entirely; they are read only when the database is empty. If any is invalid it silently falls back to the wizard.
- Git-over-SSH lives on 6611 and is not published by Podium — clone over HTTP. Set `ssh_port=0` to disable the listener.
- Persist `/opt/onedev` (repos, build artifacts, config). Migrations run in-process on every start.
- The installer exists: run `podium install onedev`.
