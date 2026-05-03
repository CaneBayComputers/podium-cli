# Grafana

Grafana is distributed as `grafana/grafana:latest`. It listens on port **3000**. Use an nginx reverse proxy to expose it at port 80.

No external database is needed — Grafana uses SQLite by default. Persist `/var/lib/grafana` with a named volume.

## Setup workflow

1. `mkdir -p ~/podium-projects/grafana`
2. Write `docker-compose.yaml` and `nginx.conf` (see below).
3. `cd ~/podium-projects/grafana && podium setup grafana --no-startup`
4. `podium up grafana`
5. Verify: `curl -sI http://grafana/` — expect HTTP 200 or 302.

## docker-compose.yaml

```yaml
services:
  grafana-app:
    image: grafana/grafana:latest
    restart: unless-stopped
    environment:
      GF_SERVER_ROOT_URL: http://grafana/
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: admin
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: grafana
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - grafana-app

volumes:
  grafana-data:

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
        proxy_pass http://grafana-app:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Admin

- URL: `http://grafana/`
- Credentials: `admin` / `admin` (prompted to change on first login)
