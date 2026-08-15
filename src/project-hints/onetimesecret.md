# Onetime Secret

Share a password or note via a link that self-destructs after a single view.

**Image**: `onetimesecret/onetimesecret:v0.26.3` (behind `nginx:alpine`)
**Port**: 3000 (via nginx proxy)
**Database**: `podium-redis` (db 0) — secrets live only in Redis
**Credentials**: none needed to create secrets; see below to make an admin

## Key Notes
- Encryption is **server-side (Ruby)**, not in the browser, so this one works fine over plain HTTP — unlike PrivateBin or Cryptgeon.
- Both `REDIS_URL` and `VALKEY_URL` are set to the same value: 0.26.x renamed the variable and which one is honoured depends on the point release.
- `SECRET` is generated at install time and **is not recoverable**. Losing or changing it makes every existing secret undecryptable.
- Secrets are stored in shared `podium-redis` db 0 with no persistence guarantees — a Redis flush wipes them.
- To get an admin ("colonel") account:
  `docker exec onetimesecret-app bin/ots customers create you@example.com --role colonel`
  — it prints a generated password.
- `HOST` must match how you reach it (`onetimesecret`) or generated links point at the wrong hostname.
- The installer exists: run `podium install onetimesecret`.
