# LiteLLM Proxy

OpenAI-compatible gateway in front of 100+ LLM providers, with keys, budgets, routing and spend tracking.

**Image**: `ghcr.io/berriai/litellm:v1.95.0` + `nginx:1.30.4-alpine`
**Port**: 4000 (behind the nginx reverse proxy on 80)
**Database**: PostgreSQL (`podium-postgres`, database `litellm`) + Redis (`podium-redis`, DB 7) for router caching
**Credentials**: `admin` / `admin123` — the admin UI is at `http://litellm/ui/`, not at `/`

## Key Notes
- No `config.yaml` is mounted on purpose. `STORE_MODEL_IN_DB=True` means models are added through the UI and persisted in Postgres, which survives reinstalls better than a file.
- The generated master key is saved to `litellm-master-key.txt` in the project directory. Clients point their OpenAI SDK at `http://litellm/v1` and use that key as `api_key`.
- `LITELLM_SALT_KEY` encrypts provider credentials stored in the database — changing it after models are added makes those keys unreadable.
- The entrypoint runs Prisma migrations against `DATABASE_URL` on every boot; first start takes ~30 s longer than later ones.
- `/` returns a small JSON health payload — that is normal; the dashboard lives under `/ui/`.
- The `-stable` tags on this image lag the release line by many versions; `v1.95.0` matches the current GitHub release.
- The installer exists: run `podium install litellm`.
