# SearXNG

**Image**: `searxng/searxng:latest`
**Port**: 8080 (via nginx proxy)
**Database**: None
**Credentials**: None (public metasearch engine)

## Key Notes
- Set `SEARXNG_BASE_URL=http://searxng/` so results link back correctly.
- May show 502 briefly on startup — the container takes a few seconds to initialize.
- No authentication by default; add HTTP basic auth via nginx if you want to restrict access.
- The installer exists: run `podium install searxng`.
