# 🚀 Podium: The Complete PHP Development Platform

**One command. Complete development environment. Any PHP project.**

Podium is a comprehensive Docker-based development platform that creates professional PHP development environments with complete automation. **Manage multiple projects across different frameworks** - Laravel, WordPress, and generic PHP - all running simultaneously with shared services. Perfect for teams, agencies, and developers who need **easy project access for demos and collaboration**, including LAN access so your boss Frank can check your work from any device on the network.

## ✨ What Makes Podium Special

### 🎯 **Complete Turnkey Experience**
- **One installer** sets up your entire development environment
- **One command** creates ready-to-code projects  
- **Zero manual configuration** - everything works out of the box
- **Cross-platform** - Linux, macOS, Windows (WSL2)

### 🏗️ **Multi-Project Architecture**
- **Run multiple projects simultaneously** - Laravel, WordPress, PHP all at once
- **Cross-framework compatibility** - Mix and match project types
- **Shared services** (MySQL, Redis, phpMyAdmin) serve all projects efficiently
- **Individual project isolation** with unique ports and containers

### 🌐 **Easy Access for Everyone**
- **Local development**: `http://project-name` for your work
- **LAN access**: `http://your-ip:port` for team demos and testing
- **Mobile testing**: Access projects from phones and tablets on your network
- **Client presentations**: Show work to stakeholders from any device

### 🖥️ **GUI Management Interface**
- **Desktop application** for visual project management
- **Real-time status monitoring** with live updates
- **One-click project operations** (start, stop, remove)
- **System health dashboard** with service status
- **Cross-platform** - Linux, Windows, macOS support

## 🎬 Quick Start

### Linux (Ubuntu/Debian) - Recommended
```bash
# Download and install .deb package (fully automated setup)
curl -L -o podium-cli_latest.deb https://github.com/CaneBayComputers/podium-cli/releases/latest/download/podium-cli_latest.deb
sudo dpkg -i podium-cli_latest.deb

# That's it! Everything is configured automatically.
# Log out and back in, then: podium new
```

### macOS
```bash
# Homebrew installation
curl -O https://raw.githubusercontent.com/CaneBayComputers/podium-cli/main/releases/homebrew/podium-cli.rb
brew install --formula ./podium-cli.rb
```

### Windows (WSL2)
```bash
# Install Ubuntu WSL2 first, then:
curl -L -o podium-cli_latest.deb https://github.com/CaneBayComputers/podium-cli/releases/latest/download/podium-cli_latest.deb
sudo dpkg -i podium-cli_latest.deb

# That's it! Everything is configured automatically.
# Make sure Docker Desktop is running with WSL2 integration enabled
```

### GUI Management (Optional)
```bash
# Download the AppImage (Linux)
wget https://github.com/CaneBayComputers/podium-gui/releases/latest/download/Podium.AppImage
chmod +x Podium.AppImage
./Podium.AppImage

# Windows/macOS: Download from releases page
```

## 💻 Basic Development Workflow

### 1. Create Your First Project
```bash
# Log out and back in first (for docker group), then:
podium new my-awesome-app
```
**What happens:**
- Interactive framework selection (Laravel/WordPress/PHP)
- Automatic database setup and connection
- Environment files configured
- Project starts automatically
- **Ready to code immediately!**

### 2. Start Coding!
```bash
# Your project is ready at:
http://my-awesome-app
```

### 3. Daily Workflow
```bash
# Morning: Start everything
podium up

# Work on your projects...
# All projects accessible at http://project-name

# Evening: Clean shutdown (optional)
podium down
```

**That's it!** You now have a professional development environment with zero manual configuration.

## 🛠️ Core Commands

### Project Management

#### Creating New Projects
```bash
podium new [project_name]
```

Creates a new Laravel or WordPress project with:
- Interactive framework selection (Laravel/WordPress/PHP)
- Automatic database setup and connection
- Complete environment configuration
- Project starts automatically

**Examples:**
```bash
# Interactive creation
podium new

# Create with specific name
podium new my-awesome-app
```

#### Cloning Existing Projects
```bash
podium clone <repository> [project_name] [options]
```

Clones a Git repository and automatically sets it up as a Podium project:

**Examples:**
```bash
# Basic clone
podium clone https://github.com/user/my-laravel-app

# Clone with custom name
podium clone https://github.com/user/project my-local-name

# Clone with specific options
podium clone https://github.com/user/project --php-version 8 --overwrite-docker-compose
```

**Options:**
- `--overwrite-docker-compose`: Force overwrite existing Docker configs
- `--php-version VERSION`: Force PHP version (7 or 8)
- `--database ENGINE`: Database type (mysql, postgres, mongo)
- `--display-name NAME`: Custom display name
- `--description TEXT`: Project description
- `--emoji EMOJI`: Project emoji

#### Setting Up Downloaded/Copied Projects
```bash
podium setup <project_name> [options]
```

Configures manually downloaded or copied projects for Podium:

**Use Cases:**
```bash
# Manual Git clone
git clone https://github.com/user/project
podium setup project

# Downloaded ZIP file
# Extract to ~/podium-projects/project/
podium setup project

# Copied project folder
cp -r existing-project ~/podium-projects/new-project
podium setup new-project
```

**Smart Detection:**
- Automatically detects Laravel/WordPress/PHP projects
- Handles existing Docker configurations intelligently
- Prompts before overwriting non-Podium Docker files
- Configures databases, environments, and networking

#### Removing Projects Safely
```bash
podium remove <project_name>
```
- **`<project_name>`**: The name of the project to remove (required)

Safely removes a project by:
- Moving project directory to system trash (recoverable)
- Stopping and removing Docker containers
- Cleaning up database (with confirmation)
- Removing hosts file entries
- Cleaning up all project-related configurations

## 🪄 The Magic Commands - Daily Workflow

Podium is designed around two magic commands that handle your entire development environment:

### ⚡ Morning Startup: `podium up`
```bash
podium up
```
**This single command does everything:**
- Starts all shared services (MariaDB, Redis, PostgreSQL, MongoDB, etc.)
- Starts ALL your project containers automatically
- Configures networking so all projects are accessible
- Shows status of everything that's running
- Makes all your projects available at `http://project-name`

**Perfect morning routine**: Open terminal, type `podium up`, grab coffee while everything starts! ☕

### 🌅 Evening Shutdown: `podium down`
```bash
podium down
```
**This single command cleans up everything:**
- Stops ALL running project containers
- Stops all shared services (databases, caches, etc.)
- Cleans up networking configurations
- Frees up system resources
- Preserves all your data and configurations

**Perfect evening routine**: Finish work, type `podium down`, everything shuts down cleanly! 🌙

### 🤔 Do I Need to Shut Down?

**Short answer: No, but it's nice to!**

- **Shutdown computer without `podium down`**: Docker automatically stops containers and will restart them when you boot up
- **Use `podium down` anyway because**:
  - Frees up RAM and CPU resources immediately
  - Clean shutdown prevents any potential data corruption
  - Good habit for development discipline
  - Useful when switching between different project sets

### 💡 Daily Workflow Examples

```bash
# Monday morning - start everything for the week
podium up

# Tuesday through Thursday - everything keeps running
# (no commands needed, just work on your projects)

# Friday evening - clean shutdown for the weekend  
podium down

# Or just shut down your computer - Docker handles it! 💻
```

### Service Management

#### Redis Commands (Run from anywhere)
```bash
podium redis KEYS "*"          # Run Redis CLI commands
podium redis-flush             # Flush all Redis data
```

#### Memcached Commands (Run from anywhere)
```bash
podium memcache stats          # Show Memcached statistics
podium memcache-flush          # Flush all Memcached data
podium memcache-stats          # Detailed Memcached stats
```

#### Database Commands (Run from anywhere)
```bash
podium db-refresh              # Fresh migration + seed (Laravel)
podium cache-refresh           # Clear all Laravel caches
```

#### Supervisor Commands (Run from project directory)
```bash
# Must be run from within a project directory
cd ~/podium-projects/my-project
podium supervisor status       # Show all supervised processes
podium supervisor restart all  # Restart all processes
```

#### System Status
```bash
podium status                  # Check all projects and services
podium status <project_name>   # Check specific project
```

## 🔧 Essential Development Tools

### The `podium` Command

Podium provides a **single, unified command** that handles all development tasks. No more remembering dozens of aliases or complex Docker commands - just use `podium` followed by what you want to do.

### Why Containerized Tools Matter

Podium uses **containerized development tools** that run inside Docker containers instead of on your host system. This is **crucial for professional PHP development** because:

#### **🎯 Consistent Environment**
- **Same PHP version** across all team members
- **Identical extensions** and configurations  
- **No "works on my machine" problems**
- **Perfect for team collaboration**

#### **🔄 Proper Dependencies**
- **Composer runs with correct PHP version** - ensures packages install correctly
- **WP-CLI uses container's WordPress environment** - commands work reliably  
- **Artisan uses container's Laravel setup** - migrations and commands execute properly
- **No host system conflicts** - your system PHP doesn't interfere

#### **🚀 Professional Workflow Benefits**
- **Switch between PHP versions** per project without system changes
- **Clean host system** - no PHP version conflicts or extension issues
- **Portable environments** - same setup works on any developer's machine
- **Production parity** - development matches server environment

### Containerized Development Commands

**All these commands run inside your project's container with the correct PHP environment:**

#### Composer (Run from project directory)
```bash
cd ~/podium-projects/my-project
podium composer install
podium composer require laravel/sanctum
podium composer update
```

#### Laravel Artisan (Run from project directory)
```bash
cd ~/podium-projects/my-project
podium art migrate
podium art make:controller UserController
podium art tinker
podium art queue:work
```

#### WordPress CLI (Run from project directory)
```bash
cd ~/podium-projects/my-project
podium wp plugin list
podium wp user create john john@example.com --role=administrator
podium wp db export backup.sql
```

#### PHP Commands (Run from project directory)
```bash
cd ~/podium-projects/my-project
podium php -v                  # Check PHP version
podium php script.php          # Run PHP scripts
```

#### Container Access (Run from project directory)
```bash
cd ~/podium-projects/my-project
podium exec bash               # Access container as web user
podium exec-root bash          # Access container as root
```

**Why Containerized?** These commands run with your project's exact PHP version, extensions, and environment - ensuring consistency across team members and preventing "works on my machine" issues.

### System Management
```bash
# Stop all services only (keeps projects running)
podium stop-services

# Configure Podium environment
podium configure
```

### Get Help Anytime
```bash
# See all available commands
podium help
```

## 🤖 JSON Automation & Scripting

Podium supports JSON output for automation and scripting:

### JSON Output Mode
```bash
# Get JSON output for any command
podium status --json-output
podium new my-app --json-output
podium clone https://github.com/user/repo --json-output
```

### Automation Examples
```bash
# Check if services are running in a script
if podium status --json-output | jq -r '.shared_services.mariadb.status' | grep -q "RUNNING"; then
    echo "Database is ready"
fi

# Automated project creation
podium new api-service --json-output | jq -r '.project_name'

# Batch project operations
for project in $(podium status --json-output | jq -r '.projects[].name'); do
    podium up $project --json-output
done

# CI/CD Integration
podium clone $REPO_URL $PROJECT_NAME --json-output --php-version 8
```

### GUI Integration
```bash
# The GUI uses JSON mode internally
podium gui                     # Launch visual interface
```

**GUI Features:**
- Visual project dashboard with real-time status
- One-click project operations (create, start, stop, remove)
- Service health monitoring
- Cross-platform desktop app (Linux, Windows, macOS)

## 🖥️ GUI Management Interface

### Installation
```bash
# Download AppImage (Linux)
wget https://github.com/CaneBayComputers/podium-gui/releases/latest/download/Podium.AppImage
chmod +x Podium.AppImage
./Podium.AppImage

# Or download from releases page for Windows/macOS
# https://github.com/CaneBayComputers/podium-gui/releases
```

## 🌐 Multi-Project Development

Podium excels at **managing multiple projects simultaneously across different frameworks**:

```bash
# Create multiple projects of different types
podium new                    # Interactive project creation
# Choose: WordPress, Laravel, or Basic PHP for each

# All running simultaneously:
# http://client-website     (WordPress)
# http://api-backend        (Laravel)  
# http://legacy-app         (PHP)
```

**Shared services** (MySQL, Redis, phpMyAdmin) serve all projects efficiently while maintaining complete isolation between projects.

## 🔍 Project Status and Access

### Status Display Example:
```text
PROJECT: my-laravel-app
PROJECT FOLDER: ✅ FOUND
HOST ENTRY: ✅ FOUND  
DOCKER STATUS: ✅ RUNNING
DOCKER PORT MAPPING: ✅ MAPPED
LOCAL ACCESS: http://my-laravel-app
LAN ACCESS: http://192.168.1.100:8123
```

### Access Your Projects:
- **Local Development**: `http://project-name` 
- **LAN Testing**: `http://YOUR-IP:PORT` - Perfect for showing Frank your progress from his phone or computer
- **Database Management**: `http://podium-phpmyadmin`

## 🏗️ Architecture Overview

### Shared Services (One Stack for All Projects)
- **MariaDB**: Database server for all projects
- **Redis**: Caching and sessions
- **phpMyAdmin**: Database management interface  
- **Memcached**: Additional caching layer

### Per-Project Containers
Each project gets its own optimized container:
- **Custom Docker Image**: Pre-built with PHP, Nginx, Composer, WP-CLI
- **Automatic Configuration**: Ready-to-use environment
- **Port Mapping**: Unique port for LAN access
- **Volume Mounting**: Live code editing

## 🌍 Cross-Platform Support

### Linux (Ubuntu/Debian)
```bash
# Install via .deb package
sudo dpkg -i podium-cli_latest.deb
```
- **Native .deb package** for optimal performance
- **Automatic dependency installation** (Docker, Git, development tools)
- **System integration** with proper permissions and paths

### macOS
```bash
# Homebrew installation
curl -O https://raw.githubusercontent.com/CaneBayComputers/podium-cli/main/releases/homebrew/podium-cli.rb
brew install --formula ./podium-cli.rb
```
- **Professional Homebrew installation** with dependency management
- **Docker Desktop integration** with automatic setup
- **Apple Silicon (M1/M2) support** with native performance

### Windows (WSL2)
```bash
# Install Ubuntu WSL2, then install Podium
sudo dpkg -i podium-cli_latest.deb
```
- **Full WSL2 compatibility** with Linux performance
- **Docker Desktop integration** with WSL2 backend
- **Windows file system access** for seamless development

## 📁 Project Structure

```
cbc-development/
├── src/
│   ├── docker-stack/              # Infrastructure templates
│   │   ├── docker-compose.services.yaml  # Shared services template
│   │   ├── docker-compose.project.yaml   # Individual project template
│   │   ├── docker-compose.yaml           # Generated services (gitignored)
│   │   └── .env.example                  # Environment template
│   ├── scripts/                   # Core Podium scripts
│   │   ├── configure.sh          # Environment configurator
│   │   ├── new_project.sh        # Project creator
│   │   ├── setup_project.sh      # Project configurator
│   │   ├── clone_project.sh      # Repository cloner
│   │   ├── remove_project.sh     # Safe project removal
│   │   ├── startup.sh            # Service starter
│   │   ├── shutdown.sh           # Service stopper
│   │   ├── status.sh             # Status checker
│   │   ├── functions.sh          # Shared utilities


│   └── hosts.txt                  # Domain mappings
├── projects/                      # Your development projects
│   ├── my-laravel-app/
│   ├── client-website/
│   └── api-backend/
├── packaging/                     # Distribution packages
├── releases/                      # Release artifacts
└── docs/                         # Documentation
```

## 🎯 Perfect For

### Laravel Developers
- **Multiple Laravel versions** (11.x LTS, 10.x)
- **Instant setup** with database, Redis, caching
- **Proper containerized tools** (Composer, Artisan)
- **Multi-project workflows**

### WordPress Developers  
- **Latest WordPress** or specific versions
- **Automatic database setup**
- **WP-CLI ready** in containers
- **Development-optimized** configuration

### PHP Teams
- **Consistent environments** across team members
- **Easy project sharing** and onboarding
- **Professional development workflow**
- **Docker-based isolation**

### Agencies and Freelancers
- **Quick client demos** via LAN access
- **Multiple client projects** running simultaneously  
- **Professional presentation** capabilities
- **Easy stakeholder access** from any device

## 🚀 Advanced Usage

### Containerized Development Tools

**All `podium composer`, `podium art`, and `podium php` commands run inside your project's container.** This ensures:

- **Consistent PHP environment** across all team members
- **Proper dependency resolution** with correct PHP version
- **No host system conflicts** or version mismatches
- **Production parity** - development matches server environment

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

### Project Creation Options

```bash
# Interactive project creation (recommended)
podium new

# Non-interactive with defaults
podium new my-app

# The interactive mode lets you choose:
# - Framework: Laravel, WordPress, or Basic PHP
# - Database: MySQL, PostgreSQL, or MongoDB  
# - PHP Version: Automatically detected or manual selection
# - Project metadata: Display name, description, emoji
```

### Advanced Project Setup

```bash
# Manual project setup with all options
podium setup my-project postgres "My Project" "Cool description" 🚀 --php-version 8

# Clone with full customization
podium clone https://github.com/user/repo my-local-name \
  --database postgres \
  --display-name "Local Development" \
  --description "Development version" \
  --emoji 🛠️ \
  --php-version 8
```

### Safety & Automation Features

- **Smart conflict detection** - Handles existing Docker configurations intelligently
- **Trash integration** - Projects moved to system trash (recoverable), never permanently deleted
- **Automatic backups** - `docker-compose.yaml` files backed up during setup
- **Non-destructive operations** - Confirmation prompts for dangerous actions
- **JSON automation support** - Perfect for CI/CD and scripting

## 💡 Why Use Podium?

### The Problem with Traditional PHP Development
- **Environment inconsistencies** between developers
- **Complex multi-container Docker setups** that are slow and resource-heavy
- **Manual configuration** for each new project
- **Host system pollution** with multiple PHP versions and tools
- **Difficult project sharing** and team onboarding

### The Podium Solution
- **Single command installation** sets up everything
- **Optimized single-container architecture** that's fast and efficient
- **Automatic project configuration** with zero manual setup
- **Clean containerized tools** that don't affect your host system
- **Instant project access** for demos and collaboration
- **Professional GUI interface** for visual management

## 📦 Distribution

### Debian Package (Recommended)
```bash
# Download and install
curl -L -o podium-cli_latest.deb https://github.com/CaneBayComputers/podium-cli/releases/latest/download/podium-cli_latest.deb
sudo dpkg -i podium-cli_latest.deb
```

### macOS Homebrew Formula
```bash
# Download and install via Homebrew
curl -O https://raw.githubusercontent.com/CaneBayComputers/podium-cli/main/releases/homebrew/podium-cli.rb
brew install --formula ./podium-cli.rb
```

---

*Podium: Professional PHP development made simple.* 🎭