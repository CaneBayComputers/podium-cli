# Docmost

Collaborative wiki and documentation workspace with real-time editing.

**Image**: `docmost/docmost:0.95.0`
**Port**: 3000 (via nginx proxy)
**Database**: PostgreSQL `docmost` on podium-postgres, plus podium-redis
**Credentials**: Create the workspace owner on first visit

## Key Notes
- Both Postgres and Redis are required — Redis backs the collaborative editing session state, not just caching.
- `APP_URL` must match the URL you browse to or invite links and websocket upgrades break.
- `APP_SECRET` encrypts stored tokens; changing it invalidates them.
- The nginx proxy forwards `Upgrade`/`Connection`, which real-time editing depends on.
- Attachments live in the `docmost-data` volume at `/app/data/storage`.
- The installer exists: run `podium install docmost`.
