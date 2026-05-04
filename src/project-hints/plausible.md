# Plausible Analytics

**Image**: `ghcr.io/plausible/community-edition:v2`
**Port**: 8000 (nginx reverse proxy)
**Database**: PostgreSQL (`podium-postgres`) + Clickhouse sidecar (required)
**Credentials**: Create account on first visit

## Key Notes
- Requires a Clickhouse sidecar (`clickhouse/clickhouse-server:24.3.3.102-alpine`).
- Clickhouse needs two XML config files: `ipv4-only.xml` (sets listen_host=0.0.0.0) and `low-resources.xml` (memory limits).
- Plausible startup command must run migrations: `sh -c "/entrypoint.sh db createdb && /entrypoint.sh db migrate && /entrypoint.sh run"`.
- Uses a `.env` file. `SECRET_KEY_BASE` is a random 64-byte hex string.
- `CLICKHOUSE_DATABASE_URL` must point to the sidecar container name.
- The installer exists: run `podium install plausible`.
