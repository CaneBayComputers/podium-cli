# ArchiveBox

**Image**: `archivebox/archivebox:latest`
**Port**: 8000 (via nginx proxy)
**Database**: SQLite (embedded, stored in `/data`)
**Credentials**: Create superuser with: `docker exec -it archivebox-app archivebox manage createsuperuser`

## Key Notes
- The container `command` must be `server --quick-init 0.0.0.0:8000` — without `--quick-init`, the container waits for interactive confirmation.
- `ALLOWED_HOSTS: "*"` is needed to accept requests from the nginx proxy.
- `MEDIA_MAX_SIZE: 750m` controls maximum download size per URL.
- nginx `client_max_body_size 750M` and long `proxy_read_timeout`/`proxy_send_timeout` (300s) are recommended for archiving large pages.
- Persist `archivebox-data` volume at `/data`.
- The installer exists: run `podium install archivebox`.
