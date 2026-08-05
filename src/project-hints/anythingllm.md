# AnythingLLM

All-in-one private RAG/chat workspace: ingest documents, pick any LLM provider, chat over your data.

**Image**: `mintplexlabs/anythingllm:1.15.0` + `nginx:1.30.4-alpine`
**Port**: 3001 (behind the nginx reverse proxy on 80)
**Database**: None externally — SQLite + LanceDB inside the `anythingllm-storage` volume
**Credentials**: Set up in the first-run wizard (single-user mode by default; multi-user adds an admin login)

## Key Notes
- `STORAGE_DIR=/app/server/storage` must be set **and** match the mounted volume or the app boots into a fresh, empty state on every restart.
- The container runs as the non-root `anythingllm` user; the named volume inherits that ownership from the image, so do not swap it for a bind mount without chowning to uid 1000.
- `cap_add: SYS_ADMIN` is what upstream's `docker run` uses — the collector's headless Chromium needs it for link scraping.
- Vector storage is LanceDB (embedded). No external vector DB service is required or wired in.
- Nothing works until a provider is chosen in the wizard; there is no bundled model.
- The installer exists: run `podium install anythingllm`.
