# AGENTS.md

> Reference for agents *using* Podium to install, build, or deploy projects on this machine.
> If you're modifying Podium's source itself, see [DEVELOPMENT.md](DEVELOPMENT.md).

This is the boiled-down version of `README.md` — same facts, no marketing, optimized for fast agent context loading. Read this and run `podium --help` and you have everything you need to use Podium effectively.

---

## Design Context: What Podium Optimizes For

Podium is infrastructure for **multi-project local dev** and **AI-driven workflows**, not a single-app framework. Lean into these properties when working with it:

- **Shared services over bundled.** One `podium-postgres` / `podium-mariadb` / `podium-redis` / `podium-mongo` / `podium-memcached` serves N projects instead of N projects each spinning up their own. Cuts RAM from ~700MB of redundant DB containers down to ~100MB and eliminates port collisions.
- **Hostname-based routing, both layers.** The host's `/etc/hosts` resolves `http://<project>/` for browsers; Docker's embedded DNS resolves `podium-postgres`/`podium-redis`/sibling-project names from inside containers. Both layers share one naming scheme.
- **Stable platform for AI agents.** Each "yo install <app>" session that has to rediscover networking, ports, secret generation, and shared services from scratch burns tokens reinventing what Podium already encodes. Reach for `podium install <app>` first; only hand-roll a compose if no installer exists.

**Where Podium does not add value**: single-project devs. Upstream `docker compose up` works fine for them.

---

## Commands You'll Use Most

| Command | Purpose |
|---|---|
| `podium install <app>` | Install a curated OSS app (`--list` to see all). Always check this first before hand-rolling anything. |
| `podium new <name> --framework <type>` | Greenfield project on a cbc base image (`laravel`, `wordpress`, `php`, `fastapi`, `django`, `python`, `express`, `nestjs`, `fastify`, `node`). |
| `podium clone <repo>` | Clone a Git repo and adapt its compose to use Podium shared services. |
| `podium up [name\|--all]` | Start a project. With no arg: interactive picker. With `--all`: every project. Shared services always start. |
| `podium down [name\|--all]` | Stop a project. With no arg: interactive picker. With `--all`: every project + shared services. |
| `podium setup [name]` | Adapt a project directory in `~/podium-projects/`. Interactive picker if name omitted. |
| `podium remove [name] --force-db-delete` | Tear down a project including its DB. Interactive picker if name omitted. |
| `podium status [name]` | Show running state. |
| `podium exec <cmd>` | Run a command inside the project container, no TTY (automation-friendly). Run from the project directory. |

For automation, prefer `podium exec` / `podium exec-root` over interactive variants (`podium bash`, `podium tinker`, `podium exec-tty*`) — those allocate a TTY and aren't agent-friendly. `podium exec` accepts either separate arguments (`podium exec python3 manage.py migrate`) or a single quoted string (`podium exec "python3 manage.py migrate"`).

For Django: prefer `podium django manage <args>` over `podium exec python3 manage.py <args>`. Python containers provide `python3`, not `python` — never `podium exec python …`.

To restart processes inside a running container use `podium supervisor restart all` (run from the project directory). Never use `podium exec supervisorctl …` — that runs as the developer user and gets permission denied on the supervisor socket.

Never pass `--json-output` to `podium new` from an automation context — it suppresses all output, so success and errors both look identical.

---

## Shared Service Credentials

Use these hostnames + credentials when configuring projects. Do not inspect containers to derive them.

| Service | Host | Port | User | Password |
|---|---|---|---|---|
| PostgreSQL | `podium-postgres` | 5432 | `root` | `password` |
| MariaDB / MySQL | `podium-mariadb` | 3306 | `root` | *(empty)* |
| Redis | `podium-redis` | 6379 | — | *(none)* |
| MongoDB | `podium-mongo` | 27017 | `root` | `password` |
| Memcached | `podium-memcached` | 11211 | — | *(none)* |
| MailHog | `podium-mailhog` | SMTP 1025 / UI 8025 | — | *(none)* |

---

## VPC Networking & IP Allocation

All Podium containers attach to the `podium-cli_vpc` Docker network (subnet `${VPC_SUBNET}.0/24`, configured per machine in `/etc/podium-cli/.env`). The address space is partitioned to keep static IPs from colliding with dynamic allocations:

| Range | Purpose | Allocation |
|---|---|---|
| `.2`–`.8` | Shared services (`podium-mariadb`, `podium-phpmyadmin`, `podium-mongo`, `podium-redis`, `podium-postgres`, `podium-memcached`, `podium-mailhog`) | Static via `ipv4_address` |
| `.32`–`.63` | Helper containers in multi-service projects (workers, schedulers, internal services) | Dynamic via `ip_range: ${VPC_SUBNET}.32/27` |
| `.100`–`.250` | Project entry-points (the web-facing service, addressable as `http://<project>/`) | Static, randomly assigned per project |

When writing a custom compose: give the entry-point service a static IP in `.100`–`.250`, leave helper services without `ipv4_address` so they land in `.32`–`.63`, and never touch `.2`–`.8`.

### Two-layer hostname resolution

- **Host → project**: `/etc/hosts` entries (`10.x.x.219    typebot`). Browsers and host-side tooling use this.
- **Container → container**: Docker's embedded DNS resolves container names automatically as long as both ends are on `podium-cli_vpc`. Frameworks inside a project container can `psql -h podium-postgres` or `fetch('http://other-project/')` without any extra config.

---

## cbc Base Docker Images

Greenfield projects (`podium new`) build from one of three cbc base images on Docker Hub under `canebaycomputers/cbc`. Each runs nginx + supervisor on Ubuntu Noble. Source repos live under `CaneBayComputers/` on GitHub.

### `canebaycomputers/cbc:nginx-node` — Node.js projects
- **GitHub**: `CaneBayComputers/cbc-docker-node-nginx`
- **nginx**: Reverse proxy, port 80 → `localhost:3000`. WebSocket upgrade headers included.
- **App startup**: Supervisor runs `/usr/local/bin/start-node-app.sh`. If `NODE_APP_COMMAND` is set, it `cd`s to `/usr/share/nginx/html`, sources `.env`, and execs the command. If unset, the process sleeps.
- **Web root**: `/usr/share/nginx/html`
- **Node version**: 22 LTS
- **Key note**: App must bind to port 3000. Set `PORT=3000` in `.env` for frameworks that default elsewhere (e.g. Strapi defaults to 1337).

### `canebaycomputers/cbc:nginx-python3` — Python projects (FastAPI, Django)
- **GitHub**: `CaneBayComputers/cbc-docker-python3-nginx`
- **nginx**: Reverse proxy, port 80 → `localhost:8000`. Passes `Host $host`, WebSocket upgrade headers included.
- **App startup**: Supervisor runs `/usr/local/bin/start-python-app.sh`. If `PYTHON_APP_COMMAND` is set, `cd`s to `/usr/share/nginx/html`, sources `.env`, execs. If unset, sleeps.
- **Web root**: `/usr/share/nginx/html`
- **Key note**: App must bind to port 8000. `python3` is available; `python` is not.

### `canebaycomputers/cbc:nginx-php8` — PHP projects (Laravel, WordPress)
- **GitHub**: `CaneBayComputers/cbc-docker-php8-nginx`
- **nginx**: FastCGI (not reverse proxy). Web root is `/usr/share/nginx/html/public`. PHP requests pass to `php-fpm8.3` via Unix socket.
- **PHP version**: 8.3
- **Supervisor programs**: `nginx`, `php-fpm`, `laravel-worker` (queue worker, `autostart=true`, runs 4 processes as `www-data`)
- **Key note**: Laravel queue worker autostarts. The app is served via php-fpm directly with no startup script needed.

---

## Writing Installers

Installers in `src/installers/<slug>.sh` are the curated knowledge for popular OSS apps. When `podium install <app>` runs, it sources the installer, calls optional `pre_install()` and required `write_files()`, then runs `podium setup` + `podium up`.

### Format

```bash
INSTALL_DISPLAY="<Pretty Name>"
INSTALL_CREDENTIALS="<initial login or 'register at first visit'>"
INSTALL_NOTES="<one-line gotcha or empty>"

# Optional: runs before write_files(). Use for DB creation, secret generation that needs the DB up.
pre_install() {
    docker exec -e PGPASSWORD=password podium-postgres \
        psql -U root -d postgres -c "CREATE DATABASE \"<slug>\";" 2>/dev/null || true
}

# Required: runs in the project directory. Generate secrets, write docker-compose.yaml, .env, etc.
write_files() {
    cat > docker-compose.yaml << COMPOSE
services:
  app:
    image: vendor/app:1.2.3
    # ... use shared-service hostnames; never bundle a postgres/mysql/redis ...
COMPOSE
}
```

### Conventions

- **Pin every image tag.** No `:latest`. Bumps must be intentional — they break backups and reproducibility silently otherwise.
- **Replace bundled DBs with shared services.** Rewrite the upstream's bundled `postgres`/`mysql`/`mariadb`/`redis`/`mongo`/`memcached` services to point at the shared hostnames.
- **Name the entry-point service** so `setup_project.sh`'s web detection picks it up: one of `nginx`, `web`, `app`, `api`, `server`, `frontend`, `backend`, `http`. Setup will assign it the project's static IP and `container_name`.
- **Helper services** (workers, schedulers, sidekiq) attach to the default network without `ipv4_address` — they land in `.32`–`.63`.
- **Generate secrets** via `openssl rand -hex 32` (or whatever the upstream expects).
- **Pick a slug**: lowercase hyphenated. Becomes the filename, project URL (`http://<slug>/`), and DB name (with hyphens → underscores).

### Reference installers

When writing a new installer, find 2-3 existing ones with similar shape:
- Postgres + Redis: `paperless-ngx.sh`, `outline.sh`, `hedgedoc.sh`
- Bundled stack with multiple services: `mastodon.sh`, `zulip.sh`, `plane.sh`, `dify.sh`
- nginx reverse proxy in front of a non-port-80 app: `zulip.sh`, `mastodon.sh`

---

## Project Hints Library

`src/project-hints/<slug>.md` files contain non-obvious setup notes for specific OSS projects. The `podium create` agent reads these before starting any named project install.

- **When to add**: testing a real install reveals a recurring stumbling block (wrong default port, mandatory env var, unusual init sequence).
- **What belongs**: only things an agent would reliably get wrong without guidance. Short. Sections: brief description, `**Image**` / `**Port**` / `**Database**` / `**Credentials**`, then `## Key Notes` with non-obvious gotchas. End with: ``The installer exists: run `podium install <slug>`.``
- **What does NOT belong**: framework-general advice, steps the agent can infer from the project docs, workarounds for bugs since fixed.

---

## Complex Compose Adaptation

When `podium clone` or `podium setup` encounters a `docker-compose.yaml` with more than one service or non-cbc images, Podium adapts it:

- Bundled DB/cache services (`postgres`, `mysql`/`mariadb`, `redis`/`valkey`, `mongodb`) are removed.
- Env var references are rewritten to the Podium shared hostnames.
- The web-facing service gets a static IP on `podium-cli_vpc` and a `container_name` matching the project name.
- Other services (workers, schedulers) attach to `podium-cli_vpc` without a fixed IP.
- The container is **not auto-started** — review the generated `docker-compose.yaml` before `podium up <project>`.

After `podium clone` of a complex project, the agent's checklist:

1. Read the generated `docker-compose.yaml` to verify the adaptation. Check the correct web-facing service was identified, that env vars use Podium shared hostnames, and that the entry-point listens on port 80 (or note the port for the URL).
2. Read the project's config files (`.env`, `configuration/`) and update any hostnames still referencing removed services.
3. If the web-facing service uses a non-80 port (e.g. 8080), either front it with a small `nginx:alpine` reverse proxy in the compose, or note that the URL needs the port (e.g. `http://project-name:8080/`).
4. `podium up <project>` and verify with `curl -sI http://<project>/`.

### Upstream compose preservation

Whenever the project already had a `docker-compose.yaml`, `setup_project.sh`:
- Copies the original to `docker-compose.upstream.yaml` (first run only — never overwrites a previous backup, so the true original survives across re-runs).
- Appends `docker-compose.yaml` to `.gitignore` (idempotent), so a Podium dev doesn't commit the Podium-mangled compose back to a shared repo.

Greenfield projects (no existing compose) are unaffected.

---

## Installer Maintenance Strategy

Installers ship hand-written compose snippets, env vars, secret-generation steps, and integration glue. Upstream apps drift over time — installers can rot silently.

The maintenance loop:

1. **Pin image versions** — bumps are intentional events.
2. **Scheduled end-to-end test runs** on the test fleet via `tests/installers-<machine>.sh`. Loud signal when an installer + its pinned image stops working.
3. **AI-assisted reconciliation** via `podium update-installer <app>` (or `--all`). Emits a pre-built prompt that tells an agent to fetch upstream, diff against our installer, regenerate, run end-to-end, commit.

`podium create-installer "<plain English description>"` does the same for a brand-new installer: agent identifies the project, writes the installer + hint, runs `podium install`, commits when verified.

The structured installer format (`INSTALL_DISPLAY`, `INSTALL_CREDENTIALS`, `INSTALL_NOTES`, `pre_install()`, `write_files()`) is intentionally easy for an agent to regenerate.

---

## Shell Script Gotchas

Installers are shell scripts sourced by `install.sh`, which runs under `set -e`. A few non-obvious traps:

- **`tput` exits non-zero when `$TERM` is unset** (plain `ssh host cmd` without `-t`). `functions.sh` auto-detects this and forces `NO_COLOR=1`. Don't call `tput` directly without a guard.
- **`trash-put` refuses to overwrite an existing trash entry.** `remove_project.sh` renames with a timestamp suffix to avoid collisions. If you trash files in a script, do the same.

Never disable `set -e` to work around these. Wrap fragile commands in `if !` / `|| true` or detect the failure mode upfront.
