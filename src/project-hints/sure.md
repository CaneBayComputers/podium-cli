# Sure

Personal finance / net-worth tracker — the community-maintained continuation of Maybe Finance.

**Image**: `ghcr.io/we-promise/sure:0.7.0-hotfix.2`
**Port**: 3000 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, db `sure`) + Redis (`podium-redis`, db 1) for Sidekiq
**Credentials**: register on first visit — the first account becomes the admin

## Key Notes
- The repo tags a lot of `-alpha`/`-rc` builds; `0.7.0-hotfix.2` is the newest **stable** one. There is also a moving `stable` tag — not usable here since it can't be pinned.
- `RAILS_FORCE_SSL` and `RAILS_ASSUME_SSL` both default to **true** in production. Over plain HTTP that means an endless redirect loop, so both must be explicitly `"false"`.
- Connection env is split (`DB_HOST`/`DB_PORT` + `POSTGRES_USER`/`POSTGRES_PASSWORD`/`POSTGRES_DB`), not a single `DATABASE_URL`.
- The entrypoint runs `./bin/rails db:prepare` **only when the command is `./bin/rails server`** — that is why the web service keeps the image's default command and only the worker overrides it with `bundle exec sidekiq`.
- Both containers share `/rails/storage` (uploads/attachments) and must use the same `SECRET_KEY_BASE`.
- Optional AI features want `OPENAI_ACCESS_TOKEN`; leaving it unset simply hides them.
- The installer exists: run `podium install sure`.
