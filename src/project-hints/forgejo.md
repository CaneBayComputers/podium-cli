# Forgejo

Self-hosted Git forge (community fork of Gitea).

**Image**: `codeberg.org/forgejo/forgejo:16.0.2`
**Port**: 3000 (via nginx proxy)
**Database**: MariaDB (`podium-mariadb`, user=root, password=empty)
**Credentials**: Register on first visit — the first user becomes admin

## Key Notes
- Config env vars use the `FORGEJO__section__KEY` double-underscore prefix (the legacy `GITEA__` prefix also still works).
- The install wizard still appears on first visit even with the DB env set — the fields are pre-filled, just click through. Set `FORGEJO__security__INSTALL_LOCK=true` if you want to skip it.
- Create the DB before first start: `docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS forgejo;"`
- Git-over-SSH is not exposed (Podium publishes HTTP only) — clone over HTTP.
- `client_max_body_size 512M` in the proxy, otherwise large pushes fail with 413.
- The installer exists: run `podium install forgejo`.
