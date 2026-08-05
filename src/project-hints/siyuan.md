# SiYuan

Block-based knowledge base with bidirectional links, running in browser-only mode.

**Image**: `b3log/siyuan:v3.7.3`
**Port**: 6806 (via nginx proxy)
**Database**: None (SQLite in the `siyuan-workspace` volume)
**Credentials**: No login — the lock screen is bypassed

## Key Notes
- The `serve` subcommand became mandatory in v3.7.0. Compose files copied from older guides that pass only `--workspace` will not start.
- The access auth code is deliberately absent. With one set, SiYuan answers `/` with a bare 401 JSON body rather than a login page, which fails Podium's readiness probe and looks broken in a browser. To lock it down, drop `SIYUAN_ACCESS_AUTH_CODE_BYPASS` and add `--accessAuthCode=<code>` to the command — but note a command-line auth code is written into `conf.json` and then *wins over* the bypass variable, so you cannot undo it by only changing the env.
- Use `PUID`/`PGID`, never `user:` — the entrypoint creates its own user at those ids.
- The proxy must pass `/ws` through for websockets and must not rewrite URLs; rewriting breaks SiYuan's auth.
- Docker builds are browser-only: no desktop/mobile app connections, and no PDF/HTML/Word export.
- `/` redirects to `/stage/build/desktop/`, which is normal.
- The installer exists: run `podium install siyuan`.
