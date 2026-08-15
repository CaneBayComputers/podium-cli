# LibreChat

Multi-provider AI chat UI (OpenAI, Anthropic, Google, Ollama, custom endpoints) with conversation history.

**Image**: `ghcr.io/danny-avila/librechat:v0.8.7` + `nginx:1.30.4-alpine`
**Port**: 3080 (behind the nginx reverse proxy on 80)
**Database**: MongoDB (`podium-mongo`, database `librechat`, `authSource=admin`)
**Credentials**: Register on first visit

## Key Notes
- `CREDS_KEY` (32 bytes hex) and `CREDS_IV` (16 bytes hex) must be exactly those lengths or the server aborts at boot — they encrypt user-supplied provider keys.
- Meilisearch is disabled (`SEARCH=false`); with it on, LibreChat blocks waiting for a Meili host that is not part of this stack.
- The RAG/file-upload sidecar (`rag_api` + pgvector) from the upstream compose is intentionally omitted, so "chat with files" is unavailable.
- Out of the box no model provider is configured — add `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or an Ollama base URL to the compose environment and restart before endpoints appear.
- The first registered user is an ordinary user; promotion to admin is done with the in-container `npm run ban-user`/user scripts.
- `proxy_buffering off` keeps token streaming smooth through nginx.
- The installer exists: run `podium install librechat`.
