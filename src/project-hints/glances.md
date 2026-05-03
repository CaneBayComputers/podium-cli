# Glances

**Image**: `nicolargo/glances:latest-full`
**Port**: 61208 (via nginx proxy)
**Database**: None
**Credentials**: None

## Key Notes
- Run in web server mode: set `GLANCES_OPT=-w`.
- Requires `pid: host` in the service definition so Glances can see all host processes.
- Mount `/var/run/docker.sock:/var/run/docker.sock:ro` to monitor Docker containers.
- curl HEAD (`-sI`) returns 405 for Glances — use `curl -s http://glances/` (GET) to verify 200.
- The installer exists: run `podium install glances`.
