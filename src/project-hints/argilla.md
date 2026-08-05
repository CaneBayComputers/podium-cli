# Argilla

**Image**: `argilla/argilla-server:v2.8.0` (+ `elasticsearch:8.17.0`)
**Port**: 6900 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, database `argilla`) + Redis (`podium-redis`, db 12) + bundled Elasticsearch
**Credentials**: argilla / argilla12345, API key `argilla.apikey`

## Key Notes
- Three moving parts are all mandatory: the server, a second container of the same image running `python -m argilla_server worker`, and Elasticsearch (>= 8.5). Without the worker, dataset deletes/imports queue in Redis and never finish.
- Elasticsearch is bundled because Podium has no shared search engine. `discovery.type=single-node` skips the bootstrap checks, so **no host `vm.max_map_count` change is needed**; `node.store.allow_mmap=false` avoids the mmap ceiling that check would have caught.
- `ARGILLA_DATABASE_URL` uses the async driver: `postgresql+asyncpg://root:password@podium-postgres:5432/argilla`.
- `USERNAME`/`PASSWORD`/`API_KEY`/`WORKSPACE` bootstrap the owner account on first boot. Re-running is safe — the CLI prints "already exists in database. Skipping...", so restarts don't crash the `set -e` entrypoint.
- `ARGILLA_AUTH_SECRET_KEY` is not set by upstream's compose; without it every restart invalidates all sessions, so the installer generates one.
- Heavy: roughly 3 GB RAM across the four containers, and the first boot takes a couple of minutes — hence `INSTALL_READY_RETRIES=48`.
- The installer exists: run `podium install argilla`.
