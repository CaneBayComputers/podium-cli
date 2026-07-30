---
title: Frameworks
layout: default
nav_order: 4
---

# Frameworks — `podium new`

`podium new <framework> <name>` scaffolds a greenfield project **you write**. Both arguments are required positionals.

```bash
podium new laravel my-shop
podium new flask my-api --database sqlite
podium new express my-service --database postgres --version latest
```

For ready-made third-party apps you *run* rather than write, see [App library]({{ site.baseurl }}/guide/app-library/) instead.

---

## Supported frameworks

| Framework | Runtime image | Default database |
|---|---|---|
| `laravel` | PHP 8.3 | MySQL |
| `wordpress` | PHP 8.3 | MySQL |
| `php` | PHP 8.3 | MySQL |
| `fastapi` | Python 3 | PostgreSQL |
| `flask` | Python 3 | PostgreSQL |
| `django` | Python 3 | PostgreSQL |
| `python` | Python 3 | PostgreSQL |
| `express` | Node 22 | MySQL |
| `nestjs` | Node 22 | MySQL |
| `fastify` | Node 22 | MySQL |
| `node` | Node 22 | MySQL |

---

## Options

| Option | Description | Values |
|---|---|---|
| `--database <type>` | Database engine | `auto` (default), `mysql`, `postgres`, `mongodb`, `sqlite` |
| `--db-name <name>` | Database name | Default: project name, dashes → underscores |
| `--version <ver>` | Framework version | Laravel / WordPress: `latest` or a version tag |
| `--image <ref>` | Override the Docker image | Default: the framework's base image |
| `--no-migration` | Skip migrations | Migrations run by default |
| `--one-off` | Skip the AI hand-off after creation | |
| `--github` | Create a GitHub repo in your account | Requires `gh` auth |
| `--github-org <org>` | Create the repo in an organization | |
| `--public` / `--private` | Repo visibility | Default private |
| `--no-storage-symlink` | Skip `public/storage` symlink | Laravel only |

---

## Databases

### SQLite

```bash
podium new flask notes --database sqlite
podium new django blog --database sqlite
podium new laravel shop --database sqlite
```

SQLite needs no shared service — it's a single file. Podium creates it, points the project's `.env` at it, and runs migrations normally.

The file always lives **inside the project directory**:

| Framework | Path |
|---|---|
| Django | `db.sqlite3` |
| Laravel | `database/database.sqlite` |
| Everything else | `database.sqlite` |

That location is deliberate. The project directory is the only path bind-mounted into the container, so a database anywhere else would be destroyed every time the container is recreated on `podium up`. It is also gitignored by default.

Good for prototypes, single-user tools, and test fixtures. For anything concurrent, use Postgres or MySQL.

### Shared server databases

`mysql`, `postgres` and `mongodb` connect to the shared service containers. Podium creates the database and writes the connection settings into the project's `.env` — you never configure credentials by hand. See [Architecture → Shared services]({{ site.baseurl }}/guide/architecture/#shared-services) for hostnames and credentials.

---

## Working inside a project

Run these **from the project directory**. They execute inside the container, with the correct runtime.

### PHP

```bash
podium composer install
podium art migrate
podium wp plugin list --status=active
podium php script.php
podium tinker
```

### Python

```bash
podium python -c "import sys; print(sys.version)"
podium pip install httpx
podium django manage migrate
podium django manage createsuperuser
podium shell
```

Python containers provide `python3`, not `python`.

### Node

```bash
podium npm install
podium npx tsc --init
podium node script.js
podium shell
```

### Any framework

```bash
podium exec <cmd>              # run a command, no TTY — good for scripts and CI
podium exec-root <cmd>         # as root
podium bash                    # interactive shell
podium shell                   # framework-aware REPL (tinker / django shell / node / python3)
podium supervisor restart all  # restart in-container processes
podium supervisor-status
```

Use `podium supervisor`, never `podium exec supervisorctl` — the latter runs as the developer user and is denied on the supervisor socket.

### Laravel extras

```bash
podium db-refresh      # fresh migration + seed
podium cache-refresh   # clear all caches
podium phpcs app/      # static analysis
podium phpcbf app/     # auto-fix
podium phpmd app/File.php
podium php -l app/File.php
```

---

## Adopting an existing project

```bash
podium setup my-project                          # a folder already in ~/podium-projects/
podium setup my-project --framework django       # force detection
podium setup my-project --overwrite-env          # repoint an existing .env at shared services
podium setup my-project --no-startup             # register without starting, to review the compose
```

Framework detection reads the project's files — `artisan`, `manage.py`, `main.py`, `app.py`, `package.json`, `wp-config.php`. Flask and FastAPI are distinguished by which one the file actually imports, not by filename.
