# New API

OpenAI-compatible LLM relay and gateway (fork of one-api) with token quotas, channels and billing.

**Image**: `calciumion/new-api:v1.0.0-rc.23` + `nginx:1.30.4-alpine`
**Port**: 3000 (behind the nginx reverse proxy on 80)
**Database**: MariaDB (`podium-mariadb`, database `newapi`, user `newapi`/`newapi`) + Redis (`podium-redis`, DB 4)
**Credentials**: `root` / `123456` — upstream's fixed initial admin, change it on first login

## Key Notes
- `SQL_DSN` uses **Go MySQL DSN syntax**, not a URL: `user:pass@tcp(host:3306)/db`. A `mysql://` URL is silently rejected and the app falls back to SQLite.
- `pre_install()` creates a dedicated `newapi` MariaDB user; the shared root account's empty password does not round-trip cleanly through the Go DSN parser.
- `v1.0.0-rc.*` looks like a pre-release but upstream publishes these as full GitHub releases — it is the current stable line.
- Without `SESSION_SECRET` the app regenerates sessions on every restart, logging everyone out.
- `--log-dir /app/logs` in `command:` matches upstream; the `newapi-logs` volume keeps those out of the container layer.
- The installer exists: run `podium install newapi`.
