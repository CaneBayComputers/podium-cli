# Apprise API

HTTP gateway in front of Apprise — one POST fans a notification out to 130+ services.

**Image**: `caronc/apprise:v1.5.1` (behind `nginx:alpine`)
**Port**: 8000 (via nginx proxy)
**Database**: None (config files under `/config`)
**Credentials**: none

## Key Notes
- The backend service is deliberately named `notifier`, **not** `apprise-app` or similar: Podium's web-service regex is `^(nginx|web|app|api|server|frontend|backend|http)` and any name starting with "apprise" matches on `app`, which would hand the project IP to the wrong container.
- `APPRISE_STATEFUL_MODE: simple` maps each `{key}` straight onto a file in `/config`, which is what you want for a single-user setup.
- Workflow: open `http://apprise-api/`, pick a key, paste your Apprise URLs, save. Then `curl -X POST -d 'body=hello' http://apprise-api/notify/<key>`.
- The image runs as root by default, so the named volumes need no ownership fixups.
- The installer exists: run `podium install apprise-api`.
