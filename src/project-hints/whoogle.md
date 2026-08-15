# Whoogle Search

Self-hosted, ad-free, privacy-respecting Google search front-end (no JS, no cookies, no tracking).

**Image**: `benbusby/whoogle-search:1.2.4`
**Port**: 5000 (via nginx proxy)
**Database**: none
**Credentials**: none by default; set `WHOOGLE_USER` + `WHOOGLE_PASS` for basic auth

## Key Notes
- The image runs as the unprivileged `whoogle` user (uid/gid **927**). `/config`, `/var/lib/tor` and `/run/tor` must be writable — the tmpfs mounts with `uid=927,gid=927` are how upstream does it, and they also keep config out of a persistent volume (there is nothing worth persisting).
- The default command starts a Tor daemon alongside the app. Tor is only used when a request opts into it; if it fails to start the search app still works.
- Settings are per-browser (stored in a cookie or a URL config), so there is no shared state to back up.
- It scrapes Google live — expect occasional CAPTCHA/rate-limit pages from a residential IP, and none of it works offline.
- `WHOOGLE_CONFIG_*` env vars preset the defaults shown on the config page; the `WHOOGLE_ALT_*` vars redirect Twitter/YouTube/Reddit links to farside.link front-ends.
- The installer exists: run `podium install whoogle`.
