# Keycloak

Identity and access management server (OIDC / SAML).

**Image**: `quay.io/keycloak/keycloak:26.7.1`
**Port**: 8080 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password, db `keycloak`)
**Credentials**: `admin` / `admin123`

## Key Notes
- 26.x renamed the initial admin vars: `KC_BOOTSTRAP_ADMIN_USERNAME` / `KC_BOOTSTRAP_ADMIN_PASSWORD` (the old `KEYCLOAK_ADMIN*` names are ignored). They only take effect while the DB has no admin user.
- Production mode (`start`) refuses to run without TLS unless `KC_HTTP_ENABLED=true`; behind the proxy also set `KC_PROXY_HEADERS=xforwarded`, `KC_HOSTNAME=http://keycloak` and `KC_HOSTNAME_STRICT=false`, or issuer URLs come out wrong.
- `--optimized=false` makes Keycloak build the augmented distribution at boot. First start takes 30-90s and returns 502 through the proxy until it finishes.
- Keycloak creates and migrates its own schema; only the empty database has to exist.
- Auth flows push large cookies/headers — `large_client_header_buffers 4 32k` in the proxy avoids random 400s.
- The installer exists: run `podium install keycloak`.
