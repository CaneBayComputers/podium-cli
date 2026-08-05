# Swetrix Analytics

**Image**: `swetrix/swetrix-fe:v5.4.1` + `swetrix/swetrix-api:v5.4.1`
**Port**: fe 3000 / api 5005 (both behind the `nginx` reverse proxy on 80)
**Database**: ClickHouse sidecar for events + shared `podium-redis`. No MySQL/Postgres is used.
**Credentials**: Register the first account on first visit

## Key Notes
- The `/backend/` prefix in nginx is load-bearing — the UI calls the API at `<BASE_URL>/backend/`, and the trailing slash on `proxy_pass http://swetrix-api:5005/;` strips the prefix before it reaches the API. Dropping either breaks every API call.
- ClickHouse must be bundled: it is the event store and is not one of Podium's shared services. The four XML overlays cut its RAM and disable query logging; without them it is very memory hungry.
- `CLICKHOUSE_PASSWORD` must be identical on the ClickHouse container and the API, and the API refuses to start without it.
- Redis points at the shared `podium-redis`; only ClickHouse is local to the project.
- `DISABLE_REGISTRATION=false` still only permits the *initial* user — subsequent signups are blocked either way. Note that leaving the variable unset also counts as disabled.
- `SMTP_MOCK=true` keeps Swetrix from needing a real mail server.
- The installer exists: run `podium install swetrix`.
