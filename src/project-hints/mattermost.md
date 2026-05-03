# Mattermost

**Image**: `mattermost/mattermost-team-edition:latest`
**Port**: 8065 (via nginx proxy with WebSocket support)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password)
**Credentials**: Create System Admin account on first visit

## Key Notes
- Env: `MM_SQLSETTINGS_DRIVERNAME=postgres`, `MM_SQLSETTINGS_DATASOURCE=postgres://root:password@podium-postgres:5432/mattermost?sslmode=disable`.
- Set `MM_SERVICESETTINGS_SITEURL=http://mattermost` and `MM_SERVICESETTINGS_LISTENADDRESS=:8065`.
- Create DB first: `docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE mattermost;"`
- nginx config needs WebSocket headers for both the `/api/.../websocket` path and general traffic.
- Persist six volumes: config, data, logs, plugins, client/plugins, bleve-indexes.
- `client_max_body_size 100M` recommended for file uploads.
- The installer exists: run `podium install mattermost`.
