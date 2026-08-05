# SparkyFitness

Self-hosted nutrition, exercise and body-measurement tracker (a MyFitnessPal alternative).

**Image**: `codewithcj/sparkyfitness:v1.6.1` (frontend) + `codewithcj/sparkyfitness_server:v1.6.1` (backend)
**Port**: the frontend nginx already listens on **80** — no extra proxy needed. Backend is on 3010.
**Database**: PostgreSQL (`podium-postgres`, db `sparkyfitness`)
**Credentials**: Register on first visit — register `admin@example.com` to land the admin panel

## Key Notes
- Two images, not one. `codewithcj/sparkyfitness` is the **frontend only**; `codewithcj/sparkyfitness_server` is the API. They share a release cadence and tag set, so pin both to the same version.
- The frontend image is a plain nginx serving on port 80 and proxying `/api/*` to `SPARKY_FITNESS_SERVER_HOST:SPARKY_FITNESS_SERVER_PORT`. Because it is already on 80 it can be the `web` service directly — that is why there is no separate proxy container here.
- The backend needs **two** DB identities: `SPARKY_FITNESS_DB_USER` (a superuser used for schema creation and migrations — Podium's `root` works) and `SPARKY_FITNESS_APP_DB_USER`/`_PASSWORD`, a limited role the backend creates itself on first boot. Both are mandatory.
- `SPARKY_FITNESS_API_ENCRYPTION_KEY` must be exactly **64 hex chars** (`openssl rand -hex 32`). `BETTER_AUTH_SECRET` signs sessions and 2FA data — changing it later locks out every user who enabled TOTP.
- `SPARKY_FITNESS_FRONTEND_URL` drives CORS and Better Auth's trusted origins; it must equal `http://sparkyfitness`. `ALLOW_PRIVATE_NETWORK_CORS=true` is needed for private-LAN access like Podium's VPC.
- Upstream's compose uses `${VAR:?Variable is required and must be set}` guards, so a missing value stops `docker compose` before the app runs at all.
- Backend boot takes ~30-60s while it builds the schema; the frontend answers 200 immediately but `/api/*` returns 502 until then.
- Persist `/app/SparkyFitnessServer/uploads` (profile and exercise images) and `.../backup`.
- The Garmin sync microservice is a separate optional image and is disabled upstream by default.
- The installer exists: run `podium install sparkyfitness`.
