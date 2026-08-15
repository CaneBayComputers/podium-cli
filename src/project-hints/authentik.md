# authentik

Identity provider / SSO (OAuth2, SAML, LDAP, proxy outposts).

**Image**: `ghcr.io/goauthentik/server:2026.5.6`
**Port**: 9000 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password, db `authentik`)
**Credentials**: `akadmin` / `admin123` — first run finishes at `http://authentik/if/flow/initial-setup/`

## Key Notes
- **No Redis.** authentik dropped Redis entirely in 2025.10; caching, the embedded outpost and WebSockets all moved to Postgres. `AUTHENTIK_REDIS__*` vars no longer exist.
- Two containers from the same image: `command: server` and `command: worker`. The **worker is mandatory** — it applies the blueprints that create the default flows, so without it there is no login page at all. It also wants `user: root`.
- Migrations run in-process on boot (both containers call `run_migrations`); there is no separate migration step.
- `AUTHENTIK_BOOTSTRAP_PASSWORD` / `AUTHENTIK_BOOTSTRAP_EMAIL` are only read on the very first startup, before any user exists.
- The server listens on 9000 (HTTP) and 9443 (HTTPS) — proxy to **9000** only.
- Env var nesting uses double underscores: `AUTHENTIK_POSTGRESQL__HOST`.
- The installer exists: run `podium install authentik`.
