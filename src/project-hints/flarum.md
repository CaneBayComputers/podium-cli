# Flarum

**Image**: `mondedie/flarum:latest`
**Port**: 8888 (via nginx proxy)
**Database**: MariaDB — dedicated `flarum` user required (root login rejected by this image)
**Credentials**: `admin / AdminPassword123!` (set via `FLARUM_ADMIN_USER` / `FLARUM_ADMIN_PASS`)

## Key Notes
- The mondedie image rejects the root MariaDB user — create a dedicated user first:
  ```
  docker exec podium-mariadb mariadb -u root -e "
    CREATE DATABASE IF NOT EXISTS flarum CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS 'flarum'@'%' IDENTIFIED BY 'FlarumDbPassword123!';
    GRANT ALL PRIVILEGES ON flarum.* TO 'flarum'@'%';
    FLUSH PRIVILEGES;"
  ```
- `FORUM_URL: http://flarum` must match the Podium hostname exactly.
- `FLARUM_PORT: 8888` — nginx proxies to this port.
- `LOG_TO_STDOUT: "true"` keeps logs visible in docker logs.
- First startup takes a few minutes while Flarum installs extensions.
- Persist `flarum-assets`, `flarum-extensions`, `flarum-logs` volumes.
- The installer exists: run `podium install flarum`.
