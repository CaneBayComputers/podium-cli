# Metabase

**Image**: `metabase/metabase:latest`
**Port**: 3000 (via nginx proxy)
**Database**: H2 embedded (file at `/metabase-data/metabase.db`) — no external DB needed
**Credentials**: Set in setup wizard on first visit

## Key Notes
- Uses H2 embedded database by default — no PostgreSQL/MariaDB setup required.
- `MB_DB_TYPE: h2` and `MB_DB_FILE: /metabase-data/metabase.db`.
- `JAVA_TIMEZONE: UTC` prevents timezone-related query issues.
- First startup takes ~60 seconds for JVM initialization — nginx `proxy_read_timeout 300s` prevents gateway timeouts.
- Persist `metabase-data` volume at `/metabase-data`.
- For production, switch to PostgreSQL: `MB_DB_TYPE=postgres`, `MB_DB_HOST=podium-postgres`, etc.
- The installer exists: run `podium install metabase`.
