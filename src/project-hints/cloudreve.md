# Cloudreve

Self-hosted cloud storage / file sharing with multi-backend support.

**Image**: `cloudreve/cloudreve:4.18.0`
**Port**: 5212 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password, db `cloudreve`) + Redis db 4
**Credentials**: register on first visit — the first registered account is elevated to administrator

## Key Notes
- v4 changed the bootstrap: there is **no seeded `admin@cloudreve.org` account and no password printed in the logs** (that was v2/v3). Self-registration is enabled by default with no captcha and no email verification, so just sign up.
- Config comes from `CR_CONF_<Section>.<Key>` env vars — the dots are part of the name. `CR_CONF_Database.Type` must be `postgres` (`mariadb` is rewritten to `mysql`, `mssql` is rejected).
- **Env-var config is sticky**: anything set this way cannot be changed later by editing `conf.ini`.
- `CR_CONF_OptionOverwrite.siteURL=http://cloudreve` overrides the DB-stored site URL (default `http://localhost:5212`) without touching the admin panel.
- Cloudreve does not create its own database — it must exist beforehand. The PG connection is hardcoded `sslmode=disable`.
- Aria2 remote download would need port 6888; it is not published, everything else lives on 5212.
- The installer exists: run `podium install cloudreve`.
