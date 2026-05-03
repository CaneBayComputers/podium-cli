# Netdata

Netdata is distributed as `netdata/netdata:latest`. It collects system metrics and provides a real-time dashboard on port **19999**. Use an nginx reverse proxy to expose it at port 80.

**Critical requirements** — the following host paths must be bind-mounted read-only so Netdata can collect metrics:
- `/proc:/host/proc:ro`
- `/sys:/host/sys:ro`
- `/etc/passwd:/host/etc/passwd:ro`
- `/etc/group:/host/etc/group:ro`
- `/etc/os-release:/host/etc/os-release:ro`

Also required:
```yaml
cap_add:
  - SYS_PTRACE
security_opt:
  - apparmor:unconfined
```

No external database is needed. Persist Netdata's config and data with named volumes.

## Setup workflow

1. `mkdir -p ~/podium-projects/netdata`
2. Write `docker-compose.yaml` and `nginx.conf` (see below).
3. `cd ~/podium-projects/netdata && podium setup netdata --no-startup`
4. `podium up netdata`
5. Verify: `curl -sI http://netdata/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  netdata-app:
    image: netdata/netdata:latest
    restart: unless-stopped
    cap_add:
      - SYS_PTRACE
    security_opt:
      - apparmor:unconfined
    volumes:
      - netdata-config:/etc/netdata
      - netdata-lib:/var/lib/netdata
      - netdata-cache:/var/cache/netdata
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /etc/passwd:/host/etc/passwd:ro
      - /etc/group:/host/etc/group:ro
      - /etc/os-release:/host/etc/os-release:ro
    environment:
      - NETDATA_CLAIM_TOKEN=
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: netdata
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - netdata-app

volumes:
  netdata-config:
  netdata-lib:
  netdata-cache:

networks:
  default:
    external: true
    name: podium-cli_vpc
```

## nginx.conf

```nginx
server {
    listen 80;
    location / {
        proxy_pass http://netdata-app:19999;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## Admin

- URL: `http://netdata/`
- No login required by default — the dashboard is open.
