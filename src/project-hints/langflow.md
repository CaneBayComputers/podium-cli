# Langflow

Visual low-code builder for LangChain-style agent and RAG flows, with an API for each published flow.

**Image**: `langflowai/langflow:1.11.2` + `nginx:1.30.4-alpine`
**Port**: 7860 (behind the nginx reverse proxy on 80)
**Database**: PostgreSQL (`podium-postgres`, database `langflow`)
**Credentials**: `admin` / `admin123`

## Key Notes
- `LANGFLOW_AUTO_LOGIN=false` is the image default, which makes `LANGFLOW_SUPERUSER` and `LANGFLOW_SUPERUSER_PASSWORD` mandatory — omit them and the login screen has no valid account.
- `LANGFLOW_CONFIG_DIR=/app/langflow` must stay on the mounted volume: it holds `secret_key`, uploaded files and profile pictures. The image pre-creates that directory as uid 1000 so the named volume inherits writable permissions — a bind mount would need a manual `chown 1000:0`.
- `LANGFLOW_SECRET_KEY` encrypts stored provider credentials; changing it invalidates every saved API key in existing flows.
- First boot indexes all bundled components and can take 1-2 minutes before the port answers.
- The installer exists: run `podium install langflow`.
