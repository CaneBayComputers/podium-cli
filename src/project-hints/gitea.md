# Gitea

**Image**: `gitea/gitea:latest`
**Port**: 3000 (via nginx proxy)
**Database**: MariaDB (`podium-mariadb`, user=root, password=empty)
**Credentials**: Set on first visit (register first user as admin)

## Key Notes
- Use `GITEA__` double-underscore env var prefix for all Gitea config sections.
- MariaDB must exist before first start: `docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS gitea;"`
- Set `GITEA__server__ROOT_URL=http://gitea/` and `GITEA__server__HTTP_PORT=3000`.
- Persist `/data` volume for repos, keys, and avatars.
- The installer exists: run `podium install gitea`.
