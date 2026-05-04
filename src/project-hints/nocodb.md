# NocoDB

**Image**: `nocodb/nocodb:latest`
**Port**: 8080 (nginx reverse proxy)
**Database**: PostgreSQL (`podium-postgres`)
**Credentials**: Set on first visit

## Key Notes
- Connection string format: `NC_DB=pg://podium-postgres:5432?u=root&p=password&d=nocodb`
- `NC_AUTH_JWT_SECRET` is required; generate with `openssl rand -hex 32`.
- First user to register becomes the superadmin.
- The installer exists: run `podium install nocodb`.
