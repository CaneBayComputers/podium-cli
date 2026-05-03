# Grocy

Grocy is a self-hosted household management ERP for groceries, distributed as `lscr.io/linuxserver/grocy:latest`. It serves on port **80** — no nginx proxy needed.

No external database is needed — Grocy uses SQLite. Persist `/config` with a named volume.

## Setup workflow

1. `mkdir -p ~/podium-projects/grocy`
2. Write `docker-compose.yaml` (see below).
3. `cd ~/podium-projects/grocy && podium setup grocy --no-startup`
4. `podium up grocy`
5. Verify: `curl -sI http://grocy/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  grocy:
    image: lscr.io/linuxserver/grocy:latest
    container_name: grocy
    restart: unless-stopped
    environment:
      PUID: 1000
      PGID: 1000
      TZ: UTC
    volumes:
      - grocy-config:/config
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>

volumes:
  grocy-config:

networks:
  default:
    external: true
    name: podium-cli_vpc
```

## Admin

- URL: `http://grocy/`
- Default credentials: `admin` / `admin`
