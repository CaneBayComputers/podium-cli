# Cal.com

**Image**: `calcom/cal.com:latest`
**Port**: 3000 (nginx reverse proxy)
**Database**: PostgreSQL (`podium-postgres`)
**Credentials**: Create account on first visit

## Key Notes
- `NEXTAUTH_URL` must include the auth path: `http://cal-com/api/auth` (not just `http://cal-com`).
- `CALENDSO_ENCRYPTION_KEY` must be exactly 32 chars (`openssl rand -hex 16`).
- Set `NEXT_PUBLIC_LICENSE_CONSENT=agree` and `LICENSE_CONSENT=agree` to accept the license non-interactively.
- `DATABASE_DIRECT_URL` should match `DATABASE_URL` for direct connection (no pooler).
- First startup takes ~60 seconds for Prisma migrations.
- The installer exists: run `podium install cal-com`.
