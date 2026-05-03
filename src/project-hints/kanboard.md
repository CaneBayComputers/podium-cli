# Kanboard

Kanboard is distributed as `kanboard/kanboard:latest`. It is a Kanban project management tool that serves on port **80** — no nginx proxy needed.

No external database is needed — Kanboard uses SQLite by default. Persist `/var/www/app/data` with a named volume.

## Setup workflow

1. `mkdir -p ~/podium-projects/kanboard`
2. Write `docker-compose.yaml` (see below).
3. `cd ~/podium-projects/kanboard && podium setup kanboard --no-startup`
4. `podium up kanboard`
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
    name: podium-cli_vpc
```

## Admin

- URL: `http://kanboard/`
- Default credentials: `admin` / `admin`
