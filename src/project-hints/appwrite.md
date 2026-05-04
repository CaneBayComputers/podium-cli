# Appwrite

**Image**: `appwrite/appwrite:1.5.7`
**Port**: 80 (direct — Apache inside the container)
**Database**: MariaDB (`podium-mariadb`) + Redis (`podium-redis`)
**Credentials**: Create first admin on first visit

## Key Notes
- Single-container simplified deploy — background workers (audits, webhooks, functions, builds) are NOT included. Basic API and console work; background processing does not.
- `_APP_OPENSSL_KEY_V1` must be 32 hex chars (`openssl rand -hex 32`).
- Domain settings must all match the project name: `_APP_DOMAIN=appwrite`, `_APP_DOMAIN_TARGET=appwrite`.
- Set `_APP_OPTIONS_FORCE_HTTPS=disabled` for local HTTP.
- MariaDB database `appwrite` must be created before first start.
- The installer exists: run `podium install appwrite`.
