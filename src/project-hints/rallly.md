# Rallly

**Image**: `lukevella/rallly:4.12.1`
**Port**: 3000 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, database `rallly`)
**Credentials**: Register on first visit; `INITIAL_ADMIN_EMAIL=admin@example.com` claims the admin role

## Key Notes
- `SECRET_PASSWORD` must be at least 32 characters — generate with `openssl rand -hex 32`.
- `NEXT_PUBLIC_BASE_URL=http://rallly` is baked into `AUTH_URL` by the entrypoint; a mismatch breaks next-auth with an origin error.
- The entrypoint runs `prisma migrate deploy` on every start, so no manual migration step is needed.
- Sign-in is passwordless: Rallly emails a 6-digit code. SMTP points at `podium-mailhog:1025` (`SMTP_SECURE=false`, `SMTP_TLS_ENABLED=false`); the code also appears in `docker logs rallly-app`.
- Polls can be created and voted on without an account, so the app is usable even if you never read the mail.
- The installer exists: run `podium install rallly`.
