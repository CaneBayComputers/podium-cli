# Alexandrie

**Image**: `ghcr.io/smaug6739/alexandrie-frontend:v8.11.0` + `ghcr.io/smaug6739/alexandrie-backend:v8.11.0`
**Port**: 8200 frontend / 8201 backend / 9000 RustFS — all fronted by one nginx on 80
**Database**: MariaDB (`podium-mariadb`, database `alexandrie`) + bundled RustFS for S3 object storage
**Credentials**: Register the first account on first visit

## Key Notes
- Upstream exposes three ports; here a single nginx multiplexes them by path:
  `/` -> `alexandrie-frontend:8200`, `/api/` -> `alexandrie-backend:8201/` (trailing slash strips the prefix), `/alexandrie/` -> `alexandrie-rustfs:9000/alexandrie/` (path-style S3 bucket).
- The Nuxt frontend builds URLs in the browser, so `NUXT_PUBLIC_BASE_API=http://alexandrie/api` and `NUXT_PUBLIC_BASE_CDN=http://alexandrie` with `NUXT_PUBLIC_CDN_ENDPOINT=/alexandrie/` must match those nginx locations exactly. Final media URL = `BASE_CDN` + `CDN_ENDPOINT` + object path.
- `COOKIE_DOMAIN` is intentionally left empty so auth cookies are host-only; setting a single-label domain gets them rejected by browsers.
- `ALLOW_UNSECURE=true` is required for plain HTTP — otherwise cookies are marked Secure and login silently fails.
- The backend creates the `alexandrie` and `alexandrie-backups` buckets in RustFS itself; the S3 keys just have to match between the backend and RustFS.
- Upstream uses MySQL 8, but the migrations are plain SQL with no MySQL-only collations, so MariaDB works.
- Object storage is optional in upstream (`MINIO_*` empty disables it) — keeping RustFS is what makes image/file uploads work.
- The installer exists: run `podium install alexandrie`.
