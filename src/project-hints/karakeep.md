# Karakeep

Bookmark-everything app (formerly Hoarder) — saves links, notes and images with full-text and optional AI tagging.

**Image**: `ghcr.io/karakeep-app/karakeep:0.33.1`
**Port**: 3000 (via nginx proxy)
**Database**: None (SQLite in the `karakeep-data` volume); bundles Meilisearch and headless Chrome
**Credentials**: Register on first visit — the first account is the admin

## Key Notes
- The two sidecars are not optional extras: `meilisearch` backs full-text search and `chrome` does the page crawling and screenshots. Neither is a Podium shared service, so both are bundled here. `MEILI_MASTER_KEY` must be identical in the app and the Meilisearch container.
- Upstream names its app service `web`, which Podium would treat as the entry point even though it listens on 3000. It is renamed `karakeep-app` here so the nginx proxy is picked up instead.
- AI tagging stays off unless you add `OPENAI_API_KEY` (or point `OLLAMA_BASE_URL` at a local model).
- `NEXTAUTH_URL` and `NEXTAUTH_SECRET` drive sign-in; changing the secret logs everyone out.
- The installer exists: run `podium install karakeep`.
