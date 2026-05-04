# Label Studio

**Image**: `heartexlabs/label-studio:latest`
**Port**: 8080 (via nginx proxy)
**Database**: SQLite only (DJANGO_DB=sqlite)
**Credentials**: Set on first visit (register first user)

## Key Notes
- `DJANGO_DB: sqlite` is required — setting it to `default` causes the app to try PostgreSQL on localhost and fail.
- `LOCAL_FILES_SERVING_ENABLED: "true"` allows accessing local files for annotation tasks.
- nginx should include WebSocket upgrade headers and a long `proxy_read_timeout` (86400s) for annotation sessions.
- `client_max_body_size 200M` to allow large media uploads.
- Persist `label-studio-data` volume at `/label-studio/data`.
- The installer exists: run `podium install label-studio`.
