---
title: Frameworks
nav_order: 5
---

# Frameworks — `zeltro new`

`zeltro new <framework> <name>` scaffolds a greenfield project **you write**. Both arguments are required positionals.

```bash
zeltro new laravel my-shop
zeltro new flask my-api --database sqlite
zeltro new express my-service --database postgres --version latest
```

For ready-made third-party apps you *run* rather than write, see [App library](../app-library/) instead.

---

## Supported frameworks

| Framework | Runtime image | Default database |
|---|---|---|
| `laravel` | PHP 8.3 | MySQL |
| `kavera` | PHP 8.3 | MySQL |
| `octobercms` | PHP 8.3 | MySQL |
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
| `nextjs` | Node 22 | SQLite |
| `nuxt` | Node 22 | SQLite |
| `sveltekit` | Node 22 | SQLite |
| `astro` | Node 22 | SQLite |
| `hono` | Node 22 | SQLite |
| `react` | Node 22 | SQLite |
| `vue` | Node 22 | SQLite |

---

### Front-end frameworks

`nextjs`, `nuxt`, `sveltekit`, `astro`, `react` and `vue` are scaffolded as
running dev servers with hot reload, proxied through nginx on port 80. Edit a
file and the page updates — no build step, no port to remember.

They default to **SQLite**, unlike every other framework here, because a
front-end project should not start a database server it never queries. Ask for
one explicitly when you need it:

```bash
zeltro new nextjs my-app --database postgres
```

`react` and `vue` are plain single-page apps on Vite with no server rendering.
`hono` is an API framework rather than a UI one, and is grouped with them only
because it shares the same Node base image.

{: .note }
> Hot reload is wired for you. The dev server's own port is never published —
> the browser reaches the app on port 80 through nginx — so each project's Vite
> config pins the HMR socket to port 80. Change that and hot reload stops
> connecting while the page still loads, which is a confusing failure.

### Kavera

[Kavera](https://github.com/CaneBayComputers/kavera) is a Laravel-native **website** framework: flat-file Blade pages plus service-driven dynamic content (Blogger posts, Eventbrite events, Flickr galleries, form webhooks) cached through Redis. Forms ship with email, webhooks, spam controls and reCAPTCHA; pages carry SEO titles and optional JSON-LD.

It exists because an agent editing page *files* beats an agent driving a CMS admin UI. Reach for it over plain Laravel for marketing sites, brochure sites, portfolios and galleries — and for plain Laravel when you need a real application with custom models and business logic.

```bash
zeltro new kavera my-site
```

Pages live in `resources/views/content`. After adding or removing one, refresh the registry so routes resolve:

```bash
zeltro art app:update-content-list
```

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
zeltro new flask notes --database sqlite
zeltro new django blog --database sqlite
zeltro new laravel shop --database sqlite
```

SQLite needs no shared service — it's a single file. Zeltro creates it, points the project's `.env` at it, and runs migrations normally.

The file always lives **inside the project directory**:

| Framework | Path |
|---|---|
| Django | `db.sqlite3` |
| Laravel | `database/database.sqlite` |
| Everything else | `database.sqlite` |

That location is deliberate. The project directory is the only path bind-mounted into the container, so a database anywhere else would be destroyed every time the container is recreated on `zeltro up`. It is also gitignored by default.

Good for prototypes, single-user tools, and test fixtures. For anything concurrent, use Postgres or MySQL.

### Shared server databases

`mysql`, `postgres` and `mongodb` connect to the shared service containers. Zeltro creates the database and writes the connection settings into the project's `.env` — you never configure credentials by hand. See [Architecture → Shared services](../architecture/#shared-services) for hostnames and credentials.

---

## Working inside a project

Run these **from the project directory**. They execute inside the container, with the correct runtime.

### PHP

```bash
zeltro composer install
zeltro art migrate
zeltro wp plugin list --status=active
zeltro php script.php
zeltro tinker
```

### Python

```bash
zeltro python -c "import sys; print(sys.version)"
zeltro pip install httpx
zeltro django manage migrate
zeltro django manage createsuperuser
zeltro shell
```

Python containers provide `python3`, not `python`.

### Node

```bash
zeltro npm install
zeltro npx tsc --init
zeltro node script.js
zeltro shell
```

### Any framework

```bash
zeltro exec <cmd>              # run a command, no TTY — good for scripts and CI
zeltro exec-root <cmd>         # as root
zeltro bash                    # interactive shell
zeltro shell                   # framework-aware REPL (tinker / django shell / node / python3)
zeltro supervisor restart all  # restart in-container processes
zeltro supervisor-status
```

Use `zeltro supervisor`, never `zeltro exec supervisorctl` — the latter runs as the developer user and is denied on the supervisor socket.

### Laravel extras

```bash
zeltro db-refresh      # fresh migration + seed
zeltro cache-refresh   # clear all caches
zeltro phpcs app/      # static analysis
zeltro phpcbf app/     # auto-fix
zeltro phpmd app/File.php
zeltro php -l app/File.php
```

---

## Adopting an existing project

```bash
zeltro setup my-project                          # a folder already in ~/zeltro-projects/
zeltro setup my-project --framework django       # force detection
zeltro setup my-project --overwrite-env          # repoint an existing .env at shared services
zeltro setup my-project --no-startup             # register without starting, to review the compose
```

Framework detection reads the project's files — `artisan`, `manage.py`, `main.py`, `app.py`, `package.json`, `wp-config.php`. Flask and FastAPI are distinguished by which one the file actually imports, not by filename.
