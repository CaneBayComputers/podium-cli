# Uptime Kuma

Uptime Kuma is distributed as the prebuilt Docker image `louislam/uptime-kuma:1`.
The source repo at `louislam/uptime-kuma` does **not** ship a root-level
`docker-compose.yaml`, and building from source is heavy (Vue 3 frontend +
Node backend, full `npm install` + `npm run build`). Do **not** clone the source
or run `podium new`. Use the official image directly.

Uptime Kuma listens on port **3001**, not port 80. To make it reachable at
`http://uptime-kuma/`, add an nginx reverse proxy on port 80 that proxies
to `uptime-kuma:3001`. The nginx config **must** include WebSocket upgrade
headers — Uptime Kuma uses Socket.IO for live status updates and breaks
without them.

Uptime Kuma uses SQLite by default and stores all data under `/app/data`.
No external database is needed; ignore Podium's shared MariaDB/Postgres for
this project. Persist `/app/data` via a named Docker volume.

## Setup workflow

1. `mkdir -p ~/podium-projects/uptime-kuma`
2. Write `docker-compose.yaml` (see below) and `nginx.conf` (see below) into
   that directory.
3. `cd ~/podium-projects/uptime-kuma && podium setup uptime-kuma --no-startup`
   — Podium detects the multi-service compose, identifies the nginx service
   as web-facing (port 80), and assigns it a static VPC IP automatically.
4. `podium up uptime-kuma`
5. Verify with `curl -sI http://uptime-kuma/` — expect a 302 redirect to
   `/dashboard`.

## docker-compose.yaml

```yaml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    restart: unless-stopped
    volumes:
      - uptime-kuma-data:/app/data
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: uptime-kuma
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - uptime-kuma

volumes:
  uptime-kuma-data:

networks:
  default:
    external: true
    name: podium-cli_vpc
```

The nginx service holds the `container_name: uptime-kuma` and the static
VPC IP, so `http://uptime-kuma/` resolves to the proxy. The backend service
runs without a fixed IP.

## nginx.conf

```nginx
server {
    listen 80;

    location / {
        proxy_pass http://uptime-kuma:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }
}
```

## Admin

- App: `http://uptime-kuma/`
- Dashboard: `http://uptime-kuma/dashboard`
- No default credentials — create the admin account on first visit.
