# Leantime

**Image**: `leantime/leantime:latest`
**Port**: 8080 (via nginx proxy)
**Database**: MariaDB (`podium-mariadb`, user=root, password=empty)
**Credentials**: Set in setup wizard on first visit (no default admin)

## Key Notes
- Use `LEAN_` prefix for all env vars: `LEAN_DB_HOST`, `LEAN_DB_USER`, `LEAN_DB_PASSWORD`, `LEAN_DB_DATABASE`.
- `LEAN_DB_PASSWORD: ""` — the Podium MariaDB root user has no password.
- `LEAN_APP_URL: http://leantime` must match the Podium hostname.
- `LEAN_SESSION_PASSWORD` can be any random string (used to sign sessions).
- Create DB before start: `docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS leantime;"`
- Persist `leantime-userfiles`, `leantime-public-userfiles`, `leantime-plugins`, `leantime-logs` volumes.
- The installer exists: run `podium install leantime`.
