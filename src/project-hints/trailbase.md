# TrailBase

Rust/SQLite backend-as-a-service — typed REST APIs, auth, and JS/WASM endpoints, with an admin UI.

**Image**: `trailbase/trailbase:0.31.3`
**Port**: 4000 (via nginx proxy)
**Database**: None (its own SQLite in the `trailbase-depot` volume)
**Credentials**: admin@localhost / trailbase123 — admin UI at `http://trailbase/_/admin/`

## Key Notes
- TrailBase mints a *random* admin password on first boot and only ever prints it to the log. The entrypoint here resets it to a known value on every start, which is a no-op once the password already matches.
- `--depot` replaced the deprecated `--data-dir`; the entrypoint uses the new flag.
- `/` serves your own app, which is empty on a fresh depot, so nginx redirects the bare root to the admin UI.
- The installer exists: run `podium install trailbase`.
