# PhotoPrism

**Image**: `photoprism/photoprism:latest`
**Port**: 2342 (via nginx proxy)
**Database**: MariaDB (`podium-mariadb`, user=root, password=empty)
**Credentials**: admin / admin1234

## Key Notes
- Env: `PHOTOPRISM_DATABASE_DRIVER=mysql`, `PHOTOPRISM_DATABASE_SERVER=podium-mariadb:3306`, `PHOTOPRISM_DATABASE_NAME=photoprism`, `PHOTOPRISM_DATABASE_USER=root`, `PHOTOPRISM_DATABASE_PASSWORD=` (empty).
- Set `PHOTOPRISM_AUTH_MODE=password`, `PHOTOPRISM_SITE_URL=http://photoprism/`.
- Create DB first: `docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS photoprism;"`
- Persist `/photoprism/originals` (your photos) and `/photoprism/storage` (index/cache).
- nginx `client_max_body_size` should be at least 500M for photo uploads.
- Initial indexing can take minutes — import photos by placing them in the originals volume.
- The installer exists: run `podium install photoprism`.
