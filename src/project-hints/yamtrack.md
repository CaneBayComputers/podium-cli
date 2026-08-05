# Yamtrack

Self-hosted media tracker for movies, TV, anime, games, books and manga.

**Image**: `ghcr.io/fuzzygrim/yamtrack:0.25.3` + `nginx:1.30.4-alpine`
**Port**: 8000 (behind the nginx reverse proxy on 80)
**Database**: PostgreSQL (`podium-postgres`, database `yamtrack`) + Redis (`podium-redis`, DB 2) for cache/tasks
**Credentials**: Register on first visit

## Key Notes
- Django app. `URLS=http://yamtrack` is what populates `CSRF_TRUSTED_ORIGINS`; without it every form POST fails with a CSRF error.
- `ALLOWED_HOSTS` defaults to `*`, so no extra host config is needed.
- The container falls back to SQLite unless `DB_HOST` is set — all five `DB_*` vars must be present together.
- Static files are served by the app itself (WhiteNoise); nginx only proxies.
- Metadata lookups need a TMDB API key (`TMDB_API`) — set it in the app settings or add the env var.
- The installer exists: run `podium install yamtrack`.
