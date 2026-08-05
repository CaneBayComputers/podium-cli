# Gotify

Simple self-hosted push-notification server with a REST API and a web UI.

**Image**: `gotify/server:3.0.0`
**Port**: 80 (direct — Gotify's own default listen port is already 80)
**Database**: None (SQLite under `/app/data`)
**Credentials**: admin / admin123

## Key Notes
- v3 dropped `config.yml` support entirely — configuration is env-only now, so `GOTIFY_*` vars are the only way in.
- `GOTIFY_DEFAULTUSER_PASS` only applies on the very first boot, while the database is being created. Changing it later does nothing.
- Create an "application" in the UI to get a token, then push with `curl -F "message=hi" "http://gotify/message?token=<apptoken>"`.
- API tokens are shown once, at creation time — v3 no longer returns them from GET endpoints.
- The installer exists: run `podium install gotify`.
