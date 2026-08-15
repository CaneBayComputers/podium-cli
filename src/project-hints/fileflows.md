# FileFlows

**Image**: `revenz/fileflows:26.07`
**Port**: 5000 (via nginx proxy)
**Database**: none shared — everything lives in `/app/Data`
**Credentials**: None by default; optional OIDC can be configured in the UI

## Key Notes
- Server-only deployment: **no docker socket, no privileged mode, no host networking**. The socket in upstream's example is for DockerMods and sibling processing nodes, not for the server to boot.
- The container runs as root and its entrypoint does chown/chmod work, so don't add `no-new-privileges` or force a non-root user.
- Volumes that matter: `/app/Data` (config + library database, must persist), `/app/Logs`, `/temp` (scratch), and `/media` for the files being processed. Put your media in the `fileflows-media` volume — the processing library is configured against paths *inside* the container.
- `TempPathHost` is only needed once you spawn sibling containers over the docker socket; it is not required here.
- The dashboard uses SignalR over WebSockets for live status, so the proxy needs `proxy_http_version 1.1` plus upgrade headers or the UI hangs on "connecting".
- Health endpoint is `GET /frasier`. The undocumented `FFPORT` env var changes the internal listen port — leave it unset for 5000.
- The image is roughly 1 GB compressed; the first `podium install` spends most of its time pulling.
- The installer exists: run `podium install fileflows`.
