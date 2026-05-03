# Trilium Notes

**Image**: `zadam/trilium:latest`
**Port**: 8080 (via nginx proxy)
**Database**: None (SQLite, file-based)
**Credentials**: Set password on first visit

## Key Notes
- Persist `/home/node/trilium-data` as a bind mount or named volume.
- First visit shows a setup page to set the login password.
- No external database or cache needed.
- The installer exists: run `podium install trilium`.
