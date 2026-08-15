# Slash

Self-hosted link shortener and bookmark manager (yourselfhosted/slash).

**Image**: `yourselfhosted/slash:0.5.3` + `nginx:1.30.4-alpine`
**Port**: 5231 (behind the nginx reverse proxy on 80)
**Database**: None — SQLite in the `slash-data` volume
**Credentials**: Register on first visit; the first account created becomes the host/admin

## Key Notes
- v0.5.3 is the latest tagged upstream release (Feb 2024); the `1.0.0-rc.*` tags are pre-releases and are not used.
- Shortcut links resolve at `http://slash/s/<name>` — a bare `/<name>` is also handled by the app.
- The installer exists: run `podium install slash`.
