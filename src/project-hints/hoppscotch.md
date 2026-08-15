# Hoppscotch

Open-source API development environment — a self-hosted Postman alternative.

**Image**: `hoppscotch/hoppscotch:2026.7.0` (AIO, direct)
**Port**: 80 (direct — the AIO image's bundled Caddy binds 80 in subpath mode)
**Database**: PostgreSQL (`podium-postgres`, db `hoppscotch`, user=root, password=password)
**Credentials**: the first account that signs in at `/admin` becomes the administrator

## Key Notes
- `ENABLE_SUBPATH_BASED_ACCESS: "true"` is what makes this fit Podium at all. In the default "multiport" mode the AIO image binds 3000, 3100 and 3170 separately and needs three exposed ports; subpath mode collapses them onto port 80 as `/`, `/admin` and `/backend`.
- Subpath mode binds port 80 and the container runs as root, so it works. If you ever add a `user:` override you must also set `HOPP_ALTERNATE_PORT` to something >= 1024 (and not 8080, 3200, 3000, 3100 or 3170, which the image reserves).
- `DATA_ENCRYPTION_KEY` must be **exactly 32 characters** — the installer uses `openssl rand -hex 16`.
- The `VITE_*` values are baked into the frontend bundle at container start by `import-meta-env`, so they must be the URLs a *browser* uses (`http://hoppscotch/...`), not internal service names.
- The database must exist first; the AIO entrypoint runs Prisma migrations but not `CREATE DATABASE`. `pre_install()` handles it.
- Sign-in needs an auth provider. Email magic-link needs SMTP, configurable from the admin dashboard — point it at `podium-mailhog:1025` and read the mail there.
- The installer exists: run `podium install hoppscotch`.
