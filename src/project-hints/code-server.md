# Code-Server

**Image**: `codercom/code-server:latest`
**Port**: 8080 (nginx reverse proxy)
**Database**: None
**Credentials**: Password: codeserver123

## Key Notes
- Set `PASSWORD=codeserver123` env var. No username required.
- nginx must include WebSocket upgrade headers (`Upgrade`, `Connection`) for the terminal to work.
- Workspace persisted in `code-server-workspace` volume at `/home/coder/project`.
- The installer exists: run `podium install code-server`.
