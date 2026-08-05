# Calibre-Web Automated Book Downloader (Shelfmark)

**Image**: `ghcr.io/calibrain/shelfmark:1.3.5`
**Port**: 8084 (via nginx proxy)
**Database**: none shared — SQLite/config in the `shelfmark-config` volume
**Credentials**: Create the first account on first visit

## Key Notes
- Upstream renamed the project from *calibre-web-automated-book-downloader* to **Shelfmark**; the current image is `ghcr.io/calibrain/shelfmark`, and the old repo name publishes the same version numbers.
- Two volumes matter: `/config` (settings, database, artwork cache) and `/books` (downloads). Point `/books` at a Calibre-Web ingest folder if you want automatic imports.
- `PUID`/`PGID` control file ownership of the mounted paths; the defaults (1000) match Podium's host user.
- Sources, metadata providers and download clients are all configured inside the web UI after first login — nothing is set by env.
- The download queue streams progress over WebSockets, so the proxy needs upgrade headers and buffering off.
- Tor/WireGuard variants of this app need `NET_ADMIN`/`NET_RAW` and are deliberately not used here.
- The installer exists: run `podium install calibre-web-automated-book-downloader`.
