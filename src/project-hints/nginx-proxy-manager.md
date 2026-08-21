# Nginx Proxy Manager

**Image**: `jc21/nginx-proxy-manager:latest`
**Port**: 81 (admin UI, via nginx proxy) — port 80 and 443 are the proxy ports (not used in Zeltro)
**Database**: SQLite (embedded)
**Credentials**: `admin@example.com / changeme` (change immediately after first login)

## Key Notes
- The admin UI runs on port 81 — nginx proxies to `npm-app:81`.
- NPM also listens on ports 80 and 443 for proxied traffic, but in a Zeltro env those are not exposed (Zeltro's nginx handles ingress).
- Persist `npm-data` (`/data`) and `npm-letsencrypt` (`/etc/letsencrypt`) volumes.
- The installer exists: run `zeltro install nginx-proxy-manager`.
