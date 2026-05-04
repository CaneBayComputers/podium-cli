# Open WebUI

**Image**: `ghcr.io/open-webui/open-webui:main`
**Port**: 8080 (nginx reverse proxy)
**Database**: None (SQLite internal)
**Credentials**: Create admin on first visit

## Key Notes
- Ollama integration disabled by default (`ENABLE_OLLAMA_API=false`). Enable and set `OLLAMA_BASE_URL` to connect to an Ollama instance.
- First startup takes ~15 seconds for initialization before the proxy returns 200.
- The installer exists: run `podium install open-webui`.
