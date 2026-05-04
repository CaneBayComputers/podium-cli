# Matomo

**Image**: `matomo:apache`
**Port**: 80 (direct — Apache inside the container)
**Database**: MariaDB (`podium-mariadb`, user=root, password=empty)
**Credentials**: Set during install wizard

## Key Notes
- Use the `matomo:apache` tag (not `matomo:fpm` which needs a separate nginx).
- First visit shows the installation wizard at `/index.php`.
- Set `PHP_MEMORY_LIMIT=512M` to avoid memory errors on larger datasets.
- The installer exists: run `podium install matomo`.
