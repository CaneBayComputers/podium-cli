# Dify

**Image**: `langgenius/dify-api:latest` (api + worker + beat) + `langgenius/dify-web:latest` + `langgenius/dify-sandbox:latest` + `semitechnologies/weaviate:1.27.0` + `nginx:alpine`
**Port**: 8080 (nginx reverse proxy)
**Database**: PostgreSQL (`podium-postgres`) + Redis (`podium-redis`) + Weaviate sidecar (vector store)
**Credentials**: Set on first visit (INIT_PASSWORD=DifyAdmin123 pre-sets the initial password)

## Key Notes
- 7-service setup: api (MODE=api), worker (MODE=worker), worker_beat (MODE=beat), web, dify-sandbox, weaviate, nginx.
- Uses `.env` file for configuration; key vars: `SECRET_KEY`, `DB_HOST=podium-postgres`, `REDIS_HOST=podium-redis`.
- `MIGRATION_ENABLED=true` causes the API to auto-run DB migrations on startup.
- nginx routes: `/console/api`, `/api`, `/v1`, `/files` → api:5001; `/` → web:3000.
- Weaviate is the vector store (`VECTOR_STORE=weaviate`, `WEAVIATE_ENDPOINT=http://weaviate:8080`).
- Sandbox (`dify-sandbox`) handles code execution; `ENABLE_NETWORK=false` skips SSRF proxy requirement.
- `CELERY_BROKER_URL=redis://podium-redis:6379/1` (uses Redis DB 1 for Celery).
- Storage is local filesystem; uploaded files stored in `dify-storage` volume.
- The installer exists: run `podium install dify`.
