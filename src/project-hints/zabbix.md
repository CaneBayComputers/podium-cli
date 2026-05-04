# Zabbix

**Image**: `zabbix/zabbix-server-pgsql:alpine-latest` + `zabbix/zabbix-web-nginx-pgsql:alpine-latest`
**Port**: 8080 (zabbix-web, nginx reverse proxy)
**Database**: PostgreSQL (`podium-postgres`)
**Credentials**: Admin / zabbix

## Key Notes
- Two-service setup: `zabbix-server-pgsql` (backend, port 10051) and `zabbix-web-nginx-pgsql` (frontend, port 8080).
- `ZBX_SERVER_HOST` in the web container must point to the server container name.
- PostgreSQL database `zabbix` must be created before first start.
- Use `alpine-latest` tags (the plain `latest` tag uses Debian which is larger).
- The installer exists: run `podium install zabbix`.
