# Pydio Cells

Enterprise-style document sharing and collaboration platform (Go).

**Image**: `pydio/cells:5.0.2`
**Port**: 8080 (via nginx proxy)
**Database**: PostgreSQL (`podium-postgres`, user=root, password=password, db `pydio_cells`)
**Credentials**: `admin` / `admin123`

## Key Notes
- Cells serves **self-signed HTTPS on 8080 by default** — `CELLS_NO_TLS=1` is what switches it to plain HTTP so the proxy can talk to it. Pair with `CELLS_BIND=0.0.0.0:8080` and `CELLS_EXTERNAL=http://pydio-cells`.
- The browser installer is skipped by mounting an `install.yml` and pointing `CELLS_INSTALL_YAML` at it; the entrypoint rewrites `cells start` into `cells configure` on the first run and then serves. No init container.
- Copy the DSN shape exactly, including the `{{.Meta.prefix}}` / `{{.Meta.policies}}` / `{{.Meta.singular}}` template placeholders and `sslmode=disable` — Cells expands them itself.
- Cells does **not** create the database; `pydio_cells` must exist first.
- v5 supports PostgreSQL as a first-class primary DB (the docs page listing MySQL-only is stale v4 content). MongoDB is optional and only tested through v7 — leave it off.
- Heaviest app of the file-sync family: ~1-2 GB RAM, 30-60s first boot. Everything persists under `/var/cells`.
- The installer exists: run `podium install pydio-cells`.
