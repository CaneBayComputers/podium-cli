# Mattermost

Clone the official Docker deployment repo: `https://github.com/mattermost/docker`
(not the main source repo `mattermost/mattermost-server`).

Mattermost listens on port **8065**, not port 80. You **must** add an nginx reverse proxy
with WebSocket upgrade headers — Mattermost uses WebSockets for real-time messaging and
breaks without them. The nginx service owns the static VPC IP; Mattermost runs without one.

Use the **Team Edition** image: `mattermost/mattermost-team-edition:<latest>`.
Use **PostgreSQL** — `podium-postgres` (host), port 5432, user `root`, password `password`.

## Setup workflow

1. `podium clone https://github.com/mattermost/docker mattermost --no-github`
2. Create the database: `docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE mattermost;"`
3. Replace `docker-compose.yaml` with the two-service stack below.
4. Create `nginx.conf` (see below).
5. `cd ~/podium-projects/mattermost && podium setup mattermost --no-startup`
6. `podium up mattermost`
7. Verify with `curl -sI http://mattermost/` — expect HTTP 200.

## docker-compose.yaml

```yaml
services:
  mattermost:
    image: mattermost/mattermost-team-edition:10
    container_name: mattermost-app
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp
    volumes:
      - mattermost-config:/mattermost/config:rw
      - mattermost-data:/mattermost/data:rw
      - mattermost-logs:/mattermost/logs:rw
      - mattermost-plugins:/mattermost/plugins:rw
      - mattermost-client-plugins:/mattermost/client/plugins:rw
      - mattermost-bleve-indexes:/mattermost/bleve-indexes:rw
    environment:
      TZ: UTC
      MM_SQLSETTINGS_DRIVERNAME: postgres
      MM_SQLSETTINGS_DATASOURCE: postgres://root:password@podium-postgres:5432/mattermost?sslmode=disable&connect_timeout=10
      MM_BLEVESETTINGS_INDEXDIR: /mattermost/bleve-indexes
      MM_SERVICESETTINGS_SITEURL: http://mattermost
      MM_SERVICESETTINGS_LISTENADDRESS: ":8065"
    networks:
      default:

  nginx:
    image: nginx:alpine
    container_name: mattermost
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      default:
        ipv4_address: <ASSIGNED_IP>
    depends_on:
      - mattermost

volumes:
  mattermost-config:
  mattermost-data:
  mattermost-logs:
  mattermost-plugins:
  mattermost-client-plugins:
  mattermost-bleve-indexes:

networks:
  default:
    external: true
    name: podium-cli_vpc
```

The `nginx` service holds `container_name: mattermost` and the static VPC IP. The
`mattermost` backend uses `container_name: mattermost-app` so nginx can resolve it by
that name.

## nginx.conf

```nginx
upstream backend {
    server mattermost-app:8065;
    keepalive 32;
}

server {
    listen 80;
    server_name _;

    client_max_body_size 100M;

    location ~ /api/v[0-9]+/(users/)?websocket$ {
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffers 256 16k;
        proxy_buffer_size 16k;
        client_body_timeout 60s;
        send_timeout 300s;
        lingering_timeout 5s;
        proxy_connect_timeout 90s;
        proxy_send_timeout 300s;
        proxy_read_timeout 90s;
        proxy_http_version 1.1;
        proxy_pass http://backend;
    }

    location / {
        proxy_set_header Connection "";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffers 256 16k;
        proxy_buffer_size 16k;
        proxy_read_timeout 600s;
        proxy_http_version 1.1;
        proxy_pass http://backend;
    }
}
```

## Admin

- URL: `http://mattermost/`
- No default credentials — create the System Admin account on first visit.
