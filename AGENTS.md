# Repository Guidelines

## Initial Context Acquisition

**Read the following files** to become acquainted with the codebase before making changes:

1. `src/scripts/functions.sh` – Shared helpers used across all scripts (echo wrappers, JSON output, sudo helpers, etc.).
2. `src/scripts/configure.sh` – Sets up Podium and the dev environment; good reference for conventions.

Each subcommand maps directly to `src/scripts/<command>.sh` (e.g. `podium clone` → `src/scripts/clone_project.sh`). Read the relevant script when working on a specific command.

> **Note**: `README.md` and `podium --help` are the user-facing docs — they describe how to *use* Podium, not how to develop it. Keep them in sync when adding or changing commands, but do not treat them as the primary source of architectural truth. That said, use `podium` commands freely when testing or validating changes — spinning up a project, running exec commands, checking output — just as a user would.

## Project Structure & Module Organization
- `src/podium` is the Bash entrypoint; it wires subcommands and shared helpers from `src/scripts/`.
- Keep command logic inside `src/scripts/`, grouping related workflows beside their support files.
- Docker Compose templates and defaults live in `src/docker-stack/`; update `env.example` when you add variables.
- Installer wrappers (`install-ubuntu.sh`, `install-mac.sh`) are the only scripts that should touch host package managers; route runtime logs to `logs/` instead of the repo root.
- Runtime configuration is resolved from `/etc/podium-cli/.env`; ship repo defaults via examples rather than committed secrets.

## Build, Test, and Development Commands
- Run the CLI just as `podium <command>`. Do not run CLI from `./src/podium`.
- Exercise automation outputs with `podium <command> --json-output` or any subcommand that feeds the GUI. Not all commands have this option so check help first.
- Use `podium test-json-output [case]` for regression coverage and `podium cleanup-test-environment` to tear down fixtures after ad hoc runs.
- Static analysis and linting commands run inside the project container and expect project-relative paths (from the project root, for example `app/Console/Commands/Foo.php`):
  - `podium phpcs <relative-path>` – Run PHPCS with the default ruleset.
  - `podium phpcbf <relative-path>` – Run PHPCBF with the default ruleset to auto-fix.
  - `podium phpmd <relative-path>` – Run PHPMD against a file using the default rules.
  - `podium php -l <relative-path>` – Run PHP lint against a file.

## Coding Style & Naming Conventions
- Author scripts with `#!/bin/bash`, `set -e`, four-space indentation, and snake_case helpers (`init_projects_dir`).
- Prefer extending the shared utilities in `functions.sh` so color handling, JSON quiet mode, and logging stay consistent.
- New commands should follow the existing verb-first naming (`podium cleanup-test-environment`) and reuse the echo wrappers instead of raw `echo`.
- `set -e` is mandatory but watch for surprise aborts from commands that fail in non-obvious environments. Known traps: `tput` exits non-zero when `$TERM` is unset (plain `ssh host cmd` without `-t`) — `functions.sh` auto-detects this and forces `NO_COLOR=1`; `trash-put` refuses to overwrite an existing trash entry — `remove_project.sh` renames with a timestamp suffix to avoid collisions. When using a command that can fail this way, wrap in `if !` / `|| true` or detect the failure mode upfront.

## AI / Automation Usage Notes
- For non-interactive runs (CI, agents, scripts), prefer the non-TTY container execution commands:
  - `podium exec <cmd>` / `podium exec-root <cmd>` – run inside the project container without allocating a TTY.
  - Avoid interactive REPL-style commands (`podium bash`, `podium tinker`, `podium exec-tty*`) in agents; keep those for human-operated terminals.
- `podium exec` accepts either separate arguments (`podium exec python3 manage.py migrate`) or a single quoted string (`podium exec "python3 manage.py migrate"`). Both forms work.
- Python containers provide `python3`, not `python`. Use `podium python <args>` or `podium exec python3 <args>`. Never `podium exec python ...`.
- For Django management commands use `podium django manage <args>` (e.g. `podium django manage startapp myapp`, `podium django manage migrate`). This is the preferred shorthand over `podium exec python3 manage.py <args>`.

## Testing Guidelines
- Add new coverage by extending `src/scripts/test_json_output.sh`; name scenarios after the command under test (`new_laravel_latest`).
- Keep Docker noise isolated by using the `podium_test_` prefixes and calling `cleanup-test-environment` within failure handlers.
- Capture debugging data with the `--debug` flag and attach the relevant portion of `/tmp/podium-cli-debug.log` to reviews when issues arise.

## Configuration & Security Notes
- Document new environment variables in `src/docker-stack/env.example` and keep defaults non-sensitive.
- Any credentials belong in `/etc/podium-cli/.env` or developer-specific overrides, never in tracked files or example data.

---

## Design Context: What Podium Optimizes For

Podium is infrastructure for **multi-project local dev** and **AI-driven workflows**, not a single-app framework. The codebase makes design decisions on those terms — when adding or refactoring features, ask whether the change preserves these properties:

- **Shared services over bundled**. One `podium-postgres` / `podium-mariadb` / `podium-redis` / `podium-mongo` / `podium-memcached` serves N projects instead of N projects each spinning up their own. Cuts RAM from ~700MB of redundant DB containers down to ~100MB and eliminates port collisions.
- **Hostname-based routing, both layers**. The host's `/etc/hosts` resolves `http://<project>/` for browsers; Docker's embedded DNS resolves `podium-postgres`/`podium-redis`/sibling-project names from inside containers. Both layers share one naming scheme so frameworks see a consistent hostname regardless of which side they're on.
- **Stable platform for AI agents**. Each "yo install <app>" session that has to rediscover networking, ports, secret generation, and shared services from scratch burns tokens reinventing what Podium already encodes. The installer + `setup_project.sh` adaptation logic captures that knowledge once so the agent can focus on the actual app.

**When Podium does not add value**: single-project devs. Upstream `docker compose up` works fine for them — bundled DBs, host port binds, no need for shared resources. Don't pitch Podium to that audience.

The cross-project communication side effect (project A `fetch('http://project-b/api')` directly) is a real but secondary benefit. The headline win is resource consolidation + a consistent mental model across machines (dingdong / cami / cassie).

---

## cbc Base Docker Images

Podium project containers are built from one of three cbc base images hosted on Docker Hub under `canebaycomputers/cbc`. Each image runs nginx + supervisor on Ubuntu Noble. The source repos are on GitHub under `CaneBayComputers/`.

### `canebaycomputers/cbc:nginx-node` — Node.js projects

- **GitHub**: `CaneBayComputers/cbc-docker-node-nginx`
- **nginx**: Reverse proxy, port 80 → `localhost:3000`. No `Host` header override (nginx uses `$proxy_host`). WebSocket upgrade headers included.
- **App startup**: Supervisor runs `/usr/local/bin/start-node-app.sh`. If `NODE_APP_COMMAND` env var is set, it `cd`s to `/usr/share/nginx/html`, sources `.env`, and execs the command. If unset, the process sleeps (container stays up, app does not run).
- **Web root**: `/usr/share/nginx/html`
- **Node version**: 22 LTS (via NodeSource)
- **Supervisor programs**: `nginx`, `node-app`
- **Key note**: App must bind to port 3000. Set `PORT=3000` in `.env` for frameworks that default to a different port (e.g. Strapi defaults to 1337).

### `canebaycomputers/cbc:nginx-python3` — Python projects (FastAPI, Django)

- **GitHub**: `CaneBayComputers/cbc-docker-python3-nginx`
- **nginx**: Reverse proxy, port 80 → `localhost:8000`. Passes `Host $host`, WebSocket upgrade headers included.
- **App startup**: Supervisor runs `/usr/local/bin/start-python-app.sh`. If `PYTHON_APP_COMMAND` env var is set, it `cd`s to `/usr/share/nginx/html`, sources `.env`, and execs the command. If unset, sleeps.
- **Web root**: `/usr/share/nginx/html`
- **Supervisor programs**: `nginx`, `python-app`
- **Key note**: App must bind to port 8000. `python3` is available; `python` is not.

### `canebaycomputers/cbc:nginx-php8` — PHP projects (Laravel, WordPress)

- **GitHub**: `CaneBayComputers/cbc-docker-php8-nginx`
- **nginx**: FastCGI (not reverse proxy). Web root is `/usr/share/nginx/html/public`. PHP requests pass to `php-fpm8.3` via Unix socket.
- **PHP version**: 8.3
- **Supervisor programs**: `nginx`, `php-fpm`, `laravel-worker` (queue worker, `autostart=true`, runs 4 processes as `www-data`)
- **Key note**: Laravel queue worker autostarts. No `NODE_APP_COMMAND` / `PYTHON_APP_COMMAND` equivalent — the app is served via php-fpm directly with no startup script needed.

### Rebuilding and publishing a cbc image

1. Edit the relevant file in the image's repo.
2. Commit and push the repo.
3. From the repo directory, run `sudo bash build_push.sh` — it builds, tags, and pushes to Docker Hub.
4. Existing running containers will not pick up the new image automatically; they need `podium down <name> && podium up <name>`.

---

## VPC Networking & IP Allocation

All Podium containers attach to the `podium-cli_vpc` Docker network (subnet `${VPC_SUBNET}.0/24`, configured per machine in `/etc/podium-cli/.env`). The address space is partitioned to keep static IPs (shared services, project entry-points) from colliding with dynamic allocations (helper containers in multi-service projects):

| Range | Purpose | Allocation |
|---|---|---|
| `.2`–`.8` | Shared services (`podium-mariadb`, `podium-phpmyadmin`, `podium-mongo`, `podium-redis`, `podium-postgres`, `podium-memcached`, `podium-mailhog`) | Static via `ipv4_address` in `src/docker-stack/docker-compose.services.yaml` |
| `.32`–`.63` | Helper containers in multi-service projects (workers, schedulers, internal services) | Dynamic via `ip_range: ${VPC_SUBNET}.32/27` |
| `.100`–`.250` | Project entry-points (the web-facing service, addressable as `http://<project>/`) | Static, randomly assigned per project (`D_CLASS=$((RANDOM % 151 + 100))` in `setup_project.sh`) |

The `ip_range` on the network is critical. Without it, Docker hands out dynamic IPs starting at `.2` and helper containers squat on `podium-mariadb`/`podium-postgres`/etc. whenever the shared services are temporarily down — blocking those services from coming back up. If you edit `src/docker-stack/docker-compose.services.yaml`, preserve the `ip_range` block.

Two-layer hostname resolution:
- **Host → project**: `/etc/hosts` entries written by `setup_project.sh` (`10.x.x.219    typebot`). Browsers and host-side tooling use this.
- **Container → container**: Docker's embedded DNS resolves container names automatically as long as both ends are on `podium-cli_vpc`. Frameworks inside a project container can `psql -h podium-postgres` or `fetch('http://other-project/')` without any extra config.

`/etc/podium-cli/docker-compose.yaml` is the deployed copy of `src/docker-stack/docker-compose.services.yaml`, copied once on first `podium configure`. It does not auto-resync on `podium update` — when you change the source, existing installs need a manual `sudo cp` and `docker network rm podium-cli_vpc` + `podium start-services` to pick up the new config.

---

## Complex Compose Adaptation

When `podium clone` or `podium setup` encounters an existing `docker-compose.yaml` that has more than one service or uses non-cbc images, it is considered a **complex project**. Podium automatically adapts the compose rather than replacing it:

- Bundled DB/cache services (`postgres`, `mysql`/`mariadb`, `redis`/`valkey`, `mongodb`) are removed.
- Environment variable references to those services are rewritten to the Podium shared hostnames (`podium-postgres`, `podium-mariadb`, `podium-redis`, `podium-mongo`).
- The web-facing service gets a static IP on `podium-cli_vpc` and a `container_name` matching the project name.
- All other services (workers, schedulers, etc.) are attached to `podium-cli_vpc` without a fixed IP.
- The container is **not auto-started** after setup, so the generated `docker-compose.yaml` can be reviewed and corrected before first boot.

This logic lives in `src/scripts/setup_project.sh`. The adaptation is a Python script embedded inline. If it fails (malformed YAML, edge case), it falls through silently and Podium generates a fresh cbc-template compose instead.

### Upstream compose preservation

Whenever the project already had a `docker-compose.yaml` (any complexity), `setup_project.sh`:
- Copies the original to `docker-compose.upstream.yaml` (first run only — never overwrites a previous backup, so the true original survives across re-runs).
- Appends `docker-compose.yaml` to the project's `.gitignore` (idempotent, with a comment pointing at the upstream sidecar). This keeps a Podium dev from accidentally committing the Podium-mangled compose back to a shared repo and breaking non-Podium teammates.
- Does **not** auto-run `git rm --cached docker-compose.yaml` — if the upstream compose was already tracked, the user still sees modifications in `git status` and can untrack it themselves if desired.

Greenfield projects (no existing compose, e.g. `podium new`) are unaffected — no `.upstream.yaml` and no `.gitignore` entry, since there's no team convention to preserve.

This is the lightweight version of a full sidecar pattern (where Podium would write its config to `docker-compose.podium.yaml` and run with `-f`). The full sidecar would require threading an alternate filename through `dockerup`/`dockerdown`/`startup.sh`/`shutdown.sh`/`status.sh`/the compose-type detection helpers — a couple-day refactor with edge cases (`extends`, projects already using `-f` chains). Revisit if `podium clone` of upstream repos becomes a dominant workflow.

**Shared service credentials** (use these when configuring projects — do not inspect containers):
| Service | Host | Port | User | Password |
|---|---|---|---|---|
| PostgreSQL | `podium-postgres` | 5432 | `root` | `password` |
| MariaDB/MySQL | `podium-mariadb` | 3306 | `root` | *(empty)* |
| Redis | `podium-redis` | 6379 | — | *(none)* |
| MongoDB | `podium-mongo` | 27017 | `root` | `password` |

---

## Project Hints Library

`src/project-hints/` contains per-project markdown files with non-obvious setup notes for known open-source projects. The `podium create` agent prompt instructs agents to check this directory before starting any named OSS project install.

**File naming**: lowercase hyphenated project slug, e.g. `strapi.md`, `netbox.md`, `ghost.md`.

**When to add a hints file**: when testing a real `podium create` install reveals a recurring stumbling block that can't be fixed at the infrastructure level (wrong default port, unusual directory requirement, mandatory env var, etc.).

**What belongs in a hints file**: only non-obvious things that an agent would reliably get wrong without guidance. Keep them short. Do not duplicate information already in the agent prompt or the project's own README.

**What does NOT belong**: framework-general advice (already in `create.sh`), steps the agent can infer from the project docs, or workarounds for bugs that have since been fixed in the cbc images or Podium core.

---

## Installer Maintenance Strategy

Installers in `src/installers/` ship hand-written `docker-compose.yaml` snippets, env vars, secret-generation steps, and integration glue (Mastodon's `db-migrate` service, Zulip's `X-Forwarded-Proto`, plane's YAML anchors, etc.). Upstream apps drift over time — new required env vars, renamed config, image schema changes — and our installers can rot silently.

The intended approach:

1. **Pin image versions** in installers (`zulip/docker-zulip:8.0`, not `:latest`). Trades upstream-tracking for reproducibility — image bumps become intentional events instead of surprises.
2. **Scheduled end-to-end test runs** on cami/cassie via `tests/installers-<machine>.sh` cron'd weekly. Loud signal when an installer + its pinned image stops working.
3. **AI-assisted reconciliation** via `podium update-installer <app>` (or `--all`). The command emits a pre-built prompt that tells an AI agent: read `AGENTS.md`, fetch the upstream compose, diff against our installer, regenerate the installer + hint file, run `podium install <app>` end-to-end on the local machine (and remote test machines if available), confirm the deploy works. The structured installer format (`INSTALL_DISPLAY`, `INSTALL_CREDENTIALS`, `INSTALL_NOTES`, `pre_install()`, `write_files()`) is intentionally easy for an agent to regenerate.

There's no clean fully-automated reconciliation path — installer YAML encodes integration decisions that don't fail loudly when upstream changes. End-to-end tests + AI/human judgment are what surface the subtler drifts.

---

## OSS Project Testing

Podium is validated against real open-source apps by deploying them end-to-end using AI agents across multiple machines. The workflow is:

1. Write a `tests/oss-<machine>.sh` harness — one `run_project()` call per app, all run in parallel via `&` + `wait`.
2. Each `run_project` call runs `podium create --one-off "<idea>"` and curls the result. Each idea prompt includes a `SUMMARY_SUFFIX` instructing the agent to write `SETUP_SUMMARY.md` in the project dir.
3. After runs complete, read the master log (`/tmp/podium-tests/oss-master.log`) and `SETUP_SUMMARY.md` files to assess results.
4. For any app that failed or needed agent workarounds, create or update a `src/project-hints/<slug>.md` file so future runs succeed first-try.

### Test machines and agents

See `machines.local` in the repo root for the current machine list. The canonical setup is:

| Machine | Agent | Test scripts |
|---------|-------|-------------|
| dingdong | claude | `tests/oss-dingdong.sh`, `tests/oss2-dingdong.sh`, `tests/custom-dingdong.sh`, `tests/installers-dingdong.sh`, `tests/installers2-dingdong.sh` |
| cami | codex | `tests/oss-cami.sh`, `tests/oss2-cami.sh`, `tests/custom-cami.sh`, `tests/installers-cami.sh`, `tests/installers2-cami.sh` |
| cassie | gemini/codex | `tests/oss-cassie.sh`, `tests/oss2-cassie.sh`, `tests/custom-cassie.sh`, `tests/installers-cassie.sh`, `tests/installers2-cassie.sh` |

SSH access: `ssh cami@cami`, `ssh cassie@cassie`. Pull repo on remotes: `ssh cami@cami "sudo git -C /usr/local/share/podium-cli pull"`.

### OSS apps already tested and hinted

The following apps have been deployed successfully and have `src/project-hints/` files validated by real test runs:

| App | Image | Notes |
|-----|-------|-------|
| FreshRSS | `freshrss/freshrss:latest` | Port 80 direct, SQLite |
| Memos | `neosmemo/memos:stable` | Port 5230 → nginx |
| Grocy | `lscr.io/linuxserver/grocy:latest` | Port 80 direct |
| Snipe-IT | `snipe/snipe-it:latest` | Needs generated APP_KEY, MariaDB |
| Kimai | `kimai/kimai2:apache` | Port 8001 → nginx, MariaDB |
| Redmine | `redmine:latest` | Port 3000 → nginx, MariaDB utf8mb4, wait 60s |
| Lychee | `lycheeorg/lychee:latest` | Port 8000 → nginx, needs APP_KEY + dedicated DB user |
| Wallabag | `wallabag/wallabag:latest` | Port 80 direct, MariaDB |
| Stirling PDF | `frooodle/s-pdf:latest` | Port 8080 → nginx, needs SECURITY_ENABLE_LOGIN=false |
| IT Tools | `corentinth/it-tools:latest` | Port 80 direct, no config |
| Changedetection | `ghcr.io/dgtlmoon/changedetection.io` | Port 5000 → nginx, WebSocket headers |
| Flame | `pawelmalak/flame:latest` | Port 5005 → nginx |
| Heimdall | `lscr.io/linuxserver/heimdall:latest` | Port 80 direct |
| Umami | `ghcr.io/umami-software/umami:postgresql-latest` | Port 3000 → nginx, **PostgreSQL only** |
| Dashy | `lissy93/dashy:latest` | Port 8080 → nginx |
| LimeSurvey | `martialblog/limesurvey:latest` | Port 8080 → nginx, needs dedicated DB user (empty password rejected) |
| Miniflux | `miniflux/miniflux:latest` | Port 8080 → nginx, **PostgreSQL only**, RUN_MIGRATIONS=1 |
| Grafana | `grafana/grafana:latest` | Port 3000 → nginx |
| Vikunja | `vikunja/vikunja:latest` | Port 3456 → nginx, MariaDB, needs JWTSECRET |
| Mealie | `ghcr.io/mealie-recipes/mealie:latest` | Port 9000 → nginx, SQLite |
| Portainer | `portainer/portainer-ce:latest` | Port 9000 → nginx, needs docker.sock mount |
| Netdata | `netdata/netdata:latest` | Port 19999 → nginx, needs cap_add + host bind mounts |
| Vaultwarden | `vaultwarden/server:latest` | Port 80 direct |
| Kanboard | `kanboard/kanboard:latest` | Port 80 direct |
| Gitea | `gitea/gitea:latest` | Port 3000 → nginx, MariaDB, GITEA__ env prefix |
| Wiki.js | `ghcr.io/requarks/wiki:2` | Port 3000 → nginx, PostgreSQL |
| Jellyfin | `jellyfin/jellyfin:latest` | Port 8096 → nginx, no DB |
| Paperless-ngx | `ghcr.io/paperless-ngx/paperless-ngx:latest` | Port 8000 → nginx, PostgreSQL + Redis |
| Uptime Kuma | `louislam/uptime-kuma:1` | Port 3001 → nginx, SQLite, WebSocket |
| Ghost | `ghost:latest` | Port 2368 → nginx, SQLite for dev |
| BookStack | `lscr.io/linuxserver/bookstack:latest` | Port 80 direct, MariaDB, needs APP_KEY |
| Homer | `b4bz/homer:latest` | Port 8080 → nginx, YAML config |
| Monica | `monica:latest` | Port 80 direct, MariaDB + Redis, needs APP_KEY |
| Listmonk | `listmonk/listmonk:latest` | Port 9000 → nginx, PostgreSQL, --install on start |
| HedgeDoc | `quay.io/hedgedoc/hedgedoc:latest` | Port 3000 → nginx, PostgreSQL, WebSocket |
| Linkwarden | `ghcr.io/linkwarden/linkwarden:latest` | Port 3000 → nginx, PostgreSQL, NEXTAUTH_URL path |
| Tandoor | `vabene1111/recipes:latest` | Port 8080 → nginx, PostgreSQL, static/media volumes |
| n8n | `n8nio/n8n:latest` | Port 5678 → nginx, SQLite, WebSocket |
| Actual Budget | `actualbudget/actual-server:latest` | Port 5006 → nginx, no DB |
| Nextcloud | `nextcloud:latest` | Port 80 direct, MariaDB + Redis |
| PhotoPrism | `photoprism/photoprism:latest` | Port 2342 → nginx, MariaDB, large client_max_body_size |
| Immich | `ghcr.io/immich-app/immich-server:release` | Port 2283 → nginx, dedicated pgvecto-rs DB + shared Redis |
| Trilium Notes | `zadam/trilium:latest` | Port 8080 → nginx, SQLite |
| SearXNG | `searxng/searxng:latest` | Port 8080 → nginx, no DB |
| Glances | `nicolargo/glances:latest-full` | Port 61208 → nginx, pid:host + docker.sock |
| wger | `wger/server:latest` | Port 80 direct + celery workers, PostgreSQL + Redis, config/prod.env |
| Mattermost | `mattermost/mattermost-team-edition:latest` | Port 8065 → nginx, PostgreSQL, WebSocket |
| Outline | `outlinewiki/outline:latest` | Port 3000 → nginx, PostgreSQL + Redis, needs auth provider |

### Adding more OSS apps

To add a new batch:
1. Add `run_project "<name>" "$IDEA_<NAME>"` entries to the relevant `tests/oss-<machine>.sh`.
2. Write the `IDEA_*` variable following the established pattern: exact project name, image, port, nginx or direct, DB requirements, step-by-step instructions, `$SUMMARY_SUFFIX`.
3. Always spell out `mkdir -p ~/podium-projects/<name>` in the steps to prevent agent renaming.
4. Run: `bash tests/oss-<machine>.sh`
5. After completion, check `/tmp/podium-tests/oss-master.log` and `SETUP_SUMMARY.md` files.
6. Create/update `src/project-hints/<slug>.md` for any app that needed workarounds.
7. Commit updated hints and test scripts.
