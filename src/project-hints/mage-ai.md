# Mage AI

Notebook-style data pipeline tool (ETL/orchestration) — build blocks in Python, SQL or R and schedule them.

**Image**: `mageai/mageai:0.9.79`
**Port**: 6789 (via nginx proxy, WebSocket upgrade required)
**Database**: none required — Mage keeps its metadata in SQLite under `/home/src/mage_data`
**Credentials**: none (authentication is off unless `REQUIRE_USER_AUTHENTICATION=1` is set)

## Key Notes
- The command **must** be `/app/run_app.sh mage start <project>`; running `mage start` directly skips the image's init wrapper.
- `USER_CODE_PATH` has to match the project name in the command (`/home/src/podium_project`), otherwise the UI opens an empty project.
- Everything persistent lives under `/home/src` — that single volume covers both pipeline code and the metadata db.
- The editor and terminal use WebSockets; nginx needs the upgrade headers and a long read timeout.
- Set `REQUIRE_USER_AUTHENTICATION=1` if you want the login screen (default owner is `admin@admin.com` / `admin`).
- The installer exists: run `podium install mage-ai`.
