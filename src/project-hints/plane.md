# Plane

**Image**: `makeplane/plane-proxy:stable` (nginx gateway) + `makeplane/plane-frontend:stable` + `makeplane/plane-backend:stable` + `makeplane/plane-space:stable` + `makeplane/plane-admin:stable` + `makeplane/plane-live:stable`
**Port**: 80 (plane-proxy nginx gateway, assign VPC IP)
**Database**: PostgreSQL (`podium-postgres`) + MinIO sidecar (`plane-minio`) + RabbitMQ sidecar (`plane-mq`)
**Credentials**: Register on first visit

## Key Notes
- 10-service setup: proxy (nginx), web, space, admin, live, api, worker, beat-worker, migrator, plane-mq, plane-minio.
- Uses `.env` file and YAML anchors (`x-db-env: &db-env`, `x-app-env: &app-env`, etc.) for shared env vars.
- `migrator` uses `restart: on-failure` — runs migrations once then stops.
- Entry point is the `nginx` service (renamed from `proxy`) using `makeplane/plane-proxy:stable` image.
- MinIO stores file uploads; bucket `uploads` is created automatically.
- `SECRET_KEY` and `LIVE_SERVER_SECRET_KEY` must be long random hex strings.
- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are credentials for the internal MinIO.
- The installer exists: run `podium install plane`.
