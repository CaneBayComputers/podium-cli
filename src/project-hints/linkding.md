# linkding

Minimal, fast bookmark manager with tagging and full-text search.

**Image**: `sissbruecker/linkding:1.45.0`
**Port**: 9090 (via nginx proxy)
**Database**: None (SQLite in the `linkding-data` volume)
**Credentials**: admin / admin123

## Key Notes
- `LD_SUPERUSER_NAME` / `LD_SUPERUSER_PASSWORD` only take effect on the *first* boot, while the database is still empty. Changing them later does nothing — use the Django admin at `/admin/` instead.
- `LD_CSRF_TRUSTED_ORIGINS` is set to the Podium hostname so form posts pass Django's CSRF origin check.
- The `-plus` image variants bundle extra archiving dependencies; this installer uses the plain build.
- The installer exists: run `podium install linkding`.
