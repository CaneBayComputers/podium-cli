# Navidrome

Self-hosted music server and streamer, Subsonic-API compatible.

**Image**: `deluan/navidrome:0.63.2` + `nginx:1.30.4-alpine`
**Port**: 4533 (behind the nginx reverse proxy on 80)
**Database**: None — SQLite in the `navidrome-data` volume
**Credentials**: Create the admin account on first visit

## Key Notes
- Music goes in the `navidrome-music` volume (mounted at `/music`); it is read-only to the app in practice, and an empty library is a valid startup state.
- Every setting is an `ND_*` env var — there is no config file to edit unless you write `/data/navidrome.toml`.
- `proxy_buffering off` in the nginx config matters: without it, seeking within a track over the transcoding endpoint stalls.
- Subsonic clients point at `http://navidrome/rest/...` with the same credentials.
- The installer exists: run `podium install navidrome`.
