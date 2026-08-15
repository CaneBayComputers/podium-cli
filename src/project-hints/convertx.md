# ConvertX

Self-hosted file converter — 1000+ formats via ffmpeg, ImageMagick, LibreOffice, Calibre, Pandoc and friends.

**Image**: `ghcr.io/c4illin/convertx:v0.18.0` (behind `nginx:alpine`)
**Port**: 3000 (via nginx proxy)
**Database**: None (SQLite under `/app/data`)
**Credentials**: register on first visit — the first account created is the only one unless you re-enable registration

## Key Notes
- `HTTP_ALLOWED: "true"` is **mandatory** here. Without it ConvertX refuses to issue its auth cookie over a non-HTTPS, non-localhost origin and login silently fails.
- `ACCOUNT_REGISTRATION: "false"` still permits the very first account. Flip it to `true` if you want more users later.
- Conversions run server-side and can take minutes, so the proxy uses 900s timeouts, `client_max_body_size 0` and `proxy_request_buffering off`.
- Uploads are auto-deleted after 24h (`AUTO_DELETE_EVERY_N_HOURS`); set it to `0` to keep them.
- The installer exists: run `podium install convertx`.
