# Zipline

ShareX/file upload server with a dashboard — screenshot and file host with short links.

**Image**: `ghcr.io/diced/zipline:4.6.5` (behind `nginx:alpine`)
**Port**: 3000 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, db `zipline`, user=root, password=password)
**Credentials**: administrator / password

## Key Notes
- Zipline publishes **no `v`-prefixed semver tags** on GHCR. The tag is `4.6.5`, not `v4.6.5` — `v4.6.5` 404s.
- `CORE_SECRET` must be longer than 32 characters or Zipline refuses to boot. The installer generates 64 hex chars.
- The env var is `DATABASE_URL` in v4; v3 called it `CORE_DATABASE_URL`. Old guides will mislead you.
- Over plain HTTP the "copy link" buttons are dead — `navigator.clipboard` is gated behind a browser secure context, and Zipline uses it in ~19 components. Uploads, viewing, sharing and password login all work; passkey MFA does not (WebAuthn is secure-context-only too). Use TOTP if you want MFA.
- Three volumes: uploads, public and themes. Losing `zipline-uploads` loses every uploaded file.
- The installer exists: run `podium install zipline`.
