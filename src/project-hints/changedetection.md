# Changedetection.io

Changedetection.io is distributed as `ghcr.io/dgtlmoon/changedetection.io:latest`. It monitors websites for changes and listens on port **5000**. Use an nginx reverse proxy to expose it at port 80.

No external database is needed — data is stored in a datastore volume at `/datastore`.

## Setup workflow

1. `mkdir -p ~/podium-projects/changedetection`
2. Write `docker-compose.yaml` and `nginx.conf` (see below).
3. `cd ~/podium-projects/changedetection && podium setup changedetection --no-startup`
4. `podium up changedetection`
5. Verify: `curl -sI http://changedetection/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  changedetection-app:
    image: ghcr.io/dgtlmoon/changedetection.io:latest
    restart: unless-stopped
    environment:
      BASE_URL: http://changedetection
    volumes:
      - changedetection-data:/datastore
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: changedetection
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - changedetection-app

volumes:
  changedetection-data:

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
        proxy_pass http://changedetection-app:5000;
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

- URL: `http://changedetection/`
- No login required by default (can add password in settings).
