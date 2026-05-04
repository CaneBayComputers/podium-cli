# Firefly III

**Image**: `fireflyiii/core:latest`
**Port**: 8080 (via nginx proxy)
**Database**: MariaDB (`podium-mariadb`, user=root, password=empty)
**Credentials**: Set on first visit (register first user as admin)

## Key Notes
- Generate APP_KEY: `base64:$(openssl rand -base64 32)` — must be set before first run.
- Set `TRUSTED_PROXIES: "**"` so requests through the nginx proxy are trusted.
- Create DB before start: `docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS firefly;"`
- `MYSQL_USE_SSL: "false"` is required; `CACHE_DRIVER: file` and `SESSION_DRIVER: file` avoid Redis dependency.
- `STATIC_CRON_TOKEN` can be any string — it authenticates the recurring-transaction cron URL.
- Persist `/var/www/html/storage/upload` for attachments.
- The installer exists: run `podium install firefly-iii`.
