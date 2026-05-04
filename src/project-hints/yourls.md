# YOURLS

**Image**: `ghcr.io/yourls/yourls:latest`
**Port**: 80 (direct — no nginx proxy, container_name is the VPC entry point)
**Database**: MariaDB (`podium-mariadb`, user=root, password=empty)
**Credentials**: admin / admin123

## Key Notes
- Requires custom Apache config files (`apache/ports.conf`, `apache/000-default.conf`) and an `index.php` redirect at root.
- Without the custom 000-default.conf, mod_rewrite rules are missing and short links won't resolve.
- `index.php` at document root redirects to `/admin/` for convenience.
- The installer exists: run `podium install yourls`.
