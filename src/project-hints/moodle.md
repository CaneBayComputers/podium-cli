# Moodle

**Image**: `erseco/alpine-moodle:v5.2.1`
**Port**: 8080 (behind the `nginx` reverse proxy; nginx + PHP-FPM run non-root inside)
**Database**: MariaDB (`podium-mariadb`), dedicated user `moodle` / `moodle`
**Credentials**: admin / Admin123!

## Key Notes
- **The Bitnami Moodle image is dead** — `bitnami/moodle` now has zero tags (moved to paid Bitnami Secure Images in Aug 2025), and `bitnamilegacy/moodle` is frozen with no security patches. `erseco/alpine-moodle` is the maintained replacement.
- Because of that switch, the env vars are `DB_TYPE` / `DB_HOST` / `DB_NAME` / `DB_USER` / `DB_PASS` — **not** the `MOODLE_DATABASE_*` names Bitnami used. Only the admin vars keep the `MOODLE_` prefix.
- The admin password must satisfy Moodle's policy (8+ chars, upper, lower, digit, symbol); `Admin123!` is the minimum that passes. A weaker value makes the CLI install fail.
- The database must already exist — Moodle's CLI installer does not create it.
- First boot runs the full CLI install; expect several minutes of 502s. The long proxy timeouts are there for that and for course backup/restore.
- `SITE_URL` must match the browser URL or Moodle rejects requests with a wwwroot mismatch.
- The installer exists: run `podium install moodle`.
