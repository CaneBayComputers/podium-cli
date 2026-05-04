# Audiobookshelf

**Image**: `ghcr.io/advplyr/audiobookshelf:latest`
**Port**: 80 (direct — no nginx proxy needed)
**Database**: SQLite (embedded)
**Credentials**: Set on first visit (create admin account)

## Key Notes
- Single-service compose — assigns the VPC IP directly to the `audiobookshelf-app` container.
- No environment variables required for basic operation.
- Persist four named volumes: `audiobookshelf-config` (`/config`), `audiobookshelf-metadata` (`/metadata`), `audiobookshelf-audiobooks` (`/audiobooks`), `audiobookshelf-podcasts` (`/podcasts`).
- Add audiobooks/podcasts to the named volumes, then create libraries pointing to those paths in the UI.
- The installer exists: run `podium install audiobookshelf`.
