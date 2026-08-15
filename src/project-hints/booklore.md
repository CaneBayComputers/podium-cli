# BookLore

Self-hosted, multi-user digital library for EPUB, PDF and comics with a built-in reader and OPDS.

**Image**: `ghcr.io/booklore-app/booklore:v2.3.1` + `nginx:1.30.4-alpine`
**Port**: 6060 (behind the nginx reverse proxy on 80)
**Database**: MariaDB (`podium-mariadb`, database `booklore`, user `booklore`/`booklore`)
**Credentials**: Create the admin account on first visit

## Key Notes
- The connection string is JDBC, not a URL: `jdbc:mariadb://podium-mariadb:3306/booklore`.
- `pre_install()` creates a dedicated `booklore` MariaDB user because the Spring datasource does not like the shared root account's empty password.
- First boot runs Flyway migrations under the JVM — allow ~60 s before the proxy starts returning 200.
- `USER_ID`/`GROUP_ID` drive the `su-exec` drop in the entrypoint; leave them at 1000 so the named volumes stay writable.
- Drop files into the `booklore-bookdrop` volume (`/bookdrop`) for auto-import; the library itself lives in `/books`.
- WebSocket (STOMP) is used for import progress, hence the `Upgrade`/`Connection` headers in the proxy.
- The installer exists: run `podium install booklore`.
