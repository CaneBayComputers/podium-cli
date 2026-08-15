# Fizzy

**Image**: `ghcr.io/basecamp/fizzy:sha-bbb6948`
**Port**: 80 (Thruster — served directly, no proxy)
**Database**: SQLite inside the `fizzy-storage` volume (`/rails/storage`) — no shared DB used
**Credentials**: Sign up with any email on first visit; the sign-in code is in the logs

## Key Notes
- 37signals publishes no semver tags — only `main`/`latest` and immutable `sha-<commit>` tags, so the installer pins the commit tag `sha-bbb6948`.
- `DISABLE_SSL=true` is mandatory. Without it the image tries to terminate TLS itself (`TLS_DOMAIN`) and HTTP on port 80 will not answer.
- `BASE_URL=http://fizzy` is used for links in emails and push payloads.
- `SECRET_KEY_BASE` must be a long random string; regenerating it invalidates existing sessions and signed links.
- No SMTP is configured on purpose: sign-in emails a 6-character code, and with mail unconfigured that code is printed to the container log (`docker logs fizzy`). Adding a broken SMTP host would make sign-in fail instead.
- `MULTI_TENANT=false` means new account signups close after the first account is created; set it to `true` for multiple accounts.
- All state (SQLite + Active Storage uploads) lives in `/rails/storage`.
- The installer exists: run `podium install fizzy`.
