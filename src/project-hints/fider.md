# Fider

**Image**: `getfider/fider:v0.36.0`
**Port**: 3000 (behind the `nginx` reverse proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password), database `fider`
**Credentials**: Create the site and admin account on the first-visit setup page

## Key Notes
- Fider **panics on boot** if `EMAIL_SMTP_HOST` and `EMAIL_SMTP_PORT` are unset — it only checks that they are present, never that they connect, so pointing at `podium-mailhog:1025` fully satisfies it.
- **Never set `HOST_DOMAIN`** — it was replaced by `BASE_URL`, and setting it makes Fider panic with an explicit "has been replaced" error.
- `BASE_URL` does not have to match the request Host; it is only parsed for link generation, so `http://fider` works fine over plain HTTP.
- `JWT_SECRET` is required but has no enforced format — any random string works; the installer uses 64 hex chars.
- Login is passwordless: Fider emails a sign-in link, so check the MailHog UI to complete the first sign-up.
- `ALLOW_PRIVATE_NETWORK_TARGETS=true` relaxes the SSRF guard so webhooks can reach other Podium containers.
- The installer exists: run `podium install fider`.
