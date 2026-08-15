# ownCloud

Classic ownCloud Server (10.x) file sync and share.

**Image**: `owncloud/server:10.16.4`
**Port**: 8080 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password, db `owncloud`)
**Credentials**: `admin` / `admin123`

## Key Notes
- **Use `pgsql`, not MariaDB.** The `/usr/bin/owncloud` entrypoint only passes `--database-pass` when the password is non-empty, so `podium-mariadb`'s empty root password makes `occ maintenance:install` fall into an interactive prompt under `--no-interaction`. Postgres has a real password and sidesteps it.
- There is no enforced database-version gate in the 10.16 setup code, but the docs only certify PostgreSQL 9-14 / MariaDB 10.2-10.11. `OWNCLOUD_DB_PLATFORM` is the escape hatch if Doctrine misdetects the server.
- The install is fully unattended from `OWNCLOUD_ADMIN_USERNAME`/`OWNCLOUD_ADMIN_PASSWORD`; ownCloud will create the database itself if the user is privileged.
- `OWNCLOUD_TRUSTED_DOMAINS` must contain the hostname you browse to or you get "untrusted domain". Pair it with `OWNCLOUD_OVERWRITE_PROTOCOL=http` behind the proxy.
- Redis and Memcached are off by default (`OWNCLOUD_REDIS_ENABLED=false`) — APCu handles local caching; no shared cache needed.
- All data lives in `/mnt/data`.
- The installer exists: run `podium install owncloud`.
