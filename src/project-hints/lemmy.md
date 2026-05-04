# Lemmy

**Image**: `nginx:1-alpine` (proxy) + `dessalines/lemmy:0.19.18` + `dessalines/lemmy-ui:0.19.18` + `asonix/pictrs:0.5.23`
**Port**: 80 (nginx proxy, assign VPC IP)
**Database**: PostgreSQL (`podium-postgres`)
**Credentials**: lemmy / lemmylemmy (created on first start via `lemmy.hjson` setup block)

## Key Notes
- 4-service setup: nginx, lemmy-backend (port 8536), lemmy-ui (port 1234), pictrs (image host, port 8080).
- nginx uses a full `nginx.conf` (not just `conf.d/default.conf`) because it needs top-level `map` and `resolver` directives.
- The `map` directive routes by request method and Accept header: ActivityPub requests go to lemmy-backend, others to lemmy-ui.
- nginx also needs a `proxy_params` file mounted at `/etc/nginx/proxy_params`.
- `lemmy.hjson` configures the backend: database URI, hostname, CORS, pictrs API key.
- Admin credentials are set in the `setup` block of `lemmy.hjson` and are only applied on first start.
- pictrs runs as user `991:991` (non-root).
- The installer exists: run `podium install lemmy`.
