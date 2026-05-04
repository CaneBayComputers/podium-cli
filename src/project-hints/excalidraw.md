# Excalidraw

**Image**: `excalidraw/excalidraw:latest`
**Port**: 80 (direct — no nginx proxy needed)
**Database**: None (client-side only, data stored in browser)
**Credentials**: None

## Key Notes
- Completely stateless — no database, no volumes, no env vars needed.
- Assigns the VPC IP directly to the `excalidraw-app` container (single-service compose).
- Collaboration features (live sharing) require the excalidraw-room and excalidraw-storage services — not included in the basic installer.
- The installer exists: run `podium install excalidraw`.
