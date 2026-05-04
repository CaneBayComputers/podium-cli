# Typebot

**Image**: `baptistearno/typebot-builder:latest` + `baptistearno/typebot-viewer:latest`
**Port**: 3000/3001 → nginx (builder on /, viewer on /viewer/)
**Database**: PostgreSQL (`podium-postgres`)
**Credentials**: admin@typebot.local (set ADMIN_EMAIL)

## Key Notes
- Two services: builder (port 3000) and viewer (port 3001). nginx routes `/viewer/` to viewer, everything else to builder.
- Both services share the same `.env` file.
- `ENCRYPTION_SECRET` must be exactly 32 hex chars (`openssl rand -hex 16`).
- `NEXTAUTH_URL` points to the builder URL (http://typebot).
- `NEXT_PUBLIC_VIEWER_URL=http://typebot/viewer` (with trailing path, not a separate domain).
- `DISABLE_SIGNUP=false` for open registration; set to `true` to restrict.
- The installer exists: run `podium install typebot`.
