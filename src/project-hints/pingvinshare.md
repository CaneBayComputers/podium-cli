# Pingvin Share

Self-hosted file-sharing platform, a WeTransfer-style drop with expiring links.

**Image**: `ghcr.io/stonith404/pingvin-share:v1.13.0` (behind `nginx:alpine`)
**Port**: 3000 (via nginx proxy)
**Database**: None (SQLite under `/opt/app/backend/data`)
**Credentials**: register on first visit — the first account becomes admin

## Key Notes
- Two volumes are required, not one: `/opt/app/backend/data` (SQLite + uploads) and `/opt/app/frontend/public/img` (branding). Mounting only the first loses your logo on every restart.
- `TRUST_PROXY: "true"` is set because nginx sits in front; without it the app records the proxy's IP for every visitor and reverse-proxy-aware links break.
- Everything else (app URL, share size limits, SMTP, OAuth) is configured from the admin UI, not env vars.
- Large uploads stream through nginx with buffering off and a 900s timeout.
- The installer exists: run `podium install pingvinshare`.
