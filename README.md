# Podium CLI

Podium is a Docker-based local development environment manager for PHP, Python, and Node projects.

Type `podium create "A timeclock for employees in Django"` and an AI agent scaffolds the full app — migrations, models, routes, templates — running at a local URL with a live database. No Docker knowledge required. No config files to wrestle with.

Podium supports Laravel, FastAPI, Django, WordPress, Express, NestJS, Fastify, and plain Node.js. Every project shares MariaDB, PostgreSQL, Redis, and other services automatically — a Laravel backend and a FastAPI service can talk to the same database on day one with no extra configuration.

Podium runs on Linux and Mac. It is open source. Stop configuring. Start building.

---

**Why developers reach for Podium:**

- **No ports to memorize.** Every project lives at `http://project-name` — automatically. No `localhost:3001` vs `localhost:3002` confusion.
- **One database server for everything.** All your projects share a single MariaDB, PostgreSQL, and Redis instance. Spin up ten projects. They all just work.
- **`podium up` / `podium down`. That's your entire environment.** One command starts everything — all shared services, all project containers. One command stops it all. Come back tomorrow and run `podium up` again.
- **Build custom apps from a sentence.** `podium create "A customer portal in Laravel with subscription billing"` — the AI scaffolds it end to end. Database, models, routes, UI, seeds.
- **Install 24+ popular OSS apps in seconds.** Grafana, Gitea, n8n, Portainer, Nextcloud, and more — fully configured, running, and reachable at their local URL in under two minutes. No YAML to write.
- **AI that knows what to do.** Tell Podium to "set up n8n" and it installs it. Tell it to "set up n8n and add a Slack webhook" and it installs it first, then customizes it. The AI reaches for the right tool automatically.

---

[Install](#-installation) · [Quick Start](#quick-start) · [One-Command App Library](#-one-command-app-library) · [Commands](#-commands-overview) · [AI Create](#-ai-assisted-project-creation) · [JSON API](#-json-api-integration) · [Uninstall](#uninstallation)


## 💾 Installation


### Option A: One-line installer (recommended)

Use this when you just want Podium installed quickly.


#### 🐧 Linux (Debian / Ubuntu / Ubuntu-based)

Podium CLI works best in Linux!

```bash
# One-liner install
curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-ubuntu.sh | bash

# Configure your development environment post installation
podium configure
```

#### 🐧 Linux (Arch / Arch-based)

On Arch Linux and Arch-based distributions:

```bash
# One-liner install
curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-arch.sh | bash

# Configure your development environment post installation
podium configure
```

This installs Docker, Node.js, Git, `jq`, `trash-cli`, and other utilities via `pacman`, then sets up the Podium CLI and `podium` command.


#### 🍎 MacOS

```bash
# One-liner install
curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-mac.sh | bash

# Configure your development environment post installation
podium configure
```

**Note:** You might need to start Docker Desktop manually after installation.


#### 🪟 Windows

Podium CLI runs best on Linux, period. You can try WSL but it is not officially supported. Windows/WSL issues will not be addressed nor fixed.

---

### Option B: Clone first, then run the installer (development / local checkout)

Use this when you already have the repo checked out (or you want to hack on Podium CLI itself). If you run an installer from inside a `podium-cli` checkout, it will **skip `git clone`** and instead link `/usr/local/share/podium-cli` to your existing folder (and still create `/usr/local/bin/podium`).

```bash
git clone https://github.com/CaneBayComputers/podium-cli.git
cd podium-cli
```

- Ubuntu/Debian: `./install-ubuntu.sh`
- Arch: `./install-arch.sh`
- macOS: `./install-mac.sh`


## Quick Start

### Let an AI build your first project

```bash
podium create
```

Describe what you want in plain English. Podium adds project creation instructions and sends your idea to your configured AI CLI. The AI creates the project, wires up the database and environment, builds the app using framework-native conventions, and updates the project README with the local URL and any default credentials.

```bash
podium create "A timeclock for employees in Django"
podium create "A customer check-in system in Laravel"
podium create "An inventory tracker in Express"
```

The AI CLI can be cloud-based or local depending on your configuration. See [AI-assisted project creation](#-ai-assisted-project-creation) and `podium ai-set` for setup details.

### Or create a project manually

```bash
podium new
```

Common project types:

- Laravel API / app:
  ```bash
  podium new my-laravel-app --framework laravel
  ```
- WordPress site:
  ```bash
  podium new my-wp-site --framework wordpress
  ```
- FastAPI project:
  ```bash
  podium new my-api --framework fastapi
  ```
- Django project:
  ```bash
  podium new my-django-app --framework django
  ```
- Plain Python project:
  ```bash
  podium new my-script --framework python
  ```
- Express project:
  ```bash
  podium new my-express-app --framework express
  ```
- NestJS project:
  ```bash
  podium new my-nest-app --framework nestjs
  ```
- Fastify project:
  ```bash
  podium new my-fastify-app --framework fastify
  ```
- Plain Node.js project:
  ```bash
  podium new my-node-app --framework node
  ```
- Empty PHP project:
  ```bash
  podium new my-php-app --framework php
  ```

### Or use an existing project

Clone a Git repository and set it up automatically:

```bash
podium clone https://github.com/user/my-laravel-app
podium clone owner/repo                              # GitHub shorthand
```

Already have a project folder in your projects directory? Just set it up:

```bash
podium setup my-project
```

Or point `podium create` at an existing GitHub repo and let the AI clone and configure it:

```bash
podium create "https://github.com/monicahq/monica"
```


## ⚡ One-Command App Library

Stop copy-pasting docker-compose files from GitHub. Podium ships with battle-tested installers for the most popular self-hosted apps. One command. Fully configured. Running at a local URL in under two minutes.

```bash
podium install portainer     # Docker management UI
podium install grafana       # Monitoring dashboards
podium install gitea         # Self-hosted Git server
podium install n8n           # Workflow automation
podium install nextcloud     # File hosting
podium install wikijs        # Team wiki
podium install paperless     # Document management
podium install jellyfin      # Media server
```

See everything available:

```bash
podium install --list
```

Each installer handles the entire setup: creates the right databases, generates secrets, writes the compose file, assigns a VPC IP, starts the container, and waits for HTTP 200. No YAML. No env wrangling. No docs to read.

### AI installs it for you too

The `podium create` AI agent knows about every installer. When you describe a known app, it reaches for the installer automatically — then continues with any customization you asked for:

```bash
# Agent sees "n8n", runs `podium install n8n`, then sets up the webhook
podium create "Set up n8n and configure a webhook that posts to Slack"

# Agent installs Gitea, then creates the org and configures SSH
podium create "I need a private Git server called dev-forge, set it up and create a DevOps org"

# Just install — no customization prompt needed
podium create "New Grafana"
```

The installed app lands at `http://<app-name>/` immediately. From there, `podium ai` can continue customizing it in an interactive session.

### Available apps

| App | One-liner | Category |
|-----|-----------|----------|
| Changedetection.io | `podium install changedetection` | Monitoring |
| Dashy | `podium install dashy` | Dashboard |
| Flame | `podium install flame` | Dashboard |
| FreshRSS | `podium install freshrss` | RSS |
| Grafana | `podium install grafana` | Monitoring |
| Grocy | `podium install grocy` | Home |
| Heimdall | `podium install heimdall` | Dashboard |
| IT Tools | `podium install it-tools` | Utilities |
| Kanboard | `podium install kanboard` | Project Mgmt |
| Kimai | `podium install kimai` | Time Tracking |
| LimeSurvey | `podium install limesurvey` | Surveys |
| Lychee | `podium install lychee` | Photos |
| Mealie | `podium install mealie` | Recipes |
| Memos | `podium install memos` | Notes |
| Miniflux | `podium install miniflux` | RSS |
| Netdata | `podium install netdata` | Monitoring |
| Portainer | `podium install portainer` | Docker UI |
| Redmine | `podium install redmine` | Project Mgmt |
| Snipe-IT | `podium install snipe-it` | Asset Mgmt |
| Stirling PDF | `podium install stirling-pdf` | Utilities |
| Umami | `podium install umami` | Analytics |
| Vaultwarden | `podium install vaultwarden` | Passwords |
| Vikunja | `podium install vikunja` | Task Mgmt |
| Wallabag | `podium install wallabag` | Read Later |

---

## 🪄 The Magic Commands - Daily Workflow

Podium is designed around two magic commands that handle your entire development environment:

### ⚡ `podium up`
```bash
podium up
```
**Starts everything:**
- Starts all shared services (MariaDB, Redis, PostgreSQL, MongoDB, etc.)
- Starts ALL your project containers automatically
- Configures networking so all projects are accessible
- Shows status of everything that's running
- Makes all your projects available at `http://project-name`

### 🛑 `podium down`
```bash
podium down
```
**Stops everything:**
- Stops ALL running project containers
- Stops all shared services (databases, caches, etc.)
- Cleans up networking configurations
- Frees up system resources
- Preserves all your data and configurations

## 📋 Commands Overview

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
| `podium up [project]` | Start project containers |
| `podium down [project]` | Stop project containers |
| `podium status [project]` | Show project status |
| `podium new [options]` | Create new project |
| `podium create [--one-off] ["idea"]` | Create a project from a plain English description (AI) |
| `podium install <app>` | Install a popular OSS app in one command (`--list` to see all) |
| `podium clone <repo>` | Clone existing project |
| `podium setup <project> [options]` | Set up an existing project directory |
| `podium remove <project> [options]` | Remove project |

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
podium ai-set --agent ollama --model llama3.1
podium ai-set --agent codex --model gpt-4.1
podium ai-set --json-output
```

Supported flags:

- `--agent <name>` – Set the AI agent CLI (`codex`, `claude`, `gemini`, or a custom command name).
- `--model <name>` – Set the model name (optional for all supported agents).
- `--api-key <key>` – Set the AI API key (optional for Codex and Claude; not used by Gemini which uses Google account auth).
- `--json-output` – Return the current configuration or update result as JSON (non-interactive).

Examples:

- Inspect current AI settings:
  - `podium ai-set --json-output`
- Configure Codex with a model:
  - `podium ai-set --agent codex --model gpt-4.1`
- Configure Claude with a model:
  - `podium ai-set --agent claude --model claude-opus-4-7`

### 🤖 AI-assisted project creation

`podium create` collects your project idea, adds Podium-specific instructions, and hands the combined prompt to your configured AI CLI. Podium sets up the environment. The AI builds the app.

```bash
# Podium will prompt you for an idea
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

By default `podium ai` launches an **interactive** session — the agent starts up, receives the prompt as its first message, and stays open so you can continue the conversation. Add `--one-off` to run a single non-interactive prompt and exit (useful for automation and scripted pipelines):

```bash
podium ai --one-off "Add a health-check endpoint at /ping"
```

`podium ai` / `podium create`:

- Looks up your configured `AI_AGENT`, `AI_MODEL`, and `AI_API_KEY` from `/etc/podium-cli/.env`.
- Starts an interactive AI agent session (or non-interactive with `--one-off`) seeded with the prompt using safe, automation-friendly flags:
  - Codex: `codex [--model "$AI_MODEL"] [--api-key "$AI_API_KEY"] --dangerously-bypass-approvals-and-sandbox "<prompt>"` (interactive) / `codex exec ...` (one-off)
  - Claude: `claude --dangerously-skip-permissions [-p] [--model "$AI_MODEL"] [--api-key "$AI_API_KEY"] "<prompt>"` (`-p` added for `--one-off`)
  - Gemini: `gemini --yolo --skip-trust [--model "$AI_MODEL"] -i "<prompt>"` (interactive) / `... --output-format text --prompt ...` (one-off)

## 🎯 Command Options

### Global Options

| Option | Description |
|--------|-------------|
| `--json-output` | Clean JSON output (suppresses all text/colors) |
| `--no-colors` | Disable colored output |
| `--debug` | Enable debug logging to `/tmp/podium-cli-debug.log` |

### New Project Options

| Option | Description | Values |
|--------|-------------|---------|
| `--framework <name>` | Framework type | `laravel` (default), `wordpress`, `php`, `fastapi`, `django`, `python`, `express`, `nestjs`, `fastify`, `node` |
| `--version <ver>` | Framework version | **Laravel:** `latest` (default), any valid Laravel version tag<br/>**WordPress:** `latest` (default), any valid WordPress version |
| `--database <type>` | Database type | `mysql` (default), `postgres`, `mongodb` |
| `--github` | Create GitHub repository in user account | Requires GitHub CLI authentication |
| `--github-org <org>` | Create GitHub repository in organization | Requires GitHub CLI authentication |
| `--no-github` | Skip GitHub repository creation (default) | - |
| `--no-storage-symlink` | Skip creating `public/storage` symlink | (Laravel only) |

### Clone Project Options

| Option | Description |
|--------|-------------|
| `--overwrite-docker-compose` | Overwrite existing docker-compose.yaml without prompting |
| `--database <type>` | Database type (`mysql`, `postgres`, `mongodb`) |
| `--framework <name>` | Force framework detection (`laravel`, `wordpress`, `php`, `fastapi`, `django`, `python`, `express`, `nestjs`, `fastify`, `node`) |
| `--no-startup` | Register and adapt project without starting the container — use this to inspect the adapted docker-compose before running `podium up` |
| `--github` | Create GitHub repository in user account |
| `--github-org <org>` | Create GitHub repository in organization |
| `--no-github` | Skip GitHub repository creation |
| `--no-storage-symlink` | Skip creating `public/storage` symlink (Laravel) |

> **Complex projects**: When cloning a project that ships its own multi-service docker-compose (bundled database, cache, workers), Podium automatically adapts it: bundled DB/cache services are removed and their env vars are repointed to Podium's shared containers (`podium-postgres`, `podium-mariadb`, `podium-redis`, `podium-mongo`). The web-facing service gets a static VPC IP. Startup is deferred so you can verify the adapted compose before running `podium up <project>`.

### Setup Project Options

| Option | Description |
|--------|-------------|
| `--overwrite-docker-compose` | Overwrite existing docker-compose.yaml without prompting |
| `--framework <type>` | Force framework detection (`laravel`, `wordpress`, `php`, `fastapi`, `django`, `python`, `express`, `nestjs`, `fastify`, `node`) |
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
| `--projects-dir <dir>` | Custom projects directory |

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
# Create a WordPress project with PostgreSQL
podium new wp-site --framework wordpress --version latest --no-github

# Install and activate plugins
podium wp plugin install woocommerce --activate
podium wp plugin list --status=active
```

### JSON Output for Automation

```bash
# Get project status as JSON for scripts/GUI
podium status --json-output

# Create project with JSON response
podium new my-api --framework fastapi --database postgres --no-github --json-output

# Check if services are running in a script
if podium status --json-output | jq -r '.shared_services.mariadb.status' | grep -q "RUNNING"; then
    echo "Database is ready"
fi

# Batch project operations
for project in $(podium status --json-output | jq -r '.projects[].name'); do
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
const result = await exec('podium new myapp --framework laravel --version 11.x --database mysql --no-github --json-output');
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
podium new test-project --framework laravel --debug

# Check what happened
tail -f /tmp/podium-cli-debug.log
```

---

**Podium** - Streamlined web development with Docker 🐳
