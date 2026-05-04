# FreeScout

**Image**: `tiredofit/freescout:latest`
**Port**: 80 (direct — no nginx proxy; the image includes its own web server)
**Database**: MariaDB — dedicated `freescout` user required (root login rejected by this image)
**Credentials**: `admin@freescout.local / freescout-admin` (set via `ADMIN_EMAIL` / `ADMIN_PASS`)

## Key Notes
- The tiredofit image rejects the root MariaDB user — create a dedicated user first:
  ```
  docker exec podium-mariadb mariadb -u root -e "
    CREATE DATABASE IF NOT EXISTS freescout CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS 'freescout'@'%' IDENTIFIED BY 'freescout';
    GRANT ALL PRIVILEGES ON freescout.* TO 'freescout'@'%';
    FLUSH PRIVILEGES;"
  ```
- No nginx sidecar needed — the tiredofit image bundles Apache/nginx internally.
- `SETUP_TYPE: AUTO` performs automatic installation on first start.
- `ENABLE_AUTO_UPDATE: "FALSE"` prevents unexpected updates in a local env.
- Set `SITE_URL: http://freescout` to match the Podium hostname.
- Persist `freescout-data` and `freescout-logs` volumes.
- The installer exists: run `podium install freescout`.
