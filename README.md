# Podium CLI - PHP Development Environment

Podium CLI is a powerful command-line interface for managing Docker-based PHP development environments. It provides seamless support for Laravel, WordPress, and custom PHP applications with integrated database services, caching, and development tools.

Built for modern PHP development, Podium CLI eliminates the complexity of managing multiple local environments by containerizing everything while maintaining the simplicity developers love. Whether you're building a single Laravel API or managing dozens of WordPress sites, Podium handles the infrastructure so you can focus on writing code. Each project gets its own isolated environment with automatic database setup, intelligent port management, and instant LAN sharing for client demos.

## 📊 Why Choose Podium?

| Feature | Podium | Traditional Setup | Benefits |
|---------|--------|------------------|----------|
| **Multi-Project Support** | ✅ Unlimited isolated projects | ❌ Complex VHOST management | Run dozens of projects simultaneously |
| **Database Management** | ✅ Auto-created per project | ❌ Manual database setup | Zero configuration databases |
| **LAN Sharing** | ✅ Instant team access | ❌ Complex network setup | Share demos instantly |
| **Service Integration** | ✅ Redis, Memcached, MailHog, etc. | ❌ Manual installation | All services ready to use |
| **GUI Interface** | ✅ Modern desktop app | ❌ Terminal only | Visual project management |
| **Email Testing** | ✅ Built-in MailHog | ❌ External tools needed | Catch and debug emails |
| **AI Integration** | ✅ Local Ollama service | ❌ No AI tools | Local LLM for development |
| **Port Management** | ✅ Automatic assignment | ❌ Manual port conflicts | No configuration needed |

## 💾 Installation

### 🐧 Linux (Ubuntu/Debian)

```bash
curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install.sh | bash
```

**What it installs:**
- Docker CE with Compose plugin
- Node.js 20 with NPM
- GitHub CLI
- MariaDB client, p7zip, trash-cli, net-tools
- All system dependencies

**Quick Start:**
```bash
# Install and configure Podium
podium config

# Create a new project
podium new my-project

# Check status
podium status
```

---

### 🍎 macOS

```bash
curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-mac.sh | bash
```

**What it installs:**
- Homebrew (if not installed)
- Docker Desktop
- Node.js with NPM
- GitHub CLI
- Additional tools: jq, p7zip, trash, mysql-client

**Note:** You'll need to start Docker Desktop manually after installation.

**Quick Start:**
```bash
# Install and configure Podium
podium config

# Create a new project
podium new my-project

# Check status
podium status
```

---

### 🪟 Windows

Podium CLI runs on Windows through **WSL2** (Windows Subsystem for Linux). This provides a full Linux environment with excellent Docker integration.

```powershell
# Download and run the Windows installer (PowerShell as Administrator)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-windows.ps1" -OutFile "install-windows.ps1"
PowerShell -ExecutionPolicy Bypass -File install-windows.ps1
```

**What the installer does:**
- Installs WSL2 (Windows Subsystem for Linux)
- Installs Ubuntu distribution
- Downloads and installs Docker Desktop
- Configures Docker for WSL2 integration
- Installs Podium CLI inside WSL2
- Tests the complete installation

**Quick Start:**
```powershell
# Open WSL2 terminal
wsl

# Install and configure Podium
podium config

# Create a new project
podium new my-project

# Check status
podium status
```

## 🎨 Podium GUI

Looking for a visual interface? **Podium GUI** provides a modern desktop application with:

- 🎯 **Visual Project Management** - Create and manage projects with clicks
- 📊 **Real-time Monitoring** - Live status updates and service management
- 🎨 **Modern Interface** - Beautiful retro synthwave design
- ⚡ **One-Click Operations** - Start/stop services instantly

**Get Podium GUI**: Contact Cane Bay Computers for download and licensing information.

## 📋 Commands Overview

### 🛠️ Development Tools
*Run from project directory*

| Command | Description |
|---------|-------------|
| `podium composer <args>` | Run Composer commands inside container |
| `podium art <args>` | Run Laravel Artisan commands |
| `podium wp <args>` | Run WordPress CLI commands |
| `podium php <args>` | Run PHP inside container |

### 📦 Container Execution
*Run from project directory*

| Command | Description |
|---------|-------------|
| `podium exec <cmd>` | Execute command as developer user |
| `podium exec-root <cmd>` | Execute command as root user |

### ⚡ Enhanced Laravel Commands
*Run from project directory*

| Command | Description |
|---------|-------------|
| `podium db-refresh` | Fresh migration + seed |
| `podium cache-refresh` | Clear all Laravel caches |

### 🔧 Service Management

| Command | Description |
|---------|-------------|
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
| `podium clone <repo>` | Clone existing project |
| `podium remove <project> [options]` | Remove project |

### ⚙️ System Management

| Command | Description |
|---------|-------------|
| `podium config` | Configure Podium environment |
| `podium start-services` | Start shared services |
| `podium stop-services` | Stop shared services |
| `podium config projects <path>` | Set custom projects directory |
| `podium gui` | Launch desktop GUI interface |

### 🧪 Testing

| Command | Description |
|---------|-------------|
| `podium test-interactive` | Run interactive test suite |
| `podium test-json-output` | Run JSON output test suite |

## 🎯 Command Options

### Global Options

| Option | Description |
|--------|-------------|
| `--json-output` | Clean JSON output (suppresses all text/colors) |
| `--no-colors` | Disable colored output |

### New Project Options

| Option | Description | Values |
|--------|-------------|---------|
| `--framework <name>` | Framework type | `laravel` (default), `wordpress`, `php` |
| `--version <ver>` | Framework/PHP version | **Laravel:** `latest` (default), any valid Laravel version tag<br/>**WordPress:** `latest` (default), any valid WordPress version<br/>**PHP:** `8` (default - PHP 8.3), `7` (PHP 7.4) |
| `--database <type>` | Database type | `mysql` (default), `postgres`, `mongodb` |
| `--github` | Create GitHub repository in user account | Requires GitHub CLI authentication |
| `--github-org <org>` | Create GitHub repository in organization | Requires GitHub CLI authentication |
| `--no-github` | Skip GitHub repository creation (default) | - |

### Remove Project Options

| Option | Description |
|--------|-------------|
| `--force` | Skip confirmation prompts |
| `--force-db-delete` | Force database deletion without prompt |
| `--preserve-database` | Keep database (skip deletion) |

## 💡 Usage Examples

### Basic Development Workflow

```bash
# Create a new Laravel project with MySQL
podium new blog-app --framework laravel --database mysql --no-github

# Navigate to project and install dependencies
cd ~/podium-projects/blog-app
podium composer install

# Run migrations and seeders
podium art migrate --seed

# Start the project
podium up blog-app

# Check project status
podium status blog-app
```

### WordPress Development

```bash
# Create a WordPress project with PostgreSQL
podium new wp-site --framework wordpress --version latest --database postgres --no-github

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

# Start services with JSON confirmation
podium start-services --json-output
```

### Service Management

```bash
# Start all shared services
podium start-services

# Check Redis status and flush cache
podium redis ping
podium redis-flush

# Monitor supervised processes
podium supervisor-status
podium supervisor restart all
```

### Advanced Usage

```bash
# Create Laravel project with GitHub integration
podium new enterprise-app --framework laravel --version 11.x --database postgres --github --non-interactive

# Execute custom commands in container
podium exec "php -v"
podium exec-root "apt update && apt install -y vim"

# Remove project but preserve database
podium remove old-project --force --preserve-database
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

- `podium status --json-output` - Project and service status
- `podium new --json-output` - Project creation confirmation
- `podium remove --json-output` - Project removal confirmation
- `podium start-services --json-output` - Service start confirmation
- `podium stop-services --json-output` - Service stop confirmation
- `podium up --json-output` - Project startup confirmation
- `podium down --json-output` - Project shutdown confirmation

## 🏗️ Architecture

### Services Included

- **MariaDB** - Primary database service
- **PostgreSQL** - Alternative database option
- **MongoDB** - NoSQL database option
- **Redis** - Caching and session storage
- **Memcached** - Additional caching layer
- **phpMyAdmin** - Database management interface
- **MailHog** - Email testing and debugging (captures outbound emails)
- **Ollama** - Local LLM/AI service for development

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

## 📱 GUI Interface

Launch the desktop GUI with:

```bash
podium gui
```

The GUI provides:
- Visual project management
- One-click project creation
- Service status monitoring
- Real-time logs and output
- Dark theme with modern UI

## 🔧 Configuration

### Initial Setup

```bash
# Run the configuration wizard
podium config

# Set custom projects directory
podium config projects /path/to/projects
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
```

---

**Podium** - Streamlined PHP development with Docker 🐳