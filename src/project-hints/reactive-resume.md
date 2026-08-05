# Reactive Resume

Free resume builder — multiple resumes per account, live preview, PDF export.

**Image**: `amruthpillai/reactive-resume:v5.2.5`
**Port**: 3000 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, db `reactive_resume`) + Redis (`podium-redis`)
**Credentials**: register on first visit

## Key Notes
- v5 collapsed the old multi-container stack (client + server + chrome + minio) into one image. Ignore v4-era guides — `CHROME_TOKEN`, `PUBLIC_URL`/`STORAGE_URL` and the browserless container no longer apply.
- Upstream's compose runs SeaweedFS for S3 storage; **omitting all `S3_*` vars** makes the app fall back to the local filesystem at `LOCAL_STORAGE_PATH=/app/data`, which is why no object store is bundled here.
- `AUTH_SECRET` and `ENCRYPTION_SECRET` are separate values, both 32-byte hex. Regenerating them invalidates sessions and saved AI provider keys.
- `APP_URL` is used for auth callbacks and OpenGraph; it must match the hostname in the browser or login redirects break.
- With no SMTP configured the app logs verification/reset emails to stdout instead of sending them — `docker logs reactive-resume` to grab the link. Set `SMTP_HOST`/`SMTP_USER`/`SMTP_PASS`/`SMTP_FROM` (all four, or it stays in console mode) to change that.
- The container runs as the `node` user; `/app/data` is owned by it in the image, so the named volume inherits correct ownership.
- The installer exists: run `podium install reactive-resume`.
