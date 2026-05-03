# Homer

**Image**: `b4bz/homer:latest`
**Port**: 8080 (via nginx proxy)
**Database**: None (YAML config file)
**Credentials**: None

## Key Notes
- Set `INIT_ASSETS=1` to generate the default config on first start.
- Persist `/www/assets` as a named volume — edit `assets/config.yml` to customize the dashboard.
- No authentication by default; add a reverse-proxy auth layer if needed.
- The installer exists: run `podium install homer`.
