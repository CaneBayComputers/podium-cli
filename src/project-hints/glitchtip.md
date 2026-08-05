# GlitchTip

Lightweight, Sentry-API-compatible error tracking and uptime monitoring.

**Image**: `glitchtip/glitchtip:6.2.3` (web + worker + migrate, all the same image) with an `nginx:1.29-alpine` proxy
**Port**: 8000 inside the web container (via nginx proxy on 80)
**Database**: PostgreSQL (`podium-postgres`, db `glitchtip`) + Redis (`podium-redis`)
**Credentials**: Register on first visit; the first account becomes the superuser

## Key Notes
- The GitHub repo `GlitchTip/glitchtip` is only a profile stub — the real source and release tags live on GitLab (`gitlab.com/glitchtip/glitchtip-backend`). Docker Hub tags do match the GitLab tags.
- One image, three roles picked by `command:`: default (web), `./bin/run-celery-with-beat.sh` (worker), `./bin/run-migrate.sh` (one-shot migrate). The migrate container must complete before web and worker start.
- `GLITCHTIP_DOMAIN` must exactly equal the origin you browse to (`http://glitchtip`) — a mismatch breaks CSRF and every generated link.
- `EMAIL_URL` and `DEFAULT_FROM_EMAIL` are required; pointing `EMAIL_URL` at `smtp://podium-mailhog:1025` puts invites and alerts in Mailhog. `consolemail://` also works if you just want them logged.
- `ENABLE_OPEN_USER_REGISTRATION=True` is needed to create that first account, since there is no seeded admin.
- Both web and worker need the shared `/code/uploads` volume for source maps and attachments.
- Client DSNs look like `http://<key>@glitchtip/<project-id>` — the Sentry SDKs work unmodified.
- The installer exists: run `podium install glitchtip`.
