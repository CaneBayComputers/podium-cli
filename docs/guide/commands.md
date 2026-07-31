---
title: Command reference
layout: default
nav_order: 7
---

# Command reference

Run `podium --help` for the same list in your terminal, or `podium <command> --help` for one command.

Commands marked *(project dir)* must be run from inside a project directory.

---

### 🛠️ Development Tools
*Run from project directory*

| Command | Description |
|---------|-------------|
| `podium composer <args>` | Run Composer commands inside container |
| `podium art <args>` | Run Laravel Artisan commands |
| `podium wp <args>` | Run WordPress CLI commands |
| `podium php <args>` | Run PHP inside container |
| `podium npm <args>` | Run npm commands inside container |
| `podium npx <args>` | Run npx commands inside container |
| `podium node <args>` | Run Node.js inside container |
| `podium python <args>` | Run Python inside container |
| `podium pip <args>` | Run pip inside container |
| `podium shell` | Open framework-aware interactive shell or REPL |

### ✅ Static Analysis & Linting
*Run from project directory; paths are relative to the project root (for example `app/Console/Commands/Foo.php`)*

| Command | Description |
|---------|-------------|
| `podium phpcs <relative-path>` | Run PHPCS with the default ruleset |
| `podium phpcbf <relative-path>` | Run PHPCBF with the default ruleset to auto-fix |
| `podium phpmd <relative-path>` | Run PHPMD against a file using the default rules |
| `podium php -l <relative-path>` | Run PHP lint against a file |

### 📦 Container Execution
*Run from project directory*

| Command | Description |
|---------|-------------|
| `podium exec <cmd>` | Execute command as developer user (no TTY, automation‑friendly) |
| `podium exec-root <cmd>` | Execute command as root user (no TTY) |
| `podium exec-tty <cmd>` | Execute command as developer user with TTY (interactive) |
| `podium exec-tty-root <cmd>` | Execute command as root user with TTY (interactive) |
| `podium bash [args]` | Open bash shell inside container with TTY |
| `podium tinker [args]` | Open Laravel tinker REPL inside container with TTY |

### ⚡ Enhanced Laravel Commands
*Run from project directory*

| Command | Description |
|---------|-------------|
| `podium db-refresh` | Fresh migration + seed |
| `podium cache-refresh` | Clear all Laravel caches |

### 🐍 Enhanced Django Commands
*Run from project directory*

| Command | Description |
|---------|-------------|
| `podium django manage <args>` | Run `manage.py` with arguments |
| `podium django shell` | Open Django interactive shell |

### 🔧 Service Management
*Run from anywhere*

| Command | Description |
|---------|-------------|
| `podium mysql <args>` | Run MySQL client inside the `mariadb` service container |
| `podium redis <cmd>` | Run Redis CLI commands |
| `podium redis-flush` | Flush all Redis data |
| `podium memcache <cmd>` | Run Memcached commands via telnet |
| `podium memcache-flush` | Flush all Memcached data |
| `podium memcache-stats` | Show Memcached statistics |

### 🎛️ Process Management
*Run from project directory*

| Command | Description |
|---------|-------------|
| `podium supervisor <cmd>` | Run supervisorctl commands |
| `podium supervisor-status` | Show all supervised processes |

### 📁 Project Management

| Command | Description |
|---------|-------------|
| `podium up <project>` | Start a project (shared services start regardless) |
| `podium up-all` | Start every project |
| `podium down <project>` | Stop a project (shared services stay up — use `podium stop-services`) |
| `podium down-all` | Stop every project (shared services stay up) |
| `podium status [project] [--all]` | Show status of active (running) projects; `--all` includes stopped projects |
| `podium new <framework> <name> [options]` | Create a new project (framework + name required; DB auto-selected, override with `--database`) |
| `podium create "<idea>"` | Create a project from a plain-English idea, then start an interactive AI session in the project dir |
| `podium resume <project>` | Resume the last AI session for a project |
| `podium install <app>` | Install a popular OSS app in one command (`--list` to see all) |
| `podium clone <mode> <repo> [name]` | Clone an existing repo (mode: `work-directly` / `fork` / `new-repo`) |
| `podium setup <project> [options]` | Set up an existing project directory |
| `podium remove <project> [options]` | Remove a project (DB preserved unless `--force-db-delete`) |

### ⚙️ System Management

| Command | Description |
|---------|-------------|
| `podium configure` | Configure Podium environment |
| `podium ai [--one-off] "<prompt>"` | Start interactive AI agent session (or one-off with `--one-off`) |
| `podium ai-set [options]` | Configure global AI agent, model, and API key |
| `podium update` | Update Podium CLI and base Docker images |
| `podium start-services` | Start shared services |
| `podium stop-services` | Stop shared services |
| `podium uninstall` | Remove all Podium Docker resources |
| `podium projects-dir` | Show projects directory path |

#### `podium ai-set` options

`podium ai-set` manages the global AI agent CLI, model, and API key used by Podium.

```bash
podium ai-set --agent claude --model claude-opus-4-7
podium ai-set --agent codex --model gpt-4.1
podium ai-set --agent aider --model openai/gpt-4o --api-key sk-...
podium ai-set --json-output
```

Supported flags:

- `--agent <name>` – Set the AI agent CLI (`codex`, `claude`, `gemini`, or `aider`).
- `--model <name>` – Set the model name (optional for Codex, Claude and Gemini; required in practice for Aider).
- `--api-key <key>` – Set the AI API key (optional for Codex and Claude; not used by Gemini which uses Google account auth; required for Aider).
- `--api-base <url>` – Set an OpenAI-compatible API endpoint. Aider only.
- `--json-output` – Return the current configuration or update result as JSON (non-interactive).

Examples:

- Inspect current AI settings:
  - `podium ai-set --json-output`
- Configure Codex with a model:
  - `podium ai-set --agent codex --model gpt-4.1`
- Configure Claude with a model:
  - `podium ai-set --agent claude --model claude-opus-4-7`
- Configure Aider against OpenAI:
  - `podium ai-set --agent aider --model openai/gpt-4o --api-key sk-...`
- Configure Aider against a local Ollama server:
  - `podium ai-set --agent aider --model openai/llama3.1 --api-key ollama --api-base http://localhost:11434/v1`

#### Aider

Aider is the one supported agent with no login of its own — it always talks
directly to a provider's API, so it needs a model **and** a key.

- The model name selects the provider: `openai/gpt-4o`, `anthropic/claude-sonnet-4-5`,
  `gemini/gemini-2.5-pro`, `deepseek/deepseek-chat`. See
  [aider's model list](https://aider.chat/docs/llms.html).
- Aider tags keys by provider (`--api-key openai=sk-...`). Podium stores a bare key
  and tags it from the model prefix, so `--api-key sk-...` is all you need. A key
  that already contains `=` is passed through as-is.
- `--api-base` is only needed for an OpenAI-compatible server — Ollama, LM Studio,
  OpenRouter, vLLM. Prefix the model with `openai/` when you use one. Leave it blank
  for a provider's own hosted API.
- Podium runs Aider with `--no-auto-commits`, so its edits land in your working tree
  like every other agent's instead of being committed for you.

### 🤖 AI-assisted project creation

`podium create` collects your project idea, adds Podium-specific instructions, and hands the combined prompt to your configured AI CLI. Podium sets up the environment. The AI builds the app.

```bash
# asks what you want to build (interactive terminals only)
podium create

# Pass the idea directly
podium create "A timeclock for employees in Django"
podium create "A customer check-in system in Laravel"
podium create "An inventory tracker in Express"

# Point to an existing GitHub repo to clone and set it up
podium create "https://github.com/monicahq/monica"
```

What the AI agent does:

1. If the framework or stack is unclear, asks which one to use before continuing.
2. Runs `podium new` to create the project and start its containers.
3. Reads the generated `.env` file to understand database, cache, and mail configuration.
4. Builds the app using framework-native conventions: migrations, models, seeders, routes, controllers, templates.
5. Updates the project README with the local URL, useful commands, and default credentials if any.

If your idea matches a known app that has a Podium installer (Grafana, Gitea, n8n, Portainer, etc.), the agent runs `podium install <name>` first — getting it live in seconds — then applies any additional customization from your prompt. You never have to write a docker-compose file or know which port the app listens on.

The AI CLI can be cloud-based or local depending on your configuration. Use `podium ai-set` to choose which agent is used.

### 🤖 AI agent sessions

Once you have set your global AI agent with `podium ai-set`, you can start an interactive AI session seeded with a prompt from any Podium project directory:

```bash
cd /path/to/project
podium ai "Build a unique homepage hero section."
```

By default `podium ai` sends a **one-off** prompt — the agent receives it, does the work, and exits. Durable project context lives in the project's `AGENTS.md` (Podium writes it on creation), so each prompt can stand alone. Add `--interactive` if you want a persistent session instead:

```bash
podium ai --interactive "Add a health-check endpoint at /ping"
```

`podium ai` / `podium create`:

- Looks up your configured `AI_AGENT`, `AI_MODEL`, `AI_API_KEY`, and `AI_API_BASE` from `/etc/podium-cli/.env`.
- Starts an interactive AI agent session (or non-interactive with `--one-off`) seeded with the prompt using safe, automation-friendly flags:
  - Codex: `codex [--model "$AI_MODEL"] [--api-key "$AI_API_KEY"] --dangerously-bypass-approvals-and-sandbox "<prompt>"` (interactive) / `codex exec ...` (one-off)
  - Claude: `claude --dangerously-skip-permissions [-p] [--model "$AI_MODEL"] [--api-key "$AI_API_KEY"] "<prompt>"` (`-p` added for `--one-off`)
  - Gemini: `gemini --yolo --skip-trust [--model "$AI_MODEL"] -i "<prompt>"` (interactive) / `... --output-format text --prompt ...` (one-off)
  - Aider: `aider --yes-always --no-auto-commits --no-check-update [--model "$AI_MODEL"] [--api-key <provider>="$AI_API_KEY"] [--openai-api-base "$AI_API_BASE"] --message "<prompt>"` (one-off). Aider's `--message` exits after the reply, so interactive runs seed the session with `--load` instead and hand it back to you. `--no-git` is added when the directory isn't already a git repository, so `--yes-always` can't silently `git init` it.

## 🎯 Command Options

### Global Options

| Option | Description |
|--------|-------------|
| `--json-output` | Clean JSON output (suppresses all text/colors) |
| `--no-colors` | Disable colored output |
| `--debug` | Enable debug logging to `/tmp/podium-cli-debug.log` |

### New Project Options

`podium new <framework> <name>` — framework and name are **required positional arguments**. Framework is one of: `laravel`, `wordpress`, `php`, `fastapi`, `flask`, `django`, `python`, `express`, `nestjs`, `fastify`, `node`.

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

`podium clone <mode> <repo> [name]` — **mode** is a required first argument: `work-directly` (clone and keep the original as upstream), `fork` (fork to your GitHub account), or `new-repo` (create a new GitHub repo for it).

| Option | Description |
|--------|-------------|
| `--overwrite-docker-compose` | Overwrite existing docker-compose.yaml without prompting |
| `--database <type>` | Database type (`mysql`, `postgres`, `mongodb`) |
| `--db-name <name>` | Database name (default: project name with dashes converted to underscores) |
| `--overwrite-env` | Regenerate `.env` even if the cloned repo already includes one (default: keep the existing `.env`) |
| `--no-migration` | Skip database migrations (they run by default — non-destructive `migrate` for adopted apps) |
| `--framework <name>` | Force framework detection (`laravel`, `kavera`, `wordpress`, `octobercms`, `php`, `django`, `flask`, `fastapi`, `python`, `express`, `nestjs`, `fastify`, `node`) |
| `--image <ref>` | Override the project's Docker image (for an adapted complex compose, overrides the web-facing service's image; default: the framework's cbc base image) |
| `--no-startup` | Register and adapt project without starting the container — use this to inspect the adapted docker-compose before running `podium up` |
| `--github-org <org>` | For `new-repo` mode: create the repository in this organization |
| `--public` | Make the new GitHub repository public (default: private) |
| `--private` | Make the new GitHub repository private |
| `--no-storage-symlink` | Skip creating `public/storage` symlink (Laravel) |

> **Complex projects**: When cloning a project that ships its own multi-service docker-compose (bundled database, cache, workers), Podium automatically adapts it: bundled DB/cache services are removed and their env vars are repointed to Podium's shared containers (`podium-postgres`, `podium-mariadb`, `podium-redis`, `podium-mongo`). The web-facing service gets a static VPC IP. Image type only affects this compose adaptation — framework steps (composer install, `.env` wiring, migrations) are driven by framework detection and run for adapted projects too. Pass `--no-startup` to review the adapted compose before it boots, `--overwrite-env` to repoint an existing app's `.env` connection settings at the shared services (preserving `APP_KEY`), and `--no-migration` to skip migrations.

### Setup Project Options

| Option | Description |
|--------|-------------|
| `--overwrite-docker-compose` | Overwrite existing docker-compose.yaml without prompting |
| `--framework <type>` | Force framework detection (`laravel`, `kavera`, `wordpress`, `octobercms`, `php`, `django`, `flask`, `fastapi`, `python`, `express`, `nestjs`, `fastify`, `node`) |
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
| `--projects-dir <dir>` | Projects directory (default: existing or `~/podium-projects`) |
| `--vpc-subnet <A.B.C>` | Custom Docker VPC subnet (default: existing or random `10.x.x`) |

Re-running `podium configure` is safe — values from `/etc/podium-cli/.env` are kept as defaults, and prompts let you change them. Hosts entries for shared services are verified rather than rebuilt, so unchanged installs stay quiet.

## 💡 Usage Examples

### Cloning and Setting Up Projects

```bash
# Clone a Git repository and set it up automatically
podium clone https://github.com/user/my-laravel-app

# Clone with custom name and options
podium clone https://github.com/user/company-project my-local-name

# Manual Git clone, then setup
git clone https://github.com/user/company-project
podium setup company-project
podium up company-project

# Downloaded ZIP file - extract to ~/podium-projects/company-project/
podium setup company-project
podium up company-project

# Copied project folder
cp -r existing-project ~/podium-projects/new-project
podium setup new-project --overwrite-docker-compose
```

### WordPress Development

```bash
# Create a WordPress project (MySQL is auto-selected)
podium new wordpress wp-site --version latest

# Install and activate plugins
podium wp plugin install woocommerce --activate
podium wp plugin list --status=active
```

### JSON Output for Automation

```bash
# Get project status as JSON for scripts/GUI
podium status --json-output

# Create project with JSON response
podium new fastapi my-api --database postgres --json-output

# Check if services are running in a script
if podium status --json-output | jq -r '.shared_services.mariadb.status' | grep -q "RUNNING"; then
    echo "Database is ready"
fi

# Batch project operations (--all so stopped projects are included)
for project in $(podium status --all --json-output | jq -r '.projects[].name'); do
    podium up $project --json-output
done
```

### Service Management

```bash

# Check Redis status and flush cache
podium redis ping
podium redis-flush

# Monitor supervised processes
podium supervisor-status
podium supervisor restart all
```

### Advanced Usage

#### Containerized Development Commands

**PHP projects** — `podium composer`, `podium art`, `podium php`, and `podium wp` run inside your project's container with the correct PHP environment:

```bash
cd ~/podium-projects/my-laravel-app
podium composer install        # Uses container's PHP 8.2
podium art migrate             # Runs with container's Laravel setup
podium php script.php          # Executes with project's PHP configuration
```

**Node.js projects** — `podium npm`, `podium npx`, and `podium node` run inside your project's container with Node 22:

```bash
cd ~/podium-projects/my-express-app
podium npm install             # Installs packages inside container
podium npx tsc --init         # Run any npx command inside container
podium node script.js         # Execute a script with project's Node environment
```

**Python projects** (FastAPI, Django, plain Python) — `podium python` and `podium pip` run inside your project's container:

```bash
cd ~/podium-projects/my-fastapi-app
podium python -c "import sys; print(sys.version)"
podium pip install httpx              # Install a package inside the container
podium pip list                       # Show installed packages
```

**Django projects** — use the `podium django` wrappers for manage.py operations:

```bash
cd ~/podium-projects/my-django-app
podium django manage migrate          # Run migrations
podium django manage createsuperuser  # Create admin user
podium django manage collectstatic    # Collect static files
podium django manage makemigrations myapp
```

#### Interactive Shells & REPLs

`podium shell` opens the right interactive environment for the current project automatically:

```bash
# Laravel — opens php artisan tinker
cd ~/podium-projects/my-laravel-app && podium shell

# Django — opens python manage.py shell (Django ORM and apps loaded)
cd ~/podium-projects/my-django-app && podium shell

# FastAPI / plain Python / Python script — opens python3 REPL
cd ~/podium-projects/my-fastapi-app && podium shell

# Express / Fastify / plain Node.js — opens node REPL
cd ~/podium-projects/my-express-app && podium shell

# NestJS — opens node REPL; or the NestJS REPL if src/repl.ts exists
cd ~/podium-projects/my-nest-app && podium shell
```

`podium tinker` remains available as the explicit Laravel-only alias.

The NestJS REPL (`src/repl.ts`) is not scaffolded by default. Create it per the [NestJS REPL docs](https://docs.nestjs.com/recipes/repl), then `podium shell` will use it automatically.


## 🔌 JSON API Integration

Podium provides clean JSON output for programmatic integration, perfect for GUI applications and automation scripts:

```javascript
// Example: Create project via JSON API
const result = await exec('podium new laravel myapp --version 11.x --json-output');
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
- `podium status --json-output` - Project and service status
- `podium new --json-output` - Project creation confirmation
- `podium clone --json-output` - Project clone confirmation
- `podium setup --json-output` - Project setup confirmation
- `podium remove --json-output` - Project removal confirmation
- `podium up --json-output` - Project startup confirmation
- `podium down --json-output` - Project shutdown confirmation
- `podium start-services --json-output` - Service start confirmation
- `podium stop-services --json-output` - Service stop confirmation
- `podium configure --json-output` - Configuration confirmation
- `podium uninstall --json-output` - Uninstall confirmation

❌ **No JSON Support (Container Commands):**
- `podium composer` - Runs inside container
- `podium art` - Runs inside container
- `podium wp` - Runs inside container
- `podium php` - Runs inside container
- `podium npm` - Runs inside container
- `podium npx` - Runs inside container
- `podium node` - Runs inside container
- `podium python` - Runs inside container
- `podium pip` - Runs inside container
- `podium shell` - Runs inside container
- `podium django` - Runs inside container
- `podium exec` - Runs inside container
- `podium exec-root` - Runs inside container
- `podium supervisor` - Runs inside container
- `podium redis` - Direct service connection
- `podium memcache` - Direct service connection

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
~/podium-projects/
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
podium uninstall

# 2. Remove the CLI files
sudo rm -f /usr/local/bin/podium
sudo rm -rf /usr/local/share/podium-cli

# 3. Remove configuration directory (optional)
sudo rm -rf /etc/podium-cli
```

#### 🍎 MacOS (Homebrew)
```bash
# Automatic cleanup - runs 'podium uninstall' then removes CLI
brew uninstall podium-cli

# Manual method (if needed)
podium uninstall
rm -rf /usr/local/bin/podium
sudo rm -rf /etc/podium-cli
```

### What Gets Removed

**`podium uninstall` removes:**
- ✅ All Podium service containers (mariadb, redis, postgres, etc.)
- ✅ All individual project containers
- ✅ Docker images (optional with `--delete-images`)
- ✅ Docker volumes and networks
- ✅ Hosts file entries for services and projects
- ✅ Backs up project docker-compose.yaml files as .backup

**What's preserved:**
- ✅ Your project source code and files
- ✅ Other non-Podium Docker containers and images
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
podium configure
```

`podium configure` also installs **bash tab-completion** (to `/etc/bash_completion.d/podium`). Open a new shell and tab through commands, project names, and installer names:

```
podium ins<TAB>            → install
podium install gr<TAB>     → grafana  graylog  grocy
podium up <TAB>            → (your project names)
podium new <TAB>           → laravel  wordpress  fastapi  django  ...
podium clone <TAB>         → work-directly  fork  new-repo
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
podium help

# Show command-specific help
podium new --help
podium remove --help
```

## 🔍 Troubleshooting

### Common Issues

1. **Services not starting**: Check Docker is running and ports are available
2. **Permission errors**: Ensure user is in `docker` group
3. **Database connection**: Verify database service is running with `podium status`
4. **Port conflicts**: Each project gets a unique port automatically assigned

### Debug Commands

```bash
# Check service status
podium status

# View container logs
docker logs [container-name]

# Check network connectivity
podium exec "ping mariadb"

# Enable debug logging for any command
podium new my-project --debug
podium setup my-project --debug
podium configure --debug

# View debug log
cat /tmp/podium-cli-debug.log
```

### Debug Mode

All Podium commands support a `--debug` flag that creates detailed logs to help troubleshoot issues:

- **Log Location**: `/tmp/podium-cli-debug.log`
- **Session Tracking**: Each new command creates a fresh debug session
- **Detailed Output**: Shows script flow, function calls, and exit codes
- **Cross-Script Tracking**: Debug flag is passed between scripts automatically

**Example:**
```bash
# Debug a project creation issue
podium new laravel test-project --debug

# Check what happened
tail -f /tmp/podium-cli-debug.log
```

---

**Podium** - Streamlined web development with Docker 🐳

### ⚙️ System Management

| Command | Description |
|---------|-------------|
| `podium configure` | Configure the Podium environment |
| `podium ai [--interactive] "<prompt>"` | Send a prompt to your AI agent (one-off by default) |
| `podium ai-set [options]` | Configure the AI agent, model and API key |
| `podium resume <project>` | Resume a project's last AI session |
| `podium update [--full]` | Update the CLI (`--full` also re-runs the platform installer and re-pulls images) |
| `podium start-services` | Start the shared services |
| `podium stop-services` | Stop the shared services |
| `podium enable-service <name>` | Enable an optional shared service (`minio`, `meilisearch`) |
| `podium disable-service <name>` | Disable one (its data volume is kept) |
| `podium uninstall` | Remove Podium's Docker resources |
| `podium projects-dir` | Print the projects directory path |
| `podium create-installer "<idea>"` | Generate a new app installer via AI |
| `podium update-installer <app>\|--all` | Refresh installers against upstream via AI |

---

## Global options

| Option | Description |
|---|---|
| `--json-output` | Machine-readable JSON; suppresses all text and colour |
| `--no-colors` | Disable coloured output |
| `--debug` | Log to `/tmp/podium-cli-debug.log` |

See [Automation & JSON]({{ site.baseurl }}/guide/automation/) for which commands support JSON and how to script against them.
