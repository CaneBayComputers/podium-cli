# Unleash

Open-source feature-flag / toggle service with SDKs for most languages.

**Image**: `unleashorg/unleash-server:8.1.0`
**Port**: 4242 (via nginx proxy)
**Database**: PostgreSQL (`zeltro-postgres`, db `unleash`)
**Credentials**: `admin` / `unleash4all` (seeded on first boot)

## Key Notes
- `DATABASE_SSL=false` is mandatory — the server tries TLS to Postgres by default and `zeltro-postgres` serves plaintext only.
- Unleash runs its own migrations at startup; the database just has to exist, which `pre_install` handles.
- `INIT_FRONTEND_API_TOKENS` / `INIT_BACKEND_API_TOKENS` seed ready-made dev tokens so SDKs can connect immediately. They are intentionally insecure and fine for a local Zeltro project only.
- SDK clients inside the Zeltro network should point at `http://unleash/api/`.
- The installer exists: run `zeltro install unleash`.
