# Homarr

Modern, drag-and-drop dashboard with integrations for the usual self-hosted stack.

**Image**: `ghcr.io/homarr-labs/homarr:v1.73.0` + `nginx:1.30.4-alpine`
**Port**: 7575 (behind the nginx reverse proxy on 80)
**Database**: None externally — SQLite at `/appdata/db/db.sqlite` in the `homarr-appdata` volume
**Credentials**: Created by the onboarding wizard on first visit

## Key Notes
- `SECRET_ENCRYPTION_KEY` (32 random bytes, hex) is mandatory — the container refuses to start without it, and rotating it makes every saved integration credential undecryptable.
- Homarr v1 runs its own Redis **inside** the container (`REDIS_IS_EXTERNAL=false` in the image defaults), so `podium-redis` is not used and must not be wired in.
- Docker-socket integration is not mounted here; add `/var/run/docker.sock:/var/run/docker.sock` yourself if you want the Docker widget.
- WebSockets are used for live widget updates — the `Upgrade`/`Connection` headers in the proxy are required.
- The installer exists: run `podium install homarr`.
