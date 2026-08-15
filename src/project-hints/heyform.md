# HeyForm

**Image**: `heyform/community-edition:v3.0.0-rc.10`
**Port**: 9157 (behind the `nginx` reverse proxy)
**Database**: MongoDB (`podium-mongo`, root/password) + shared `podium-redis`
**Credentials**: Register the first account on first visit

## Key Notes
- **The image is `heyform/community-edition`, not `heyform/heyform`** (that is only the GitHub repo), and it is not published to GHCR.
- **The container listens on 9157, not 8000.** The published self-hosting docs still show 8000, which is stale — it predates the v3 line. `APP_LISTEN_PORT` is set explicitly here so the port can never drift.
- `APP_HOMEPAGE_URL` must exactly match the browser-visible origin, because the cookie domain and the CORS allow-list are both derived from it. Setting it wrong shows up as a login loop, not an obvious error.
- Redis is configured with discrete `REDIS_HOST` / `REDIS_PORT` vars — there is no `REDIS_URL` in HeyForm.
- MongoDB auth needs `?authSource=admin` since the shared `podium-mongo` root user lives in the admin database.
- The v3 line only publishes release candidates so far; `v3.0.0-rc.10` is what `latest` currently points at.
- HeyForm never terminates TLS itself, so plain HTTP behind nginx is the supported setup.
- The installer exists: run `podium install heyform`.
