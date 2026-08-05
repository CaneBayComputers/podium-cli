# Twenty CRM

Modern open-source CRM (a Salesforce/HubSpot alternative).

**Image**: `twentycrm/twenty:v2.27.0` (server + worker) with an `nginx:1.29-alpine` proxy
**Port**: 3000 inside the server container (via nginx proxy on 80)
**Database**: PostgreSQL (`podium-postgres`, db `twenty`) + Redis (`podium-redis`)
**Credentials**: Register on first visit

## Key Notes
- Upstream's compose ships `postgres:16`, but **vanilla PostgreSQL is all that is needed** — the old `twenty-postgres-spilo` custom image is no longer required. Podium's PG 17 works.
- The DB user must be able to create schemas and extensions: Twenty creates `core`, `metadata` and one schema per workspace inside the target database. Podium's `root` is a superuser, so this is fine.
- `ENCRYPTION_KEY` is the current required secret (`openssl rand -base64 32`); `APP_SECRET` is legacy but harmless to set. Losing `ENCRYPTION_KEY` makes stored credentials unrecoverable.
- `SERVER_URL` must exactly match the URL you browse to (`http://twenty`) or the frontend calls the wrong origin and login fails.
- The `worker` service must run with `DISABLE_DB_MIGRATIONS=true` and `DISABLE_CRON_JOBS_REGISTRATION=true` — the server already does both, and running them twice races.
- Do **not** name the app service `server`: that is one of Podium's entry-point names and it listens on 3000, not 80.
- First boot runs migrations; expect 2-3 minutes of 502s from the proxy before the UI comes up.
- The installer exists: run `podium install twenty`.
