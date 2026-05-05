# Heimdall

Heimdall is an application dashboard distributed as `lscr.io/linuxserver/heimdall:2.7.6`. It serves on port **80** — no nginx proxy needed.

No external database is needed — Heimdall uses SQLite. Persist `/config` with a named volume.

## Non-obvious gotchas

- **`ALLOW_INTERNAL_REQUESTS=true`** is required if you want Heimdall to "ping" other Podium projects on the VPC (the default `false` blocks all RFC1918 destinations, including sibling project containers). Set it to `"true"` (quoted — it's read as a string).
- The `:latest` tag drifts. Pin to a specific stable like `2.7.6`. Never use `:latest` in committed installers.

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
    image: lscr.io/linuxserver/heimdall:2.7.6
    restart: unless-stopped
    environment:
      PUID: 1000
      PGID: 1000
      TZ: Etc/UTC
      ALLOW_INTERNAL_REQUESTS: "true"
    volumes:
      - heimdall-config:/config

volumes:
  heimdall-config:
```

`setup_project.sh` adds the `container_name`, the static IP on `podium-cli_vpc`, and the external network block.

## Admin

- URL: `http://heimdall/`
- No login required by default.
