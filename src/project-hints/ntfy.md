# ntfy

Pub/sub notification service — publish with a plain HTTP POST, subscribe from a phone, browser or CLI.

**Image**: `binwiederhier/ntfy:v2.27.0`
**Port**: 80 (direct — ntfy's default `listen-http` is already `:80`)
**Database**: None (SQLite cache + auth files on volumes)
**Credentials**: none — anonymous read-write on every topic

## Key Notes
- The image's entrypoint needs the `serve` argument; without it the container just prints help and exits.
- `NTFY_BASE_URL` must match how you reach it (`http://ntfy`) or attachment links and the web UI's subscribe button point at the wrong host.
- Everything is world-writable by default. To lock it down set `NTFY_AUTH_DEFAULT_ACCESS: deny-all` and add users with `docker exec ntfy ntfy user add --role=admin <name>`.
- Publish test: `curl -d "hello" http://ntfy/mytopic`.
- The installer exists: run `podium install ntfy`.
