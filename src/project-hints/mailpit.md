# Mailpit

SMTP sink with a web UI — catches mail your apps send instead of delivering it.

**Image**: `axllent/mailpit:v1.30.6`
**Port**: 80 (direct — the UI is moved off its default 8025 via `MP_UI_BIND_ADDR`)
**Database**: None (SQLite at `/data/mailpit.db`)
**Credentials**: none

## Key Notes
- Podium already runs Mailpit as the shared `podium-mailhog` service on the stack. This project is a *second*, independent instance — use it when you want a mailbox that isn't shared with every other project.
- The UI is bound to port 80 with `MP_UI_BIND_ADDR: "[::]:80"`. The image runs as root, so binding a privileged port is fine; if you ever add `user:` to the service, that binding breaks.
- SMTP still listens on 1025 inside the container. Because the entry-point service holds the project's VPC IP, other Podium projects can send to `mailpit:1025`.
- The UI polls over a websocket, so the message list updates live only because the entry point is Mailpit itself — there is no proxy in between to strip the upgrade.
- The installer exists: run `podium install mailpit`.
