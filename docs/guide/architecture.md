---
title: Architecture
layout: default
nav_order: 9
---

# Architecture

---

## Shared services

One set of service containers serves every project on the machine.

| Service | Hostname | Port | User | Password |
|---|---|---|---|---|
| PostgreSQL | `podium-postgres` | 5432 | `root` | `password` |
| MariaDB / MySQL | `podium-mariadb` | 3306 | `root` | *(empty)* |
| Redis | `podium-redis` | 6379 | — | *(none)* |
| MongoDB | `podium-mongo` | 27017 | `root` | `password` |
| Memcached | `podium-memcached` | 11211 | — | *(none)* |
| MailHog | `podium-mailhog` | SMTP 1025 / UI 8025 | — | *(none)* |
| phpMyAdmin | `podium-phpmyadmin` | 80 | — | — |

### Optional shared services

Most projects need a database, which is what justifies the core services always running. Far fewer need object storage or a search engine, so those sit behind Docker Compose profiles and stay off until a machine asks for them — rather than every install paying that RAM to benefit a few.

```bash
podium enable-service minio
podium enable-service meilisearch
podium disable-service minio      # data volume is kept
```

Once enabled they start with every `podium up` and resolve by hostname from inside any project container, exactly like the core services. The enabled list persists in `OPTIONAL_SERVICES` in `/etc/podium-cli/.env`.

| Service | Host | Port | Credentials |
|---|---|---|---|
| MinIO | `podium-minio` | API 9000 / console 9001 | `root` / `password` |
| Meilisearch | `podium-meilisearch` | 7700 | master key `podium-dev-master-key` |

Use these hostnames and credentials directly when configuring a project — there's no need to inspect containers to discover them. Podium writes them into each project's `.env` automatically.

---

## Two-layer hostname resolution

Every project is reachable at `http://<project-name>/` from two directions, using one naming scheme:

- **Host → project.** Podium adds an `/etc/hosts` entry (`10.x.x.219  my-api`). Your browser and host tooling use this.
- **Container → container.** Docker's embedded DNS resolves container names on the shared network. Code inside a project can `psql -h podium-postgres` or `fetch('http://other-project/')` with no extra configuration.

Ports only matter when reaching a project from *another machine* on your LAN, where each project also gets a mapped port (`http://192.168.1.20:219`).

---

## VPC and IP allocation

All Podium containers attach to the `podium-cli_vpc` Docker network (`${VPC_SUBNET}.0/24`, set per machine in `/etc/podium-cli/.env`). The address space is partitioned so static IPs never collide with dynamic ones:

| Range | Purpose | Allocation |
|---|---|---|
| `.2`–`.15` | Shared services (core `.2`–`.8`, optional `.9`–`.15`) | Static |
| `.32`–`.63` | Helper containers (workers, schedulers) | Dynamic |
| `.100`–`.250` | Project entry points | Static, assigned per project |

Writing a custom compose: give the web-facing service a static IP in `.100`–`.250`, leave helpers without `ipv4_address`, and never touch `.2`–`.8`.

---

## Base images

Greenfield projects build from one of three images on Docker Hub under `canebaycomputers/cbc`. Each runs nginx + supervisor on Ubuntu Noble. Sources live in [`CaneBayComputers/docker-images`](https://github.com/CaneBayComputers/docker-images), one directory per image.

Override the default with `--image <ref>` on `new`, `clone`, `setup` or `install`.

### `cbc:nginx-php8` — PHP projects

- nginx with FastCGI to `php-fpm8.3` over a Unix socket; web root `/usr/share/nginx/html/public`
- PHP 8.3 with `pdo_mysql`, `pdo_pgsql`, `pdo_sqlite`, `redis`, `mongodb`, `gd`, `intl`, `mbstring`, `imagick`, `zip`, `soap`, `xdebug`, plus `php-codesniffer` and `phpmd`
- Supervisor runs nginx, php-fpm and a Laravel queue worker (4 processes, autostart)

### `cbc:nginx-python3` — Python projects

- nginx reverse proxy, port 80 → `localhost:8000`, with WebSocket upgrade headers
- Preinstalled: `fastapi`, `uvicorn`, `django`, `flask`, `gunicorn`, `python-dotenv`, `sqlalchemy`, `psycopg2-binary`, `PyMySQL`, `pymongo`, `redis`, `pymemcache`
- Supervisor runs `PYTHON_APP_COMMAND`; the app must bind port 8000
- `python3` is available; `python` is not

### `cbc:nginx-node` — Node projects

- nginx reverse proxy, port 80 → `localhost:3000`, with WebSocket upgrade headers
- Node 22 LTS
- Supervisor runs `NODE_APP_COMMAND`; the app must bind port 3000. Set `PORT=3000` in `.env` for frameworks that default elsewhere.

{: .note }
Project containers are **recreated from the base image on every `podium up`**. Anything installed into a running container's filesystem is lost — only the bind-mounted project directory survives. That's why every framework's runtime is baked into the image, and why a SQLite database must live in the project directory.

---

## Compose adaptation

When `podium clone` or `podium setup` meets a `docker-compose.yaml` with more than one service or a non-cbc image, Podium adapts it:

- Bundled `postgres` / `mysql` / `mariadb` / `redis` / `valkey` / `mongodb` services are removed, and env vars referencing them are repointed at the shared hostnames
- The web-facing service gets a static VPC IP and a `container_name` matching the project
- Other services attach to the network without a fixed IP
- The original is preserved as `docker-compose.upstream.yaml` (first run only, so the true original survives re-runs)
- `docker-compose.yaml` is added to `.gitignore`, so the Podium-managed file isn't committed back to a shared repo

Image type only affects this adaptation. **Framework steps — dependency install, `.env` wiring, storage symlink, migrations — are driven by framework detection** and run for adapted projects too.

Useful flags: `--no-startup` to review the adapted compose before it boots, `--overwrite-env` to repoint an existing app's `.env` at the shared services while preserving `APP_KEY`, `--db-name <name>` to pick the database, `--no-migration` to skip migrations.

---

## Project layout

```
~/podium-projects/
├── my-api/
│   ├── docker-compose.yaml          # Podium-managed (gitignored)
│   ├── docker-compose.upstream.yaml # the original, if there was one
│   ├── AGENTS.md                    # hand-off context for AI agents
│   ├── .env
│   └── [your project files]
└── my-shop/
```

Runtime configuration lives in `/etc/podium-cli/.env`.
