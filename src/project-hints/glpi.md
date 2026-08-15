# GLPI

**Image**: `glpi/glpi:11.0.8`
**Port**: 80 (Apache under supervisord — no proxy needed)
**Database**: MariaDB (`podium-mariadb`), dedicated user `glpi` / `glpi`
**Credentials**: glpi / glpi (also ships `tech`, `normal` and `post-only` demo accounts)

## Key Notes
- **All five `GLPI_DB_*` variables must be non-empty or headless install silently turns itself off** and you get the web wizard instead. An empty password counts as missing — that is why this uses a dedicated user rather than the shared blank-password root.
- GLPI creates its own schema (`CREATE DATABASE IF NOT EXISTS`), so pre-creating it is belt-and-braces; the grant on `glpi.*` is what actually makes that statement legal for this user.
- The extra `GRANT SELECT ON mysql.time_zone_name` is needed before timezone support can be enabled with `bin/console database:enable_timezones`; without it GLPI warns on the health page.
- `/var/glpi` is a single volume covering config, files, logs and marketplace on the 11.x line. (On 10.0.x you would additionally need `/var/www/glpi/marketplace`.)
- There are no admin-account env vars — the entrypoint prints the default credentials in its startup banner.
- The installer exists: run `podium install glpi`.
