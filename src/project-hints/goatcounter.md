# GoatCounter

**Image**: `arp242/goatcounter:2.7.0`
**Port**: 8080 (behind the `nginx` reverse proxy)
**Database**: SQLite in the `goatcounter-data` volume (no shared DB needed)
**Credentials**: Create the first site and user on first visit

## Key Notes
- `-tls http` is required. GoatCounter's default TLS mode would try to obtain ACME certificates, which cannot work on a local hostname.
- **Site domain must be left blank in the setup wizard.** GoatCounter validates the vhost with a two-label rule (min 4 chars, must contain a dot), so `goatcounter` is rejected; blank falls back to `goatcounter.localhost`.
- Serving at `http://goatcounter/` works because of GoatCounter's single-site fallback: when the request Host matches no site and exactly one site exists, it serves that site anyway (with a console warning). Adding a second site would break this.
- The container runs as non-root, so it cannot bind port 80 directly — hence listening on 8080 behind nginx.
- The dashboard and the `/count` tracking endpoint share the same port; no second origin is needed.
- The installer exists: run `podium install goatcounter`.
