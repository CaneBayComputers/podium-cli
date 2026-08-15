# Grist

Spreadsheet with a real database underneath — Python formulas, typed columns, access rules.

**Image**: `gristlabs/grist-oss:1.7.17`
**Port**: 8484 (via nginx proxy)
**Database**: None (SQLite inside the `grist-data` volume)
**Credentials**: Signed in automatically as admin@example.com

## Key Notes
- `GRIST_IN_SERVICE=true` is the important one. Without it, a new install wedges on a `/boot` gate that demands a boot key printed only in the container log — a headless install never gets past it.
- Changing `GRIST_DEFAULT_EMAIL` after the first run revokes admin from the original user. Pick it once.
- `APP_HOME_URL` must be the URL you actually browse to; share links and auth callbacks are built from it.
- Anonymous access is the default posture. Set `GRIST_FORCE_LOGIN=true` to require a login.
- Everything durable lives in `/persist` — documents, the home DB, and sessions.
- The installer exists: run `podium install grist`.
