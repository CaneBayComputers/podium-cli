# Tooljet

**Image**: `tooljet/tooljet-ce:latest`
**Port**: 3000 (nginx reverse proxy)
**Database**: PostgreSQL — requires TWO databases: `tooljet_production` (app) and `tooljet_db` (PostgREST)
**Credentials**: Create admin on first visit

## Key Notes
- Needs two PostgreSQL databases: `tooljet_production` and `tooljet_db`.
- PostgREST is bundled inside the image; configure via `PGRST_*` env vars.
- Uses a `.env` file (not inline compose env) due to the number of variables.
- `LOCKBOX_MASTER_KEY` (64 hex chars) and `SECRET_KEY_BASE` (128 hex chars) are required.
- Start command: `npm run start:prod`.
- Also uses podium-redis for background jobs.
- The installer exists: run `podium install tooljet`.
