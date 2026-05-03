# Portainer CE

Portainer is distributed as `portainer/portainer-ce:latest`. It provides a Docker management UI on port **9000** (HTTP). Do **not** use port 9443 (HTTPS) — it is unnecessary for local Podium use.

**Critical requirement**: The container must mount the Docker socket:
`/var/run/docker.sock:/var/run/docker.sock:ro`

Without this mount, Portainer cannot see or manage containers.

Portainer stores its data at `/data`. Persist this with a named volume.

No external database is needed. No nginx proxy is needed — use a single service on port 80 mapped to the container's port 9000.

## Setup workflow

1. `mkdir -p ~/podium-projects/portainer`
2. Write `docker-compose.yaml` (see below).
3. `cd ~/podium-projects/portainer && podium setup portainer --no-startup`
4. `podium up portainer`
5. Verify: `curl -sI http://portainer/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - portainer-data:/data
    ports:
      - "9000"
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>

volumes:
  portainer-data:

networks:
  default:
    external: true
    name: podium-cli_vpc
```

Because Portainer serves HTTP on port 9000 but the VPC resolves `http://portainer/` on port 80, add a port mapping or use the nginx proxy pattern below. The simplest approach is a minimal nginx proxy:

```yaml
services:
  portainer-app:
    image: portainer/portainer-ce:latest
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - portainer-data:/data
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: portainer
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - portainer-app

volumes:
  portainer-data:

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
        proxy_pass http://portainer-app:9000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Connection "";
    }
}
```

## Admin

- URL: `http://portainer/`
- No default credentials — create the admin account on first visit (must be done within 5 minutes of startup or the instance locks down).
