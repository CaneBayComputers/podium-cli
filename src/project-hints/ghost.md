# Ghost

Ghost 5 does **not** support MariaDB. Use SQLite (development) or PostgreSQL (production).
Podium's shared database is MariaDB, so always set `database__client: sqlite3` for local dev.

Ghost's official Docker image listens on port **2368**, not port 80. To make it accessible
via the standard Podium URL (`http://ghost/`), add an nginx reverse-proxy service to the
docker-compose, or document that the local URL is `http://ghost:2368/`.

## Recommended docker-compose structure

```yaml
services:
  ghost:
    image: ghost:5-alpine
    container_name: ghost
    restart: unless-stopped
    environment:
      url: http://ghost
      NODE_ENV: development
      database__client: sqlite3
      database__connection__filename: /var/lib/ghost/content/data/ghost.db
      database__useNullAsDefault: "true"
    volumes:
      - ghost-content:/var/lib/ghost/content
    networks:
      podium-cli_vpc:

  nginx:
    image: nginx:alpine
    container_name: ghost-nginx
    restart: unless-stopped
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      podium-cli_vpc:
        ipv4_address: <ASSIGNED_IP>

volumes:
  ghost-content:

networks:
  podium-cli_vpc:
    external: true
```

Create `nginx.conf`:
```nginx
server {
    listen 80;
    location / {
        proxy_pass http://ghost:2368;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

The nginx service gets the static VPC IP; ghost runs without a fixed IP.

## Admin
- Admin panel: `http://ghost/ghost/`
- No default credentials — create the owner account on first visit.
