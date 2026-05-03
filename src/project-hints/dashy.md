# Dashy

Dashy is a self-hosted dashboard for all your apps distributed as `lissy93/dashy:latest`. It listens on port **8080** (not port 80). Use an nginx reverse proxy to expose it at port 80 and set `PORT=80` or proxy to 8080.

No external database is needed — configuration is stored in a YAML file. Persist `/app/user-data` with a named volume.

## Setup workflow

1. `mkdir -p ~/podium-projects/dashy`
2. Write `docker-compose.yaml` and `nginx.conf` (see below).
3. `cd ~/podium-projects/dashy && podium setup dashy --no-startup`
4. `podium up dashy`
5. Verify: `curl -sI http://dashy/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  dashy-app:
    image: lissy93/dashy:latest
    restart: unless-stopped
    environment:
      NODE_ENV: production
    volumes:
      - dashy-data:/app/user-data
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: dashy
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - dashy-app

volumes:
  dashy-data:

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
        proxy_pass http://dashy-app:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Admin

- URL: `http://dashy/`
- No login required by default. Configure via the UI or by editing `conf.yml` in the volume.
