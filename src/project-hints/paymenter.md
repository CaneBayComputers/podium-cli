# Paymenter

Free, open-source billing/webshop panel aimed at hosting providers (clients, products, invoices, payment gateways).

**Image**: `ghcr.io/paymenter/paymenter:v1.5.7` (nginx + php-fpm inside, listening on port 80)
**Port**: 80
**Database**: MariaDB (`podium-mariadb`, db `paymenter`) + Redis (`podium-redis`) for cache/queue
**Credentials**: none by default — create one with `docker exec -it paymenter php artisan app:user:create`

## Key Notes
- The entrypoint runs `php artisan migrate --seed --force` itself, so no manual migration step is needed — but it does **not** create a user. Without the artisan command above there is no way to log in.
- `/app/var` must be a volume: the entrypoint writes the generated `APP_KEY` there and symlinks it to `/app/.env`. Lose that volume and every encrypted value (gateway API keys) becomes unreadable.
- Leave `APP_KEY` unset — the entrypoint generates a valid 32-char key on first boot. Supplying a wrong-length key breaks Laravel's cipher.
- Don't set `REDIS_PASSWORD`; `podium-redis` is unauthenticated and Laravel's default of `null` is correct.
- `DB_USERNAME=root` with an empty `DB_PASSWORD` is how Podium's MariaDB is configured; the value must be present but empty.
- Behind Podium's nginx-free setup the app is reached directly, but if you later front it with a proxy, set trusted proxies under Admin → Settings → Security or uploads will fail.
- The installer exists: run `podium install paymenter`.
