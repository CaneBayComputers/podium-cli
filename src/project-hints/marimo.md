# marimo

Reactive Python notebook — cells re-run automatically, notebooks are plain `.py` files.

**Image**: `ghcr.io/marimo-team/marimo:0.23.15-data`
**Port**: 8080 (via nginx proxy, WebSocket upgrade required)
**Database**: none
**Credentials**: none — the image's default command passes `--no-token`

## Key Notes
- Three image flavours exist per release: bare (`0.23.15`), `-data` (adds numpy/pandas/altair + recommended extras) and `-sql` (adds duckdb/SQL support). `-data` is the useful default.
- The default `CMD` already runs `marimo edit --no-token -p $PORT --host $HOST`; the `PORT`/`HOST` env vars are the supported way to steer it — overriding `command:` is unnecessary and easy to get wrong.
- The container runs as the non-root user `appuser` with WORKDIR `/app`. Only `/app/data` is on a volume, so notebooks saved elsewhere (e.g. `/app/notebook.py`) vanish on rebuild.
- The editor is WebSocket-driven — without `Upgrade`/`Connection` headers on nginx the UI loads but cells never execute.
- `marimo edit` allows arbitrary code execution by design; keep it on the local Podium network only.
- The installer exists: run `podium install marimo`.
