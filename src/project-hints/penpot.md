# Penpot

**Image**: `penpotapp/frontend:latest` + `penpotapp/backend:latest` + `penpotapp/exporter:latest`
**Port**: 80 (frontend has built-in nginx — assign VPC IP directly to penpot-frontend)
**Database**: PostgreSQL (`podium-postgres`) + Redis (`podium-redis`)
**Credentials**: Register at http://penpot/ (first user becomes admin)

## Key Notes
- Three-service setup: frontend (nginx serving at 80), backend (port 6060), exporter (port 6061).
- The frontend image listens on port 8080 by default; patch it to port 80 at startup: `sed -i 's/listen 8080/listen 80/g' /etc/nginx/nginx.conf && nginx -g 'daemon off;'`
- `PENPOT_SECRET_KEY` must match between frontend and backend; generate with `openssl rand -base64 32`.
- Set `PENPOT_FLAGS=disable-email-verification enable-registration enable-login disable-secure-session-cookies`.
- Backend: `PENPOT_DATABASE_URI=postgresql://podium-postgres/penpot` (no explicit port = uses 5432 default).
- Set `PENPOT_SMTP_ENABLED=false` and `PENPOT_TELEMETRY_ENABLED=false`.
- The installer exists: run `podium install penpot`.
