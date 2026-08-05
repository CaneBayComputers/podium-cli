# LobeChat

Polished AI chat UI with plugin/agent marketplace, multi-provider model support.

**Image**: `lobehub/lobe-chat:1.143.3` + `nginx:1.30.4-alpine`
**Port**: 3210 (behind the nginx reverse proxy on 80)
**Database**: None — the "client database" edition stores conversations in the browser (IndexedDB)
**Credentials**: None; set `ACCESS_CODE` to require a shared password

## Key Notes
- Pinned to the **v1 client-DB edition on purpose.** LobeChat v2 ships as `lobehub/lobehub` and its server database requires a PostgreSQL built with `pgvector` **and** ParadeDB's `pg_search` preloaded (`shared_preload_libraries=pg_search`). `podium-postgres` is stock PostgreSQL 17, so v2 migrations fail — do not "upgrade" this installer to `lobehub/lobehub` without also bringing a ParadeDB instance.
- `1.143.3` is the last v1 tag published to Docker Hub (Jan 2026); newer v1 tags do not exist.
- Conversations are browser-local: a different browser or a cleared cache means an empty history, and there is no multi-user concept.
- Add provider keys as env vars (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `OLLAMA_PROXY_URL`, …) or enter them in Settings at runtime.
- `proxy_buffering off` is required or streamed responses arrive in one lump at the end.
- The installer exists: run `podium install lobe-chat`.
