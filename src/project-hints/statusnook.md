# Statusnook

Self-hosted status page with built-in endpoint monitoring and notifications.

**Image**: `goksan/statusnook@sha256:9b2c8721...` (+ `nginx:1.29-alpine` proxy)
**Port**: 8000 inside the app container (via nginx proxy on 80)
**Database**: none — embedded SQLite under `/app/statusnook-data`
**Credentials**: Set the admin account on first visit at `http://statusnook/admin`

## Key Notes
- **Pinned by digest, not tag.** Upstream has published exactly one Docker Hub tag ever — `latest`, pushed 2024-06-18 alongside release v0.3.0 — so there is no version tag to pin. The digest pin is the stable equivalent. The project has had no commits since June 2024; treat it as unmaintained.
- The README's "requires ports 80 and 443" warning applies only to the **standalone installer script**, which does its own ACME/TLS. The container's entrypoint passes `-docker`, which skips the TLS listener entirely and serves plain HTTP on `$PORT`.
- `PORT` (default 8000) is the only meaningful env var; there are no secrets to pre-seed. All configuration happens through the web UI or the YAML editor on the settings page.
- Upstream's compose binds the published port to `127.0.0.1` — irrelevant under Podium, which routes over the VPC network instead.
- Persist `/app/statusnook-data`; it holds the SQLite database and the config.
- The installer exists: run `podium install statusnook`.
