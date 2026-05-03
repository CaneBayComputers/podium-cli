# Heimdall

Heimdall is an application dashboard distributed as `lscr.io/linuxserver/heimdall:latest`. It serves on port **80** — no nginx proxy needed.

No external database is needed — Heimdall uses SQLite. Persist `/config` with a named volume.

## Setup workflow

1. `mkdir -p ~/podium-projects/heimdall`
2. Write `docker-compose.yaml` (see below).
3. `cd ~/podium-projects/heimdall && podium setup heimdall --no-startup`
4. `podium up heimdall`
5. Verify: `curl -sI http://heimdall/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  heimdall:
    image: lscr.io/linuxserver/heimdall:latest
    container_name: heimdall
    restart: unless-stopped
    environment:
      PUID: 1000
      PGID: 1000
      TZ: UTC
    volumes:
      - heimdall-config:/config
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>

volumes:
  heimdall-config:

networks:
  default:
    external: true
    name: podium-cli_vpc
```

## Admin

- URL: `http://heimdall/`
- No login required by default.
