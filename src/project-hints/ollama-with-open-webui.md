# Ollama + Open WebUI

Local LLM runtime (Ollama) paired with the Open WebUI chat front-end, in one project.

**Image**: `ollama/ollama:0.32.5` + `ghcr.io/open-webui/open-webui:v0.11.0` + `nginx:1.30.4-alpine`
**Port**: 8080 on Open WebUI (behind the nginx reverse proxy on 80); Ollama's 11434 stays internal
**Database**: None — SQLite in `open-webui-data`; models live in `ollama-models`
**Credentials**: Create the admin account on first visit (first registered user becomes admin)

## Key Notes
- **CPU-only.** No `deploy.resources.devices` GPU reservation is declared, because Podium injects the network and a GPU request would fail on hosts without the NVIDIA runtime. Add one manually if you have a GPU.
- Nothing is preloaded. Pull a model before chatting from the WebUI's Models page, or with `docker compose exec ollama ollama pull llama3.2` from the project directory.
- Service names are `ollama`, `openwebui-app` and `nginx`. The front-end is deliberately **not** called `open-webui` so it cannot collide with Podium's entry-point name detection.
- The `ollama-models` volume grows fast — a couple of 7B models is ~10 GB.
- `OLLAMA_BASE_URL=http://ollama:11434` is the compose service name, not localhost; Open WebUI's default `127.0.0.1` would find nothing.
- `proxy_buffering off` plus a long `proxy_read_timeout` are needed so streamed tokens are not held back and slow CPU generations do not hit a 504.
- The installer exists: run `podium install ollama-with-open-webui`.
