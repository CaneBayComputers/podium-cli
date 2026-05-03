# Jellyfin

**Image**: `jellyfin/jellyfin:latest`
**Port**: 8096 (via nginx proxy)
**Database**: None (SQLite, file-based)
**Credentials**: Set on first visit (setup wizard)

## Key Notes
- Persist `/config` and `/cache` as named volumes.
- Mount a `/media` directory for your media library (optional at install time).
- First visit launches the setup wizard to create the admin account and add media libraries.
- curl HEAD check may return 302; a GET returns 200.
- The installer exists: run `podium install jellyfin`.
