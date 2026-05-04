# Kavita

**Image**: `jvmilazz0/kavita:latest`
**Port**: 5000 (via nginx proxy)
**Database**: SQLite (embedded)
**Credentials**: Set on first visit (create admin account)

## Key Notes
- No environment variables required — all config is done through the web UI.
- `client_max_body_size 512M` in nginx to allow large comic/manga/ebook uploads.
- WebSocket upgrade headers are needed in nginx for real-time UI updates.
- Persist `kavita-config` (at `/kavita/config`) and `kavita-books` (at `/books`) volumes.
- Upload books to the `kavita-books` volume, then scan libraries from the admin panel.
- The installer exists: run `podium install kavita`.
