# CodiMD

Real-time collaborative Markdown editor (the community fork HedgeDoc also descends from it).

**Image**: `hackmdio/hackmd:2.6.1`
**Port**: 3000 (via nginx proxy)
**Database**: PostgreSQL `codimd` on podium-postgres
**Credentials**: Register on first visit — anonymous notes work without an account

## Key Notes
- The database is not optional. The entrypoint blocks on `pcheck -env CMD_DB_URL` and the container never starts without it.
- `CMD_SESSION_SECRET` matters more than it looks: the default is the literal string `secret`, which makes CodiMD generate a random one at every boot and log every user out on each restart.
- `CMD_HSTS_ENABLE=false` is set deliberately. HSTS is on by default and would pin browsers to https for this hostname, which Podium does not serve.
- Set `CMD_PROTOCOL_USESSL=true` only if you front it with real TLS. Never set `CMD_USESSL=true` — that makes CodiMD try to terminate TLS itself and crash on the missing key file.
- There is no admin account and no admin UI; every user self-registers.
- Uploads live at `/home/hackmd/app/public/uploads` (the image runs as uid/gid 1500).
- The installer exists: run `podium install codimd`.
