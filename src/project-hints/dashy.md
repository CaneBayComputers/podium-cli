# Dashy

Dashy is a self-hosted dashboard for all your apps distributed as `lissy93/dashy:latest`. It serves on port **80** — no nginx proxy needed.

No external database is needed — configuration is stored in a YAML file. Persist `/app/user-data` with a named volume.

## Setup workflow

1. `mkdir -p ~/podium-projects/dashy`
2. Write `docker-compose.yaml` (see below).
3. `cd ~/podium-projects/dashy && podium setup dashy --no-startup`
4. `podium up dashy`
5. Verify: `curl -sI http://dashy/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  dashy:
    image: lissy93/dashy:latest
    container_name: dashy
    restart: unless-stopped
    environment:
      NODE_ENV: production
    volumes:
      - dashy-data:/app/user-data
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>

volumes:
  dashy-data:

networks:
  default:
    external: true
    name: podium-cli_vpc
```

## Admin

- URL: `http://dashy/`
- No login required by default. Configure via the UI or by editing `conf.yml` in the volume.
