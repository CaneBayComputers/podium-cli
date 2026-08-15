# NocoBase

Low-code platform for building internal tools and admin panels on top of a real database schema.

**Image**: `nocobase/nocobase:2.1.36`
**Port**: 80 (the image runs its own nginx — no proxy needed)
**Database**: PostgreSQL, `nocobase` on podium-postgres
**Credentials**: admin@nocobase.com / admin123

## Key Notes
- The service is named `app` and serves port 80 directly. Do not add a reverse proxy.
- First boot installs and migrates the whole plugin set — allow several minutes before the UI answers. `INSTALL_READY_RETRIES=90` covers this.
- `APP_KEY` signs user tokens. Changing it invalidates every existing session.
- Uploads and plugin state live in the `nocobase-storage` volume at `/app/nocobase/storage`.
- NocoBase's own compose runs Postgres with `wal_level=logical`; the shared podium-postgres does not. Only the change-data-capture plugins need it, so the base install is unaffected.
- The installer exists: run `podium install nocobase`.
