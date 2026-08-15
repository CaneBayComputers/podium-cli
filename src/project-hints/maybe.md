# Maybe Finance

Personal finance and wealth-management app (Rails) — accounts, budgets, transactions, net worth.

**Image**: `ghcr.io/maybe-finance/maybe:0.6.0` (web + Sidekiq worker) with an `nginx:1.29-alpine` proxy
**Port**: 3000 inside the web container (via nginx proxy on 80)
**Database**: PostgreSQL (`podium-postgres`, db `maybe`) + Redis (`podium-redis`, database 1)
**Credentials**: Register on first visit

## Key Notes
- GHCR numeric tags run ahead of what the tag-list API returns in one page — `0.6.0` exists even though a truncated listing stops at `0.5.0`. Verify with `docker manifest inspect` rather than trusting a partial tag list.
- Note the env-var split: the host is `DB_HOST`/`DB_PORT`, but the credentials reuse the Postgres image names `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB`. There is no single `DATABASE_URL`.
- `SECRET_KEY_BASE` must be set and stable — the upstream example ships a hardcoded one that must not be reused. Losing it invalidates all sessions and encrypted credentials.
- `SELF_HOSTED=true` is required; without it the app expects the hosted multi-tenant configuration.
- Keep `RAILS_FORCE_SSL` and `RAILS_ASSUME_SSL` at `false` for plain-HTTP local use, or every request redirects to https and never resolves.
- The Sidekiq `worker` container is required for imports, syncs and rules; it shares the `/rails/storage` volume with web.
- First boot runs migrations before Puma binds — expect a minute or two of 502s. `/` redirects to `/registration/new` until the first user exists.
- `OPENAI_ACCESS_TOKEN` is optional and only powers the AI chat/rules features (and costs money).
- The installer exists: run `podium install maybe`.
