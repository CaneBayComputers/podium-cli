# EspoCRM

**Image**: `espocrm/espocrm:10.0.3-apache`
**Port**: 80 (Apache inside the container — no proxy needed)
**Database**: MariaDB (`podium-mariadb`), dedicated user `espocrm` / `espocrm`
**Credentials**: admin / admin123

## Key Notes
- **An empty DB password silently breaks EspoCRM.** Its entrypoint tests `if [ "${VAR:-}" ]`, so an empty string counts as unset and falls back to the literal default `password` — which then fails to authenticate. Hence the dedicated user with a real password rather than the shared blank-password root.
- Use the `-apache` tag; the `-fpm` variants listen on 9000 and would need a separate nginx.
- The database must be created beforehand — EspoCRM's rebuild only populates an existing schema.
- **Do not mount `/var/www/html` wholesale.** That triggers a "LEGACY INSTALLATION METHOD DETECTED" warning and blocks future upgrades; mount the three sub-paths separately as this installer does.
- The `espocrm-daemon` sidecar is not needed to browse the UI, but without it scheduled jobs, workflows, reminders and inbound email never run. It shares the same volumes as the web container.
- `ESPOCRM_DATABASE_NAME` and `ESPOCRM_DATABASE_PORT` are real variables even though they are missing from the Docker Hub README.
- The installer exists: run `podium install espocrm`.
