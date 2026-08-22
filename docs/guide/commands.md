---
title: Command reference
nav_order: 9
---

# Command reference

Run `zeltro --help` for the same list in your terminal, or `zeltro <command> --help` for one command.

Commands marked *(project dir)* must be run from inside a project directory.

---

### 🛠️ Development Tools
*Run from project directory*

| Command | Description |
|---------|-------------|
| `zeltro composer <args>` | Run Composer commands inside container |
| `zeltro art <args>` | Run Laravel Artisan commands |
| `zeltro wp <args>` | Run WordPress CLI commands |
| `zeltro php <args>` | Run PHP inside container |
| `zeltro npm <args>` | Run npm commands inside container |
| `zeltro npx <args>` | Run npx commands inside container |
| `zeltro node <args>` | Run Node.js inside container |
| `zeltro python <args>` | Run Python inside container |
| `zeltro pip <args>` | Run pip inside container |
| `zeltro shell` | Open framework-aware interactive shell or REPL |

### ✅ Static Analysis & Linting
*Run from project directory; paths are relative to the project root (for example `app/Console/Commands/Foo.php`)*

| Command | Description |
|---------|-------------|
| `zeltro phpcs <relative-path>` | Run PHPCS with the default ruleset |
| `zeltro phpcbf <relative-path>` | Run PHPCBF with the default ruleset to auto-fix |
| `zeltro phpmd <relative-path>` | Run PHPMD against a file using the default rules |
| `zeltro php -l <relative-path>` | Run PHP lint against a file |

### 📦 Container Execution
*Run from project directory*

| Command | Description |
|---------|-------------|
| `zeltro exec <cmd>` | Execute command as developer user (no TTY, automation‑friendly) |
| `zeltro exec-root <cmd>` | Execute command as root user (no TTY) |
| `zeltro exec-tty <cmd>` | Execute command as developer user with TTY (interactive) |
| `zeltro exec-tty-root <cmd>` | Execute command as root user with TTY (interactive) |
| `zeltro bash [args]` | Open bash shell inside container with TTY |
| `zeltro tinker [args]` | Open Laravel tinker REPL inside container with TTY |

### ⚡ Enhanced Laravel Commands
*Run from project directory*

| Command | Description |
|---------|-------------|
| `zeltro db-refresh` | Fresh migration + seed |
| `zeltro cache-refresh` | Clear all Laravel caches |

### 🐍 Enhanced Django Commands
*Run from project directory*

| Command | Description |
|---------|-------------|
| `zeltro django manage <args>` | Run `manage.py` with arguments |
| `zeltro django shell` | Open Django interactive shell |

### 🔧 Service Management
*Run from anywhere*

| Command | Description |
|---------|-------------|
| `zeltro mysql <args>` | Run MySQL client inside the `mariadb` service container |
| `zeltro redis <cmd>` | Run Redis CLI commands |
| `zeltro redis-flush` | Flush all Redis data |
| `zeltro memcache <cmd>` | Run Memcached commands via telnet |
| `zeltro memcache-flush` | Flush all Memcached data |
| `zeltro memcache-stats` | Show Memcached statistics |

### 🎛️ Process Management
*Run from project directory*

| Command | Description |
|---------|-------------|
| `zeltro supervisor <cmd>` | Run supervisorctl commands |
| `zeltro supervisor-status` | Show all supervised processes |

### 📁 Project Management

| Command | Description |
|---------|-------------|
| `zeltro up <project>` | Start a project (shared services start regardless) |
| `zeltro up-all` | Start every project |
| `zeltro down <project>` | Stop a project (shared services stay up — use `zeltro stop-services`) |
| `zeltro down-all` | Stop every project (shared services stay up) |
| `zeltro status [project] [--all]` | Show status of active (running) projects; `--all` includes stopped projects |
| `zeltro new <framework> <name> [options]` | Create a new project (framework + name required; DB auto-selected, override with `--database`) |
| `zeltro create "<idea>"` | Create a project from a plain-English idea, then start an interactive AI session in the project dir |
| `zeltro resume <project>` | Resume the last AI session for a project |
| `zeltro install <app>` | Install a popular OSS app in one command (`--list` to see all) |
| `zeltro clone <mode> <repo> [name]` | Clone an existing repo (mode: `work-directly` / `fork` / `new-repo`) |
| `zeltro setup <project> [options]` | Set up an existing project directory |
| `zeltro remove <project> [options]` | Remove a project (DB preserved unless `--force-db-delete`) |

### ⚙️ System Management

| Command | Description |
|---------|-------------|
| `zeltro configure` | Configure Zeltro environment |
| `zeltro ai [--one-off] "<prompt>"` | Start interactive AI agent session (or one-off with `--one-off`) |
| `zeltro ai-set [options]` | Configure global AI agent, model, and API key |
| `zeltro update` | Update Zeltro CLI and base Docker images |
| `zeltro start-services` | Start shared services |
| `zeltro stop-services` | Stop shared services |
| `zeltro uninstall` | Remove all Zeltro Docker resources |
| `zeltro projects-dir` | Show projects directory path |

#### `zeltro ai-set` options

`zeltro ai-set` manages the global AI agent CLI, model, and API key used by Zeltro.

```bash
zeltro ai-set --agent claude --model claude-opus-4-7
zeltro ai-set --agent codex --model gpt-4.1
zeltro ai-set --agent aider --model openai/gpt-4o --api-key sk-...
zeltro ai-set --json-output
```

Supported flags:

- `--agent <name>` – Set the AI agent CLI (`codex`, `claude`, `gemini`, `qwen`, or `aider`).
- `--model <name>` – Set the model name (optional for Codex, Claude and Gemini; required in practice for Aider).
- `--api-key <key>` – Set the AI API key (optional for Codex and Claude; not used by Gemini which uses Google account auth; required for Aider).
- `--api-base <url>` – Set an OpenAI-compatible API endpoint. Aider only.
- `--json-output` – Return the current configuration or update result as JSON (non-interactive).

Examples:

- Inspect current AI settings:
  - `zeltro ai-set --json-output`
- Configure Codex with a model:
  - `zeltro ai-set --agent codex --model gpt-4.1`
- Configure Claude with a model:
  - `zeltro ai-set --agent claude --model claude-opus-4-7`
- Configure Aider against OpenAI:
  - `zeltro ai-set --agent aider --model openai/gpt-4o --api-key sk-...`
- Configure Aider against a local Ollama server:
  - `zeltro ai-set --agent aider --model openai/llama3.1 --api-key ollama --api-base http://localhost:11434/v1`

#### Aider

Aider is the one supported agent with no login of its own — it always talks
directly to a provider's API, so it needs a model **and** a key.

- The model name selects the provider: `openai/gpt-4o`, `anthropic/claude-sonnet-4-5`,
  `gemini/gemini-2.5-pro`, `deepseek/deepseek-chat`. See
  [aider's model list](https://aider.chat/docs/llms.html).
- Aider tags keys by provider (`--api-key openai=sk-...`). Zeltro stores a bare key
  and tags it from the model prefix, so `--api-key sk-...` is all you need. A key
  that already contains `=` is passed through as-is.
- `--api-base` is only needed for an OpenAI-compatible server — Ollama, LM Studio,
  OpenRouter, vLLM. Prefix the model with `openai/` when you use one. Leave it blank
  for a provider's own hosted API.
- Zeltro runs Aider with `--no-auto-commits`, so its edits land in your working tree
  like every other agent's instead of being committed for you.

### 🤖 AI-assisted project creation

### Classify only (for GUIs and other front ends)

```bash
zeltro create --classify-only "<idea>"                  # human-readable
zeltro create --classify-only --json-output "<idea>"    # machine-readable
```

Runs only the classify phase: works out the stack, prints the result, exits 0,
and **creates nothing**. It never prompts, so it is safe to call from a GUI,
a script or an agent.

This exists because the normal non-interactive path (`--one-off`,
`--json-output`) silently takes the top recommendation — fine for automation,
but it throws away the choice a person would have made at the menu. A front end
that wants to present those choices natively should classify first, show the
candidates, then call `zeltro install <app>` or `zeltro new <framework> <name>`
with whatever the user picked.

The JSON carries `project_name` (`null` when the idea implies no real subject,
so ask rather than prefill), `recommended`, `customization_requested`, a
suggested `database` with a reason, and `candidates` — apps first, framework
last, capped at 5. **Apps carry a single fixed `database`** set by the installer;
**frameworks carry a `databases` array** of the engines they allow. Never offer a
database choice for an app. On failure it emits
`{"action": "classify", "status": "error", "message": "..."}` and exits non-zero.

`zeltro create` collects your project idea, adds Zeltro-specific instructions, and hands the combined prompt to your configured AI CLI. Zeltro sets up the environment. The AI builds the app.

```bash
# asks what you want to build (interactive terminals only)
zeltro create

# Pass the idea directly
zeltro create "A timeclock for employees in Django"
zeltro create "A customer check-in system in Laravel"
zeltro create "An inventory tracker in Express"

# Point to an existing GitHub repo to clone and set it up
zeltro create "https://github.com/monicahq/monica"
```

What the AI agent does:

1. If the framework or stack is unclear, asks which one to use before continuing.
2. Runs `zeltro new` to create the project and start its containers.
3. Reads the generated `.env` file to understand database, cache, and mail configuration.
4. Builds the app using framework-native conventions: migrations, models, seeders, routes, controllers, templates.
5. Updates the project README with the local URL, useful commands, and default credentials if any.

If your idea matches a known app that has a Zeltro installer (Grafana, Gitea, n8n, Portainer, etc.), the agent runs `zeltro install <name>` first — getting it live in seconds — then applies any additional customization from your prompt. You never have to write a docker-compose file or know which port the app listens on.

The AI CLI can be cloud-based or local depending on your configuration. Use `zeltro ai-set` to choose which agent is used.

### 🤖 AI agent sessions

Once you have set your global AI agent with `zeltro ai-set`, you can start an interactive AI session seeded with a prompt from any Zeltro project directory:

```bash
cd /path/to/project
zeltro ai "Build a unique homepage hero section."
```

By default `zeltro ai` sends a **one-off** prompt — the agent receives it, does the work, and exits. Durable project context lives in the project's `AGENTS.md` (Zeltro writes it on creation), so each prompt can stand alone. Add `--interactive` if you want a persistent session instead:

```bash
zeltro ai --interactive "Add a health-check endpoint at /ping"
```

`zeltro ai` / `zeltro create`:

- Looks up your configured `AI_AGENT`, `AI_MODEL`, `AI_API_KEY`, and `AI_API_BASE` from `/etc/zeltro-cli/.env`.
- Starts an interactive AI agent session (or non-interactive with `--one-off`) seeded with the prompt using safe, automation-friendly flags:
  - Codex: `OPENAI_API_KEY="$AI_API_KEY" codex [--model "$AI_MODEL"] --dangerously-bypass-approvals-and-sandbox "<prompt>"` (interactive) / `codex exec ...` (one-off)
  - Claude: `ANTHROPIC_API_KEY="$AI_API_KEY" claude --dangerously-skip-permissions [-p] [--model "$AI_MODEL"] "<prompt>"` (`-p` added for `--one-off`)
  - Codex and Claude both **removed their `--api-key` flags**; the key is passed through the environment instead. Zeltro checks the key looks like it belongs to that provider (`sk-ant-` for Claude) and, if it does not, ignores it with a warning and lets the CLI use its own sign-in — a key for the wrong provider would otherwise replace working auth with auth that cannot work.
  - Gemini: `gemini --yolo --skip-trust [--model "$AI_MODEL"] -i "<prompt>"` (interactive) / `... --output-format text --prompt ...` (one-off)
  - Aider: `aider --yes-always --no-auto-commits --no-check-update [--model "$AI_MODEL"] [--api-key <provider>="$AI_API_KEY"] [--openai-api-base "$AI_API_BASE"] --message "<prompt>"` (one-off). Aider's `--message` exits after the reply, so interactive runs seed the session with `--load` instead and hand it back to you. `--no-git` is added when the directory isn't already a git repository, so `--yes-always` can't silently `git init` it.

## 🎯 Command Options

### Global Options

| Option | Description |
|--------|-------------|
| `--json-output` | Clean JSON output (suppresses all text/colors) |
| `--no-colors` | Disable colored output |
| `--debug` | Enable debug logging to `/tmp/zeltro-cli-debug.log` |

### New Project Options

`zeltro new <framework> <name>` — framework and name are **required positional arguments**. Framework is one of: `laravel`, `wordpress`, `php`, `fastapi`, `flask`, `django`, `python`, `express`, `nestjs`, `fastify`, `node`, `nextjs`, `nuxt`, `sveltekit`, `astro`, `hono`, `react`, `vue`.

| Option | Description | Values |
|--------|-------------|---------|
| `--database <type>` | Database type | `auto` (default — per-framework), `mysql`, `postgres`, `mongodb`, `sqlite` |
| `--version <ver>` | Framework version | **Laravel:** `latest` (default), any valid Laravel version tag<br/>**WordPress:** `latest` (default), any valid WordPress version |
| `--db-name <name>` | Database name | Default: project name with dashes converted to underscores |
| `--image <ref>` | Override the project's Docker image | Default: the framework's cbc base image (`canebaycomputers/cbc:nginx-php8` / `nginx-python3` / `nginx-node`) |
| `--no-migration` | Skip database migrations | Migrations run by default |
| `--github` | Create GitHub repository in user account | Requires GitHub CLI authentication |
| `--github-org <org>` | Create GitHub repository in organization | Requires GitHub CLI authentication |
| `--public` | Make the new GitHub repository public | Default is private when `--github`/`--github-org` is used |
| `--private` | Make the new GitHub repository private | Default behavior when no visibility flag is set |
| `--no-storage-symlink` | Skip creating `public/storage` symlink | (Laravel only) |

### Clone Project Options

`zeltro clone <mode> <repo> [name]` — **mode** is a required first argument: `work-directly` (clone and keep the original as upstream), `fork` (fork to your GitHub account), or `new-repo` (create a new GitHub repo for it).

| Option | Description |
|--------|-------------|
| `--overwrite-docker-compose` | Overwrite existing docker-compose.yaml without prompting |
| `--database <type>` | Database type (`mysql`, `postgres`, `mongodb`) |
| `--db-name <name>` | Database name (default: project name with dashes converted to underscores) |
| `--overwrite-env` | Regenerate `.env` even if the cloned repo already includes one (default: keep the existing `.env`) |
| `--no-migration` | Skip database migrations (they run by default — non-destructive `migrate` for adopted apps) |
| `--framework <name>` | Force framework detection (`laravel`, `kavera`, `wordpress`, `octobercms`, `php`, `django`, `flask`, `fastapi`, `python`, `express`, `nestjs`, `fastify`, `node`, `nextjs`, `nuxt`, `sveltekit`, `astro`, `hono`, `react`, `vue`) |
| `--image <ref>` | Override the project's Docker image (for an adapted complex compose, overrides the web-facing service's image; default: the framework's cbc base image) |
| `--no-startup` | Register and adapt project without starting the container — use this to inspect the adapted docker-compose before running `zeltro up` |
| `--github-org <org>` | For `new-repo` mode: create the repository in this organization |
| `--public` | Make the new GitHub repository public (default: private) |
| `--private` | Make the new GitHub repository private |
| `--no-storage-symlink` | Skip creating `public/storage` symlink (Laravel) |

> **Complex projects**: When cloning a project that ships its own multi-service docker-compose (bundled database, cache, workers), Zeltro automatically adapts it: bundled DB/cache services are removed and their env vars are repointed to Zeltro's shared containers (`zeltro-postgres`, `zeltro-mariadb`, `zeltro-redis`, `zeltro-mongo`). The web-facing service gets a static VPC IP. Image type only affects this compose adaptation — framework steps (composer install, `.env` wiring, migrations) are driven by framework detection and run for adapted projects too. Pass `--no-startup` to review the adapted compose before it boots, `--overwrite-env` to repoint an existing app's `.env` connection settings at the shared services (preserving `APP_KEY`), and `--no-migration` to skip migrations.

### Setup Project Options

| Option | Description |
|--------|-------------|
| `--overwrite-docker-compose` | Overwrite existing docker-compose.yaml without prompting |
| `--framework <type>` | Force framework detection (`laravel`, `kavera`, `wordpress`, `octobercms`, `php`, `django`, `flask`, `fastapi`, `python`, `express`, `nestjs`, `fastify`, `node`, `nextjs`, `nuxt`, `sveltekit`, `astro`, `hono`, `react`, `vue`) |
| `--db-name <name>` | Database name (default: project name with dashes converted to underscores) |
| `--image <ref>` | Override the project's Docker image (for an adapted complex compose, overrides the web-facing service's image; default: the framework's cbc base image) |
| `--overwrite-env` | Regenerate `.env` even if one already exists (default: keep the existing `.env`) |
| `--no-migration` | Skip database migrations (they run by default) |
| `--no-startup` | Register and adapt project without starting the container |

### Remove Project Options

| Option | Description |
|--------|-------------|
| `--force-db-delete` | Delete database without confirmation |
| `--preserve-database` | Skip database deletion entirely |
| `--force` | Legacy flag (now only affects database deletion) |

### Uninstall Options

| Option | Description |
|--------|-------------|
| `--delete-images` | Also remove Docker images (default: keep for faster reinstall) |

### Configure Options

| Option | Description |
|--------|-------------|
| `--git-name <name>` | Git user name |
| `--git-email <email>` | Git user email |
| `--projects-dir <dir>` | Projects directory (default: existing or `~/zeltro-projects`) |
| `--vpc-subnet <A.B.C>` | Custom Docker VPC subnet (default: existing or random `10.x.x`) |

Re-running `zeltro configure` is safe — values from `/etc/zeltro-cli/.env` are kept as defaults, and prompts let you change them. Hosts entries for shared services are verified rather than rebuilt, so unchanged installs stay quiet.

## 💡 Usage Examples

### Cloning and Setting Up Projects

```bash
# Clone a Git repository and set it up automatically
zeltro clone https://github.com/user/my-laravel-app

# Clone with custom name and options
zeltro clone https://github.com/user/company-project my-local-name

# Manual Git clone, then setup
git clone https://github.com/user/company-project
zeltro setup company-project
zeltro up company-project

# Downloaded ZIP file - extract to ~/zeltro-projects/company-project/
zeltro setup company-project
zeltro up company-project

# Copied project folder
cp -r existing-project ~/zeltro-projects/new-project
zeltro setup new-project --overwrite-docker-compose
```

### WordPress Development

```bash
# Create a WordPress project (MySQL is auto-selected)
zeltro new wordpress wp-site --version latest

# Install and activate plugins
zeltro wp plugin install woocommerce --activate
zeltro wp plugin list --status=active
```

### JSON Output for Automation

```bash
# Get project status as JSON for scripts/GUI
zeltro status --json-output

# Create project with JSON response
zeltro new fastapi my-api --database postgres --json-output

# Check if services are running in a script
if zeltro status --json-output | jq -r '.shared_services.mariadb.status' | grep -q "RUNNING"; then
    echo "Database is ready"
fi

# Batch project operations (--all so stopped projects are included)
for project in $(zeltro status --all --json-output | jq -r '.projects[].name'); do
    zeltro up $project --json-output
done
```

#### Reading the address fields

Each project in `zeltro status --json-output` carries several address fields.
They mean different things, and one of them is easy to misuse:

| Field | Meaning |
|---|---|
| `external_port` | The published port. **The only portable field** — a port is the same number no matter where you ask from. |
| `local_url` | `http://<project>` — works on the machine running Zeltro, via its `/etc/hosts` entry. |
| `lan_url` | The host's own view of itself: its LAN address and the published port. |
| `metadata` | Display metadata from the project's `x-metadata` block; `{}` when it has none. |

{: .warning }
> **`lan_url` is only meaningful from the host's own network.** It is composed
> from the address the host sees for itself, so on a cloud VM it is the private
> address — `http://172.30.2.182:226` on an EC2 box — which is unroutable from
> anywhere else. It is not a mistake in the value; the field simply cannot know
> who is asking.
>
> If you are reaching a project from another machine, **build the URL from the
> address you used to connect to that host, plus `external_port`.** Do not
> render `lan_url` to a remote user.

{: .note }
> A listening port is not the same as a reachable one. Zeltro reports what the
> host can see about itself; whether your packets arrive is a property of the
> network between you and it — security groups, NAT, VPNs, or simply whether a
> laptop is awake. That question can only be answered from the machine doing the
> asking, so probe from there rather than inferring reachability from status
> output.

### Service Management

```bash

# Check Redis status and flush cache
zeltro redis ping
zeltro redis-flush

# Monitor supervised processes
zeltro supervisor-status
zeltro supervisor restart all
```

### Advanced Usage

#### Containerized Development Commands

**PHP projects** — `zeltro composer`, `zeltro art`, `zeltro php`, and `zeltro wp` run inside your project's container with the correct PHP environment:

```bash
cd ~/zeltro-projects/my-laravel-app
zeltro composer install        # Uses container's PHP 8.2
zeltro art migrate             # Runs with container's Laravel setup
zeltro php script.php          # Executes with project's PHP configuration
```

**Node.js projects** — `zeltro npm`, `zeltro npx`, and `zeltro node` run inside your project's container with Node 22:

```bash
cd ~/zeltro-projects/my-express-app
zeltro npm install             # Installs packages inside container
zeltro npx tsc --init         # Run any npx command inside container
zeltro node script.js         # Execute a script with project's Node environment
```

**Python projects** (FastAPI, Django, plain Python) — `zeltro python` and `zeltro pip` run inside your project's container:

```bash
cd ~/zeltro-projects/my-fastapi-app
zeltro python -c "import sys; print(sys.version)"
zeltro pip install httpx              # Install a package inside the container
zeltro pip list                       # Show installed packages
```

**Django projects** — use the `zeltro django` wrappers for manage.py operations:

```bash
cd ~/zeltro-projects/my-django-app
zeltro django manage migrate          # Run migrations
zeltro django manage createsuperuser  # Create admin user
zeltro django manage collectstatic    # Collect static files
zeltro django manage makemigrations myapp
```

#### Interactive Shells & REPLs

`zeltro shell` opens the right interactive environment for the current project automatically:

```bash
# Laravel — opens php artisan tinker
cd ~/zeltro-projects/my-laravel-app && zeltro shell

# Django — opens python manage.py shell (Django ORM and apps loaded)
cd ~/zeltro-projects/my-django-app && zeltro shell

# FastAPI / plain Python / Python script — opens python3 REPL
cd ~/zeltro-projects/my-fastapi-app && zeltro shell

# Express / Fastify / plain Node.js — opens node REPL
cd ~/zeltro-projects/my-express-app && zeltro shell

# NestJS — opens node REPL; or the NestJS REPL if src/repl.ts exists
cd ~/zeltro-projects/my-nest-app && zeltro shell
```

`zeltro tinker` remains available as the explicit Laravel-only alias.

The NestJS REPL (`src/repl.ts`) is not scaffolded by default. Create it per the [NestJS REPL docs](https://docs.nestjs.com/recipes/repl), then `zeltro shell` will use it automatically.


## 🔌 JSON API Integration

Zeltro provides clean JSON output for programmatic integration, perfect for GUI applications and automation scripts:

```javascript
// Example: Create project via JSON API
const result = await exec('zeltro new laravel myapp --version 11.x --json-output');
const data = JSON.parse(result.stdout);

// Result:
{
  "action": "new_project",
  "project_name": "myapp",
  "framework": "laravel", 
  "database": "mysql",
  "status": "success"
}
```

### Available JSON Commands

**All commands support `--json-output` except containerized development tools:**

✅ **JSON Support Available:**
- `zeltro status --json-output` - Project and service status
- `zeltro new --json-output` - Project creation confirmation
- `zeltro clone --json-output` - Project clone confirmation
- `zeltro setup --json-output` - Project setup confirmation
- `zeltro remove --json-output` - Project removal confirmation
- `zeltro up --json-output` - Project startup confirmation
- `zeltro down --json-output` - Project shutdown confirmation
- `zeltro start-services --json-output` - Service start confirmation
- `zeltro stop-services --json-output` - Service stop confirmation
- `zeltro configure --json-output` - Configuration confirmation
- `zeltro uninstall --json-output` - Uninstall confirmation

❌ **No JSON Support (Container Commands):**
- `zeltro composer` - Runs inside container
- `zeltro art` - Runs inside container
- `zeltro wp` - Runs inside container
- `zeltro php` - Runs inside container
- `zeltro npm` - Runs inside container
- `zeltro npx` - Runs inside container
- `zeltro node` - Runs inside container
- `zeltro python` - Runs inside container
- `zeltro pip` - Runs inside container
- `zeltro shell` - Runs inside container
- `zeltro django` - Runs inside container
- `zeltro exec` - Runs inside container
- `zeltro exec-root` - Runs inside container
- `zeltro supervisor` - Runs inside container
- `zeltro redis` - Direct service connection
- `zeltro memcache` - Direct service connection

## 🏗️ Architecture

### Services Included

- **MariaDB** - Primary database service
- **PostgreSQL** - Alternative database option
- **MongoDB** - NoSQL database option
- **Redis** - Caching and session storage
- **Memcached** - Additional caching layer
- **phpMyAdmin** - Database management interface
- **MailHog** - Email testing and debugging (captures outbound emails)

### Project Structure

```
~/zeltro-projects/
├── project1/
│   ├── docker-compose.yaml
│   ├── .env
│   └── [project files]
├── project2/
└── ...
```

### Network Configuration

Each project gets:
- Unique Docker IP address (10.236.58.x)
- Automatic `/etc/hosts` entry
- Mapped external port for LAN access
- Local URL: `http://project-name`
- LAN URL: `http://your-ip:port`


## Uninstallation


### Platform-Specific Uninstall

#### 🐧 Linux (Debian / Ubuntu / Ubuntu-based)
```bash
# 1. Clean up Docker resources first
zeltro uninstall

# 2. Remove the CLI files
sudo rm -f /usr/local/bin/zeltro
sudo rm -rf /usr/local/share/zeltro-cli

# 3. Remove configuration directory (optional)
sudo rm -rf /etc/zeltro-cli
```

#### 🍎 MacOS (Homebrew)
```bash
# Automatic cleanup - runs 'zeltro uninstall' then removes CLI
brew uninstall zeltro-cli

# Manual method (if needed)
zeltro uninstall
rm -rf /usr/local/bin/zeltro
sudo rm -rf /etc/zeltro-cli
```

### What Gets Removed

**`zeltro uninstall` removes:**
- ✅ All Zeltro service containers (mariadb, redis, postgres, etc.)
- ✅ All individual project containers
- ✅ Docker images (optional with `--delete-images`)
- ✅ Docker volumes and networks
- ✅ Hosts file entries for services and projects
- ✅ Backs up project docker-compose.yaml files as .backup

**What's preserved:**
- ✅ Your project source code and files
- ✅ Other non-Zeltro Docker containers and images
- ✅ Docker Desktop/Engine itself

### Uninstall Options

| Option | Description |
|--------|-------------|
| `--delete-images` | Also remove Docker images (default: keep for faster reinstall) |
| `--json-output` | Output JSON responses for automation |
| `--help` | Show uninstall help and options |

## 🔧 Configuration

### Initial Setup

```bash
# Run the configuration wizard
zeltro configure
```

`zeltro configure` also installs **bash tab-completion** (to `/etc/bash_completion.d/zeltro`). Open a new shell and tab through commands, project names, and installer names:

```
zeltro ins<TAB>            → install
zeltro install gr<TAB>     → grafana  graylog  grocy
zeltro up <TAB>            → (your project names)
zeltro new <TAB>           → laravel  wordpress  fastapi  django  ...
zeltro clone <TAB>         → work-directly  fork  new-repo
```

### Environment Variables

- `PROJECTS_DIR` - Custom projects directory
- `JSON_OUTPUT` - Enable JSON output mode
- `NO_COLOR` - Disable colored output (deprecated - use `--json-output`)

## 📝 Important Notes

- **Directory Requirements**: Development tools (`composer`, `art`, `wp`, `php`, `npm`, `npx`, `node`, `python`, `exec`, `supervisor`) must be run from within a project directory
- **JSON Output**: Use `--json-output` for programmatic integration (GUI, scripts, automation)
- **Non-Interactive Mode**: Use `--json-output` for fully non-interactive automated deployment
- **Database Creation**: Databases are automatically created and configured for each project
- **Host Entries**: Local DNS entries are automatically managed in `/etc/hosts`

## 🚦 Getting Help

```bash
# Show comprehensive help
zeltro help

# Show command-specific help
zeltro new --help
zeltro remove --help
```

## 🔍 Troubleshooting

### Common Issues

1. **Services not starting**: Check Docker is running and ports are available
2. **Permission errors**: Ensure user is in `docker` group
3. **Database connection**: Verify database service is running with `zeltro status`
4. **Port conflicts**: Each project gets a unique port automatically assigned

### Debug Commands

```bash
# Check service status
zeltro status

# View container logs
docker logs [container-name]

# Check network connectivity
zeltro exec "ping mariadb"

# Enable debug logging for any command
zeltro new my-project --debug
zeltro setup my-project --debug
zeltro configure --debug

# View debug log
cat /tmp/zeltro-cli-debug.log
```

### Debug Mode

All Zeltro commands support a `--debug` flag that creates detailed logs to help troubleshoot issues:

- **Log Location**: `/tmp/zeltro-cli-debug.log`
- **Session Tracking**: Each new command creates a fresh debug session
- **Detailed Output**: Shows script flow, function calls, and exit codes
- **Cross-Script Tracking**: Debug flag is passed between scripts automatically

**Example:**
```bash
# Debug a project creation issue
zeltro new laravel test-project --debug

# Check what happened
tail -f /tmp/zeltro-cli-debug.log
```

---

**Zeltro** - Streamlined web development with Docker 🐳

### ⚙️ System Management

| Command | Description |
|---------|-------------|
| `zeltro configure` | Configure the Zeltro environment |
| `zeltro ai [--interactive] "<prompt>"` | Send a prompt to your AI agent (one-off by default) |
| `zeltro ai-set [options]` | Configure the AI agent, model and API key |
| `zeltro resume <project>` | Resume a project's last AI session |
| `zeltro update [--full]` | Update the CLI (`--full` also re-runs the platform installer and re-pulls images) |
| `zeltro start-services` | Start the shared services |
| `zeltro stop-services` | Stop the shared services |
| `zeltro enable-service <name>` | Enable an optional shared service (`minio`, `meilisearch`) |
| `zeltro disable-service <name>` | Disable one (its data volume is kept) |
| `zeltro uninstall` | Remove Zeltro's Docker resources |
| `zeltro projects-dir` | Print the projects directory path |
| `zeltro create-installer "<idea>"` | Generate a new app installer via AI |
| `zeltro update-installer <app>\|--all` | Refresh installers against upstream via AI |

---

## Global options

| Option | Description |
|---|---|
| `--json-output` | Machine-readable JSON; suppresses all text and colour |
| `--no-colors` | Disable coloured output |
| `--debug` | Log to `/tmp/zeltro-cli-debug.log` |

See [Automation & JSON](../automation/) for which commands support JSON and how to script against them.
