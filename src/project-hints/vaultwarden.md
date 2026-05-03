# Vaultwarden

Vaultwarden is an unofficial Bitwarden-compatible password manager server, distributed as `vaultwarden/server:latest`. It serves its own web vault on port **80** — no nginx proxy needed.

No external database is needed — Vaultwarden uses SQLite stored at `/data`. Persist this with a named volume.

## Setup workflow

1. `mkdir -p ~/podium-projects/vaultwarden`
2. Write `docker-compose.yaml` (see below).
3. `cd ~/podium-projects/vaultwarden && podium setup vaultwarden --no-startup`
4. `podium up vaultwarden`
5. Verify: `curl -sI http://vaultwarden/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    environment:
      WEBSOCKET_ENABLED: "true"
      SIGNUPS_ALLOWED: "true"
    volumes:
      - vaultwarden-data:/data
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>

volumes:
  vaultwarden-data:

networks:
  default:
    external: true
    name: podium-cli_vpc
```

## Admin

- URL: `http://vaultwarden/`
- No default credentials — create an account on first visit.
- Admin panel: `http://vaultwarden/admin` (requires `ADMIN_TOKEN` env var to enable).
