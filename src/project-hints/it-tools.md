# IT Tools

IT Tools is a collection of handy online utilities, distributed as `corentinth/it-tools:latest`. It is a static web app that serves on port **80** — no nginx proxy, no database, and no configuration needed. This is the simplest possible deployment.

## Setup workflow

1. `mkdir -p ~/zeltro-projects/it-tools`
2. Write `docker-compose.yaml` (see below).
3. `cd ~/zeltro-projects/it-tools && zeltro setup it-tools --no-startup`
4. `zeltro up it-tools`
5. Verify: `curl -sI http://it-tools/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  it-tools:
    image: corentinth/it-tools:latest
    container_name: it-tools
    restart: unless-stopped
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>

networks:
  default:
    external: true
    name: zeltro-cli_vpc
```

## Admin

- URL: `http://it-tools/`
- No login required.
