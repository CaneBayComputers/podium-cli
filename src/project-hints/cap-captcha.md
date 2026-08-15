# Cap (CAPTCHA)

**Image**: `tiago2/cap:3.1.9`
**Port**: 3000 (via nginx proxy) — dashboard and the reCAPTCHA-compatible API share it
**Database**: Redis only (`podium-redis`, db 9, key prefix `cap:`)
**Credentials**: admin key `podium-cap-admin-key` — that string *is* the dashboard login

## Key Notes
- Port is set with `SERVER_PORT`, not `PORT`. `SERVER_HOSTNAME` defaults to `0.0.0.0`.
- `ADMIN_KEY` is mandatory and must be at least 12 characters, or the process refuses to boot. There is no separate password — log in with the key, then create a site key/secret pair in the dashboard.
- Redis is mandatory in 3.x: the app PINGs it at import time and exits if it is unreachable. There is no SQLite fallback — **all** challenge and site data lives in Redis, so `REDIS_PREFIX` plus a dedicated db index matter (Cap uses `KEYS` scans that would otherwise walk other projects' keys).
- Challenge state must not be evicted; keep the shared Redis on a `noeviction` policy.
- `/usr/src/app/data` (no leading dot in 3.x) only caches the MaxMind GeoLite2 files and is optional.
- The installer exists: run `podium install cap-captcha`.
