# Linkwarden

**Image**: `ghcr.io/linkwarden/linkwarden:latest`
**Port**: 3000 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password)
**Credentials**: Register on first visit

## Key Notes
- `DATABASE_URL=postgresql://root:password@podium-postgres:5432/linkwarden`
- Required: `NEXTAUTH_SECRET` (random 32+ char string), `NEXTAUTH_URL=http://linkwarden/api/v1/auth`
- Set `NEXT_PUBLIC_DISABLE_REGISTRATION=false` to allow registration.
- Persist `/data/data` as a named volume.
- The installer exists: run `podium install linkwarden`.
