# Langfuse

Open-source LLM observability: traces, evals, prompt management and cost tracking for AI apps.

**Image**: `langfuse/langfuse:4.4.0` (web) + `langfuse/langfuse-worker:4.4.0` + `clickhouse/clickhouse-server:25.12` + `minio/minio:RELEASE.2025-09-07T16-13-09Z` + `nginx:1.30.4-alpine`
**Port**: 3000 on the web container (behind the nginx reverse proxy on 80)
**Database**: PostgreSQL (`podium-postgres`, database `langfuse`) + Redis (`podium-redis`, DB 6); ClickHouse and MinIO run as sidecars
**Credentials**: `admin@example.com` / `admin123` (seeded via the `LANGFUSE_INIT_*` vars)

## Key Notes
- Langfuse v3+ is **not** a single container. ClickHouse (analytics) and S3-compatible object storage (event/media blobs) are hard requirements, so they ship as sidecars — Podium's shared MinIO is an opt-in profile service and cannot be relied on.
- Config lives in `.env`, shared by the web and worker containers via `env_file`. Keep them on identical values; a mismatched `ENCRYPTION_KEY` or `SALT` silently breaks decryption.
- Redis is wired with `REDIS_CONNECTION_STRING` rather than `REDIS_HOST`/`REDIS_AUTH` because `podium-redis` has no password. DB 6 keeps BullMQ queues out of other projects' keyspace.
- `podium-redis` runs `maxmemory-policy noeviction`, which is what BullMQ requires — do not change it.
- The `LANGFUSE_INIT_*` block only seeds on a genuinely empty database. Wipe the `langfuse` Postgres DB if you need to re-seed.
- Browser-side media uploads point at the internal `http://langfuse-minio:9000`, which the browser cannot reach — trace ingestion and the UI work, but attaching media from the UI does not.
- ClickHouse migrations run at first boot; allow 2-3 minutes before the proxy returns 200.
- The installer exists: run `podium install langfuse`.
