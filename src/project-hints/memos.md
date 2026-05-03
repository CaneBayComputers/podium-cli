# Memos

Memos is a lightweight self-hosted memo hub distributed as `neosmemo/memos:stable`. It listens on port **5230**. Use an nginx reverse proxy to expose it at port 80.

No external database is needed — Memos uses SQLite stored at `/var/opt/memos`. Persist this with a named volume.

## Setup workflow

1. `mkdir -p ~/podium-projects/memos`
2. Write `docker-compose.yaml` and `nginx.conf` (see below).
3. `cd ~/podium-projects/memos && podium setup memos --no-startup`
4. `podium up memos`
5. Verify: `curl -sI http://memos/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  memos-app:
    image: neosmemo/memos:stable
    restart: unless-stopped
    volumes:
      - memos-data:/var/opt/memos
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: memos
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - memos-app

volumes:
  memos-data:

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
        proxy_pass http://memos-app:5230;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Admin

- URL: `http://memos/`
- Create an account on first visit — the first user becomes admin.
