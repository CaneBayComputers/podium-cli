# ClassicPress

**Image**: `classicpress/classicpress:php8.4-apache`
**Port**: 80 (Apache — served directly, no proxy)
**Database**: MariaDB (`podium-mariadb`, database `classicpress`, user `root`, empty password)
**Credentials**: Created by you in the five-minute install on first visit

## Key Notes
- The image is a fork of the official `wordpress` image mechanics, but **every env var uses the `CLASSICPRESS_` prefix** — `WORDPRESS_DB_HOST` and friends are silently ignored, and the entrypoint only writes `wp-config.php` when at least one `CLASSICPRESS_*` var is present.
- Default table prefix is `cp_`, not `wp_`.
- Upstream publishes no version tags — only `latest` and PHP-variant tags — so the installer pins `php8.4-apache` (ClassicPress 2.7.0 as of 2026-06).
- `CLASSICPRESS_DB_HOST` needs the port: `podium-mariadb:3306`. The database must already exist (the installer creates it); the image will not create it.
- All eight auth keys/salts are generated at install time; changing them later logs everyone out.
- Site files (themes, plugins, uploads) persist in the `classicpress-data` volume at `/var/www/html`.
- The installer exists: run `podium install classicpress`.
