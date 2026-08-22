# Kanboard

Kanboard is distributed as `kanboard/kanboard:latest`. It is a Kanban project management tool that serves on port **80** — no nginx proxy needed.

No external database is needed — Kanboard uses SQLite by default. Persist `/var/www/app/data` with a named volume.

## Setup workflow

1. `mkdir -p ~/zeltro-projects/kanboard`
2. Write `docker-compose.yaml` (see below).
3. `cd ~/zeltro-projects/kanboard && zeltro setup kanboard --no-startup`
4. `zeltro up kanboard`
5. Verify: `curl -sI http://kanboard/` — expect HTTP 200 or 302.

## docker-compose.yaml

```yaml
services:
  kanboard:
    image: kanboard/kanboard:latest
    container_name: kanboard
    restart: unless-stopped
    volumes:
      - kanboard-data:/var/www/app/data
      - kanboard-plugins:/var/www/app/plugins
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>

volumes:
  kanboard-data:
  kanboard-plugins:

networks:
  default:
    external: true
    name: zeltro-cli_vpc
```

## Admin

- URL: `http://kanboard/`
- Default credentials: `admin` / `admin`
