# Budibase

**Image**: `budibase/budibase:latest`
**Port**: 80 (direct — bundles CouchDB, MinIO, and Redis internally)
**Database**: None external (CouchDB embedded)
**Credentials**: admin@example.com / Budibase123!

## Key Notes
- Truly all-in-one: bundles CouchDB, MinIO (object storage), and Redis inside the container.
- `JWT_SECRET` and `ENCRYPTION_KEY` must be set; generate with `openssl rand -hex 32`.
- `BB_ADMIN_USER_EMAIL` and `BB_ADMIN_USER_PASSWORD` create the first admin automatically.
- First startup takes ~20 seconds. Responds with HTTP 301 redirecting to the login page.
- The installer exists: run `podium install budibase`.
