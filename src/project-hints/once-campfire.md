# Campfire (ONCE)

Basecamp's team chat, open-sourced as ONCE Campfire.

**Image**: `ghcr.io/basecamp/once-campfire:1.4.9`
**Port**: 80 (native — no proxy needed)
**Database**: none — SQLite inside the `/rails/storage` volume
**Credentials**: register on first visit; the first account becomes the admin

## Key Notes
- `DISABLE_SSL=true` is what makes it serve plain HTTP on port 80. Without it the image tries to provision Let's Encrypt certs for `TLS_DOMAIN` and nothing answers on 80.
- Campfire is SQLite-only by design — the database *and* uploaded attachments live in `/rails/storage`. It cannot use `podium-postgres`/`podium-mariadb`; that one volume is the whole backup.
- `SECRET_KEY_BASE` plus a `VAPID_PUBLIC_KEY`/`VAPID_PRIVATE_KEY` pair are required env. The VAPID pair is a P-256 key: `openssl ecparam -name prime256v1 -genkey -noout -outform DER`, then base64url the raw 32-byte scalar (bytes 7..39) and the raw 65-byte point (last 65 bytes). Upstream's own generator is `docker run --rm <image> script/admin/generate-secrets`.
- Web Push notifications need a secure context, so they stay dead over plain HTTP — chat itself works fine.
- The installer exists: run `podium install once-campfire`.
