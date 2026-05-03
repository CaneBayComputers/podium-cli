# FreshRSS

FreshRSS is distributed as `freshrss/freshrss:latest`. It is an RSS aggregator that serves on port **80** — no nginx proxy needed.

No external database is needed — FreshRSS uses SQLite by default. Persist `/var/www/FreshRSS/data` with a named volume.

## Setup workflow

1. `mkdir -p ~/podium-projects/freshrss`
2. Write `docker-compose.yaml` (see below).
3. `cd ~/podium-projects/freshrss && podium setup freshrss --no-startup`
4. `podium up freshrss`
5. Verify: `curl -sI http://freshrss/` — expect HTTP 200 or 302.

## docker-compose.yaml

```yaml
services:
  freshrss:
    image: freshrss/freshrss:latest
    container_name: freshrss
    restart: unless-stopped
    environment:
      TZ: UTC
      CRON_MIN: "1,31"
    volumes:
      - freshrss-data:/var/www/FreshRSS/data
      - freshrss-extensions:/var/www/FreshRSS/extensions
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>

volumes:
  freshrss-data:
  freshrss-extensions:

networks:
  default:
    external: true
    name: podium-cli_vpc
```

## Admin

- URL: `http://freshrss/`
- Run the web installer on first visit to create admin account.
