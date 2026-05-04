# Standard Notes

**Image**: `standardnotes/server:latest`
**Port**: 3000 (nginx reverse proxy)
**Database**: MariaDB (`podium-mariadb`, dedicated user required)
**Credentials**: Register with the Standard Notes desktop/mobile app

## Key Notes
- Uses MariaDB (not PostgreSQL) — set `DB_TYPE=mysql`.
- Requires a dedicated MariaDB user (root login fails): create `standard_notes` user with privileges on `standard_notes` database.
- Requires multiple JWT secrets: `AUTH_JWT_SECRET`, `AUTH_SERVER_ENCRYPTION_SERVER_KEY`, `VALET_TOKEN_SECRET`, `AUTH_PSEUDO_KEY_PARAMS_KEY` — all random hex strings.
- This is a sync server; the UI is the Standard Notes desktop/mobile app. Connect it to `http://standard-notes/` as the server URL.
- The installer exists: run `podium install standard-notes`.
