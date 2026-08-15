# Activepieces

Open-source no-code automation / workflow builder (a Zapier alternative).

**Image**: `activepieces/activepieces:0.86.3` (app + worker, same image)
**Port**: 80 — the app serves HTTP on 80 directly, no proxy needed
**Database**: PostgreSQL (`podium-postgres`, db `activepieces`) + Redis (`podium-redis`)
**Credentials**: Register on first visit; the first account becomes the platform admin

## Key Notes
- Upstream's compose ships `pgvector/pgvector:0.8.0-pg14`, but **the community edition does not need pgvector**. Verified: it boots and runs clean against Podium's vanilla PostgreSQL 17 (`Activepieces Edition: ce`). pgvector is only wanted for the optional `AP_TOOL_SEARCH_ENABLED` semantic search, which defaults to off.
- The app listens on **port 80 inside the container** (`Server listening at http://[::]:80`), so the service can be named `app` and no nginx proxy is needed.
- `AP_CONTAINER_TYPE` selects the role: `APP` for the web/API container, `WORKER` for the flow executors. Same image both times.
- `AP_ENCRYPTION_KEY` must be exactly **32 hex characters** (`openssl rand -hex 16`), not 64. A wrong-length key fails at boot.
- `AP_EXECUTION_MODE=UNSANDBOXED` is required — the sandboxed mode needs privileged Docker-in-Docker.
- Upstream sets `worker: deploy.replicas: 5`; one replica is plenty for local dev.
- The `cache` volume must be shared between app and worker — it holds downloaded piece packages.
- On first boot it fetches ~11k piece definitions from `cloud.activepieces.com`, so the builder needs outbound internet.
- The installer exists: run `podium install activepieces`.
