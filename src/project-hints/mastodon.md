# Mastodon

**Image**: `ghcr.io/mastodon/mastodon:v4.5.9` + `ghcr.io/mastodon/mastodon-streaming:v4.5.9` + `nginx:1.27-alpine`
**Port**: 80 (nginx reverse proxy)
**Database**: PostgreSQL (`podium-postgres`) + Redis (`podium-redis`)
**Credentials**: Register on first visit — first account becomes admin

## Key Notes
- 5-service setup: nginx, mastodon-web (puma, port 3000), streaming (node, port 4000), sidekiq (bg jobs), db-migrate (one-time).
- `db-migrate` service runs `bundle exec rails db:migrate` with `restart: on-failure` — runs once then stops.
- nginx uses `depends_on: {mastodon-web: {condition: service_healthy}, streaming: {condition: service_healthy}}` to wait for healthy services before starting.
- `.env.production` file: `LOCAL_DOMAIN=mastodon`, `FORCE_SSL=false`, `TRUSTED_PROXY_IP=10.136.0.0/16`.
- `SECRET_KEY_BASE` must be 128 hex chars (`openssl rand -hex 64`).
- `ACTIVE_RECORD_ENCRYPTION_*` keys are needed for Rails encryption; 32 alphanumeric chars each.
- VAPID keys for push notifications are generated using `bundle exec rake mastodon:webpush:generate_vapid_key` inside the mastodon image.
- `X-Forwarded-Proto: http` (not https) in nginx — mastodon uses `FORCE_SSL=false` so no SSL redirect.
- Media files stored in `mastodon-system` volume, shared by mastodon-web, sidekiq, and nginx.
- The installer exists: run `podium install mastodon`.
