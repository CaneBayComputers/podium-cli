# Zulip

**Image**: `zulip/docker-zulip:latest` + `memcached:alpine` + `rabbitmq:management-alpine` + `nginx:alpine`
**Port**: 80 (nginx reverse proxy)
**Database**: PostgreSQL (`podium-postgres`) + Redis (`podium-redis`)
**Credentials**: Register at http://zulip/register/ — first user becomes admin

## Key Notes
- 4-service setup: nginx (entry point), zulip-app (all-in-one image with bundled nginx), zulip-memcached, zulip-rabbitmq.
- `zulip/docker-zulip` bundles its own nginx that redirects HTTP→HTTPS; our external nginx sets `X-Forwarded-Proto: https` to suppress the redirect.
- `SETTING_EXTERNAL_HOST=zulip` (must match the container/DNS name).
- `SECRETS_postgres_password=password` must match podium-postgres root password.
- Generate `SECRETS_secret_key`, `SECRETS_rabbitmq_password`, `SECRETS_memcached_password` with `openssl rand -hex`.
- memcached uses SASL auth; password in `MEMCACHED_PASSWORD` must match `SECRETS_memcached_password`.
- RabbitMQ user is `zulip` with the generated rabbitmq password; `RABBITMQ_DEFAULT_PASS` must match `SECRETS_rabbitmq_password`.
- First startup takes ~3 minutes while Zulip initializes and creates the database schema.
- The installer exists: run `podium install zulip`.
