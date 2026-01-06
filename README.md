# Podium CLI - PHP and Python Development Environment

Built for modern PHP and Python development, Podium CLI eliminates the complexity of managing multiple local environments by containerizing everything while maintaining the simplicity developers love. Whether you're building a single Laravel API, managing dozens of WordPress sites, or supporting a front-end with FastAPI, Podium handles the infrastructure so you can focus on writing code. Each project gets its own isolated environment with automatic database setup, intelligent port management, and instant LAN sharing for client demos. Backed by Docker, it provides seamless support for Laravel, FastAPI, Django, WordPress, and custom PHP or Python applications with integrated database services, caching, and development tools.


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

**What it installs:**
- Docker CE with Compose plugin
- Node.js 20 with NPM
- GitHub CLI
- jq, trash-cli
- All system dependencies

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

**What it installs:**
- Homebrew (if not installed)
- Docker Desktop
- Node.js with NPM
- GitHub CLI
- Additional tools: jq, trash

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

**Open a terminal and start your first Podium project:**
```bash
podium new
```

## Kavera AI-Ready Website
```bash
# Create a new Kavera website project (AI website creation platform)
podium kavera my-kavera-site
```

Kavera (https://github.com/CaneBayComputers/kavera) is an AI‑agent‑first Laravel website framework: pages are flat-file Blade templates on purpose so agents can safely read, edit, and rearrange content without fighting a CMS, while service-driven integrations (Blogger, Eventbrite, Flickr, webhooks, etc.) stream dynamic data into the site. Paired with Podium, it lets you spin up agent-managed, production-ready marketing sites in minutes instead of weeks.

Other common project types:

- Laravel API / app:
  ```bash
  podium new my-laravel-app --framework laravel
  ```
- Kavera site without auto prompts:
  ```bash
  podium new my-kavera-site --framework kavera
  ```
- WordPress site:
  ```bash
  podium new my-wp-site --framework wordpress
  ```
- Empty PHP project:
  ```bash
  podium new my-php-app --framework php
  ```



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
| `podium kavera <name> [options]` | Create and initialize a new Kavera flat-file site |
| `podium clone <repo>` | Clone existing project |
| `podium remove <project> [options]` | Remove project |

### ⚙️ System Management

| Command | Description |
|---------|-------------|
| `podium configure` | Configure Podium environment |
| `podium ai-set [options]` | Configure global AI agent, model, and API key (for Kavera and tooling) |
| `podium update` | Update Podium CLI and base Docker images |
| `podium stop-services` | Stop shared services |
| `podium uninstall` | Remove all Podium Docker resources |
| `podium projects-dir` | Show projects directory path |
| `podium gui` | Launch desktop GUI interface |

#### `podium ai-set` options

`podium ai-set` manages the global AI agent CLI, model, and API key used by Podium (for example by `podium kavera` when bootstrapping a Kavera site).

```bash
podium ai-set --agent ollama --model llama3.1
podium ai-set --agent codex --model gpt-4.1
podium ai-set --json-output
```

Supported flags:

- `--agent <name>` – Set the AI agent CLI (for example: `codex`, `claude`, `gemini`, `deepseek`, `grok`, or a custom command).
- `--model <name>` – Set the model name; optional for `codex`, `claude`, and `grok`. Ignored for `gemini` and `deepseek` in the current flow.
- `--api-key <key>` – Set the AI API key, required by DeepSeek and Grok, optional for Codex, Claude, and Gemini.
- `--json-output` – Return the current configuration or update result as JSON (non-interactive).

Examples:

- Inspect current AI settings:
  - `podium ai-set --json-output`
- Configure Grok with an explicit model:
  - `podium ai-set --agent grok --model grok-beta`
- Configure Claude with a model:
  - `podium ai-set --agent claude --model claude-3.7-sonnet`

### 🤖 One-off AI prompts

Once you have set your global AI agent with `podium ai-set`, you can run a one-off AI prompt from any Podium project directory:

```bash
cd /path/to/project
podium ai "Build a unique homepage hero section."
```

`podium ai "<one-off prompt>"`:
`podium ai "<initial prompt>"`:

- Looks up your configured `AI_AGENT`, `AI_MODEL`, and `AI_API_KEY` from `/etc/podium-cli/.env`.
- Starts an interactive AI agent session and seeds it with the initial prompt using safe, automation-friendly flags:
  - DeepSeek: `deepseek --api-key "$AI_API_KEY" -q "<prompt>"`
  - Codex: `codex [--model "$AI_MODEL"] [--api-key "$AI_API_KEY"] --yolo "<prompt>"`
  - Claude: `claude --dangerously-skip-permissions [--model "$AI_MODEL"] [--api-key "$AI_API_KEY"] "<prompt>"`
  - Gemini: `gemini [--api-key "$AI_API_KEY"] -i "<prompt>"`
  - Grok: `grok [--model "$AI_MODEL"] --api-key "$AI_API_KEY" "<prompt>"`

When you run `podium kavera`, Podium automatically generates a Kavera-specific initial prompt and calls `podium ai "<that prompt>"` from the new project directory.

### 🧪 Testing & Utilities

| Command | Description |
|---------|-------------|
| `podium test-json-output [test_name]` | Run comprehensive JSON output test suite (optionally run specific test) |
| `podium cleanup-test-environment` | Clean up test resources (containers, networks, files) |

**Test Suite Features:**
- Tests all JSON commands for proper output format
- Validates project creation, setup, cloning, removal
- Tests different frameworks (Laravel, WordPress, PHP)
- Tests different PHP versions and database engines
- Isolated test environment using `podium_test_` prefix
- Comprehensive cleanup of all test resources
- Visual test reports with pass/fail status
- Debug logging for troubleshooting failures

**Run specific tests for debugging:**
```bash
# Run all tests
podium test-json-output

# Run specific test only
podium test-json-output new_laravel_latest
podium test-json-output remove_project
podium test-json-output clone_project

# Clean up test resources manually
podium cleanup-test-environment
```

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
| `--framework <name>` | Framework type | `laravel` (default), `wordpress`, `php`, `kavera` |
| `--display-name <name>` | Display name for project | Required with `--json-output` |
| `--version <ver>` | Framework/PHP version | **Laravel:** `latest` (default), any valid Laravel version tag<br/>**WordPress:** `latest` (default), any valid WordPress version<br/>**PHP:** `8` (default - PHP 8.3), `7` (PHP 7.4) |
| `--database <type>` | Database type | `mysql` (default), `postgres`, `mongodb` |
| `--description <text>` | Project description | Optional text description |
| `--emoji <emoji>` | Project emoji | Will prompt if not provided |
| `--github` | Create GitHub repository in user account | Requires GitHub CLI authentication |
| `--github-org <org>` | Create GitHub repository in organization | Requires GitHub CLI authentication |
| `--no-github` | Skip GitHub repository creation (default) | - |
| `--no-storage-symlink` | Skip creating `public/storage` symlink | (Laravel/Kavera only) |

### Clone Project Options

| Option | Description |
|--------|-------------|
| `--overwrite-docker-compose` | Overwrite existing docker-compose.yaml without prompting |
| `--php-version <ver>` | Force specific PHP version | `7` or `8` |
| `--database <type>` | Database type | `mysql`, `postgres`, `mongodb` |
| `--display-name <name>` | Display name for project | Optional |
| `--description <text>` | Project description | Optional |
| `--emoji <emoji>` | Project emoji | Default: 🚀 |
| `--github` | Create GitHub repository in user account | Requires GitHub CLI authentication |
| `--github-org <org>` | Create GitHub repository in organization | Requires GitHub CLI authentication |
| `--no-storage-symlink` | Skip creating `public/storage` symlink | (Laravel projects) |

### Setup Project Options

| Option | Description |
|--------|-------------|
| `--overwrite-docker-compose` | Overwrite existing docker-compose.yaml without prompting |
| `--php-version <ver>` | Force specific PHP version | `7` or `8` |
| `--framework <type>` | Force specific framework | `laravel`, `wordpress`, `php` |

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

### Test Suite Options

| Option | Description |
|--------|-------------|
| `[test_name]` | Run specific test only (e.g., `new_laravel_latest`) |

## 💡 Usage Examples

### Cloning and Setting Up Projects

```bash
# Clone a Git repository and set it up automatically
podium clone https://github.com/user/my-laravel-app

# Clone with custom name and options
podium clone https://github.com/user/company-project my-local-name --php-version 8

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

# Create PHP 7.4 project with JSON response
podium new legacy-api --framework php --version 7 --database postgres --no-github --json-output

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

**All `podium composer`, `podium art`, and `podium php` commands run inside your project's container** with the correct PHP environment:

```bash
# These commands run inside the container with project-specific PHP/extensions
cd ~/podium-projects/my-laravel-app
podium composer install        # Uses container's PHP 8.2
podium art migrate            # Runs with container's Laravel setup
podium php script.php         # Executes with project's PHP configuration

# Switch to different project with different PHP version
cd ~/podium-projects/legacy-app  
podium composer install        # Uses container's PHP 7.4
podium php old-script.php     # Runs with PHP 7.4 environment
```


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


## 🗑️ Uninstallation


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

- **Directory Requirements**: Development tools (`composer`, `art`, `wp`, `php`, `exec`, `supervisor`) must be run from within a project directory
- **JSON Output**: Use `--json-output` for programmatic integration (GUI, scripts, automation)
- **Non-Interactive Mode**: Use `--non-interactive` with sensible defaults for automated deployment
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

**Podium** - Streamlined PHP development with Docker 🐳
