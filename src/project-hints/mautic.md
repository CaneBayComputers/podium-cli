# Mautic

**Image**: `mautic/mautic:5-apache`
**Port**: 80 (direct — no nginx proxy)
**Database**: MariaDB (`podium-mariadb`, dedicated user required)
**Credentials**: Set during install wizard

## Key Notes
- Mautic 5 requires a dedicated MariaDB user — root login fails with this image.
- Create DB and user before starting: `CREATE USER 'mautic'@'%' IDENTIFIED BY '...'; GRANT ALL ON mautic.* TO 'mautic'@'%';`
- Set `DOCKER_MAUTIC_RUN_MIGRATIONS=true` so the container auto-runs migrations on startup.
- First visit shows the installation wizard. Complete it to set admin credentials.
- The installer exists: run `podium install mautic`.
