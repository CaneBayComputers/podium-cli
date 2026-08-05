# BudgE

Open-source "budgeting with envelopes" personal finance app, in the spirit of YNAB / Aspire.

**Image**: `lscr.io/linuxserver/budge:0.0.9-ls189`
**Port**: 80 (serves HTTP directly — no proxy needed)
**Database**: none shared — SQLite at `/config/budge.db`
**Credentials**: Register on first visit

## Key Notes
- The upstream project is `linuxserver/budge`; the only maintained image is the LinuxServer.io one. Upstream calls it **alpha**.
- The LSIO nginx base listens on **80 and 443 in the same server block with no redirect**, so port 80 works as-is — the service can be named `web` directly instead of adding a proxy.
- LSIO's version tags are `<app-version>-ls<build>`; the app version has sat at `0.0.9` for a long time while the `ls###` build number keeps rolling. Pin the full `0.0.9-lsNNN` tag, not `latest`.
- `PUID`/`PGID` control ownership of `/config`; `TZ` affects budget month boundaries.
- The frontend proxies `/api/` to an internal Node backend on `localhost:5000` inside the same container — nothing extra to wire up.
- The installer exists: run `podium install budge`.
