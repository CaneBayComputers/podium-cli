# Invoice Ninja

**Image**: `invoiceninja/invoiceninja:5`
**Port**: 9000 PHP-FPM (nginx uses fastcgi, NOT proxy_pass)
**Database**: MariaDB (`podium-mariadb`, user=root, password=empty, db=ninja)
**Credentials**: `admin@example.com / changeme!` (set via `IN_USER_EMAIL` / `IN_PASSWORD`)

## Key Notes
- The app image exposes PHP-FPM on port 9000 — nginx must use `fastcgi_pass invoice-ninja-app:9000`, not `proxy_pass`.
- nginx must share the `invoice-ninja-public` volume (`:ro`) to serve static files from `/var/www/app/public`.
- Generate APP_KEY: `base64:$(openssl rand -base64 32)`.
- `IS_DOCKER: "true"` and `NINJA_ENVIRONMENT: selfhost` are required.
- `REQUIRE_HTTPS: "false"` and `TRUSTED_PROXIES: "*"` are needed for local HTTP.
- Persist `invoice-ninja-public` and `invoice-ninja-storage` volumes.
- The installer exists: run `podium install invoice-ninja`.
