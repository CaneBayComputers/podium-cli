# Actual Budget

**Image**: `actualbudget/actual-server:latest`
**Port**: 5006 (via nginx proxy)
**Database**: None (own file-based storage)
**Credentials**: Set server password on first visit (optional)

## Key Notes
- No external database needed — all data is stored in `/data`.
- Persist `/data` as a named volume.
- On first visit you can optionally set a server password to restrict access.
- The installer exists: run `podium install actual-budget`.
