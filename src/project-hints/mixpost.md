# Mixpost Lite

**Image**: `inovector/mixpost:v2.6.0`
**Port**: 80 (Apache inside the container — no proxy needed)
**Database**: MariaDB (`podium-mariadb`), dedicated user `mixpost` / `mixpost`, plus shared `podium-redis`
**Credentials**: admin@example.com / changeme (built-in default — change it immediately)

## Key Notes
- `DB_HOST` and `REDIS_HOST` **must be set explicitly.** The upstream sample `.env` omits them because the image defaults to the literal service names `mysql` and `redis`, which do not exist here.
- `APP_KEY` is a standard Laravel key and must be the literal string `base64:` followed by base64 of 32 random bytes — a bare hex string will not decrypt.
- Mixpost is MySQL/MariaDB only; it does not support PostgreSQL.
- No separate worker, scheduler, or queue container: the image supervises them internally. Adding one would double-process the queue.
- `APP_DOMAIN` and `SSL_EMAIL` from the upstream docs only matter for their Traefik/SSL compose variants and are deliberately omitted here.
- The installer exists: run `podium install mixpost`.
