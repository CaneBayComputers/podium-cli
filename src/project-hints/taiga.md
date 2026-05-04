# Taiga

**Image**: `taigaio/taiga-back` + `taigaio/taiga-front` + `taigaio/taiga-events` + `taigaio/taiga-protected` + `nginx:1.19-alpine` (gateway)
**Port**: 80 (taiga-gateway nginx, assign VPC IP directly)
**Database**: PostgreSQL (`podium-postgres`) + 2× RabbitMQ sidecars + Redis (`podium-redis`)
**Credentials**: Register on first visit

## Key Notes
- 8-service setup: back, async (same image as back), taiga-front, taiga-events, taiga-protected, 2× RabbitMQ (async + events), and nginx gateway.
- Uses `.env` file with YAML anchors (`x-environment`) for shared env vars across services.
- `taiga-async` uses the same image as `taiga-back` but with a different entrypoint: `/taiga-back/docker/async_entrypoint.sh`.
- The gateway nginx (not a separate Podium nginx) handles all routing — assign the VPC IP to `taiga-gateway`.
- `taiga-gateway/taiga.conf` routes `/api/` and `/admin/` to back, `/events` to events, `/media/` to protected, `/static/` from volume.
- `POSTGRES_HOST=podium-postgres` (not a local service).
- `EMAIL_BACKEND=console` for dev (no actual email sending).
- The installer exists: run `podium install taiga`.
