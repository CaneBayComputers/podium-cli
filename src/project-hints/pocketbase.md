# PocketBase

Single-binary backend: SQLite database, REST API, auth, file storage, and an admin dashboard.

**Image**: `ghcr.io/muchobien/pocketbase:0.39.10`
**Port**: 8090 (via nginx proxy)
**Database**: None (its own SQLite in the `pocketbase-data` volume)
**Credentials**: admin@example.com / admin1234567890 — dashboard at `http://pocketbase/_/`

## Key Notes
- PocketBase ships no official image. This is the de-facto community build, which is what upstream's own docs link to.
- `PB_ADMIN_EMAIL` / `PB_ADMIN_PASSWORD` create the superuser on boot. Without them, PocketBase 0.23+ makes you fish an install token out of the log. The password must be at least 10 characters.
- `/` serves `pb_public`, which is empty on a fresh install, so nginx redirects the bare root to `/_/`. Drop that redirect once you put a real frontend in `pb_public`.
- The installer exists: run `podium install pocketbase`.
