# Homepage

Highly configurable application dashboard with service widgets and bookmarks (gethomepage).

**Image**: `ghcr.io/gethomepage/homepage:v1.13.2` + `nginx:1.30.4-alpine`
**Port**: 3000 (behind the nginx reverse proxy on 80)
**Database**: None — YAML config files in the `homepage-config` volume
**Credentials**: None by default (no auth)

## Key Notes
- Since v1.0 `HOMEPAGE_ALLOWED_HOSTS` is **required** for any host other than `localhost`. It is set to `*` here; without it every page load returns a host-validation error.
- On first boot the container writes default `services.yaml`, `bookmarks.yaml`, `widgets.yaml`, `settings.yaml` into `/app/config` — edit those in the `homepage-config` volume, the app hot-reloads them.
- Docker-socket integration is deliberately not wired up; add `/var/run/docker.sock` yourself if you want container widgets.
- The installer exists: run `podium install homepage`.
