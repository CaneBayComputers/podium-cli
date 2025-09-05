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

### Create Your First Project
```bash
# Log out and back in first (for docker group), then:
podium new
```

### Start Coding! 
```bash
# Your project is ready at:
http://your-project-name
```

**You now have a fully configured development environment with:**
- ✅ Running Laravel/WordPress application
- ✅ Database configured and connected
- ✅ Redis caching ready
- ✅ phpMyAdmin for database management
- ✅ Professional development tools
- ✅ **No manual configuration needed!**

## 🛠️ Core Commands

### Project Management

#### Creating New Projects
```bash
podium new [project_name] [organization]
```
- **`[project_name]`**: Optional name for your new project
- **`[organization]`**: Optional GitHub organization for repository creation

Creates a new Laravel or WordPress project with:
- Interactive framework selection (Laravel/WordPress)
- Version selection (Laravel 11.x, 10.x or WordPress latest/6.x)
- Automatic GitHub repository creation
- Complete environment configuration
- Database setup and connection

#### Cloning Existing Projects
```bash
podium clone <repository> [project_name] [options]
```
- **`<repository>`**: The URL of the repository to clone (required)
- **`[project_name]`**: Optional custom name for the cloned project

**Options:**
- **`--overwrite-docker-compose`**: Overwrite existing docker-compose.yaml without prompting
- **`--php-version VERSION`**: Force specific PHP version (7 or 8)
- **`--json-output`**: Output results in JSON format
- **`--no-colors`**: Disable colored output

Clones an existing project and automatically:
- Downloads the repository
- Intelligently detects existing Docker configurations
- Handles Podium projects seamlessly (auto-reconfigures)
- Prompts for non-Podium docker-compose.yaml conflicts
- Detects project type (Laravel/WordPress/PHP)
- Configures environment files
- Sets up database connections
- Starts the development environment

**Examples:**
```bash
# Basic clone
podium clone https://github.com/user/my-laravel-app

# Clone with custom name and PHP version
podium clone https://github.com/user/project my-local-name --php-version 8

# Force overwrite any existing Docker config
podium clone https://github.com/user/project --overwrite-docker-compose
```

#### Setting Up Downloaded Projects
```bash
podium setup <project_name> [database_engine] [display_name] [description] [emoji] [options]
```
- **`<project_name>`**: The name of the project directory (required)
- **`[database_engine]`**: Database type: mysql, postgres, mongo (default: mysql)
- **`[display_name]`**: Display name for project (optional)
- **`[description]`**: Project description (optional)
- **`[emoji]`**: Project emoji (default: 🚀)

**Options:**
- **`--overwrite-docker-compose`**: Overwrite existing docker-compose.yaml without prompting
- **`--php-version VERSION`**: Force specific PHP version (7 or 8)
- **`--json-output`**: Output results in JSON format
- **`--no-colors`**: Disable colored output

Configures an already downloaded project by:
- Intelligently detecting existing Docker configurations
- Handling Podium projects seamlessly (auto-reconfigures)
- Prompting for non-Podium docker-compose.yaml conflicts
- Detecting PHP version requirements from composer.json
- Creating Docker Compose configuration
- Setting up environment files (.env for Laravel, wp-config.php for WordPress)
- Creating and configuring project database
- Running migrations and setup commands
- Starting the project container

**Use Cases:**
- Manual Git clones: `git clone repo && podium setup project`
- Downloaded ZIP files: Extract and `podium setup project`
- Copied project folders: `podium setup copied-project`
- Re-configuring existing Podium projects

**Examples:**
```bash
# Basic setup
podium setup my-downloaded-project

# Setup with specific database and PHP version
podium setup my-project postgres "My Project" "A cool project" 🚀 --php-version 8

# Force overwrite existing Docker config
podium setup existing-project --overwrite-docker-compose
```

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

### Service Management

#### Starting Everything
```bash
# Turn everything on - the magic command!
podium up
```
**What it does:**
- Starts all shared services (MariaDB, Redis, PostgreSQL, etc.)
- Starts ALL project containers automatically
- Configures networking and port mapping
- Makes all projects accessible via browser
- Perfect "turn on my computer and get to work" command

#### Starting Specific Projects
```bash
# Start just one project (services start automatically if needed)
podium up <project_name>
```
- Starts shared services if not already running
- Starts the specific project container
- Configures networking for that project only

#### Stopping Everything
```bash
# Turn everything off - the magic shutdown command!
podium down
```
**What it does:**
- Stops ALL running project containers
- Stops all shared services (MariaDB, Redis, etc.)
- Cleans up all networking configurations
- Preserves all project data and configurations
- Perfect "end of day shutdown" command

#### Stopping Specific Projects
```bash
# Stop just one project (leaves services and other projects running)
podium down <project_name>
```
- Stops only the specified project container
- Leaves shared services running for other projects
- Preserves project data and configurations

#### Checking Project Status
```bash
# Check all projects
podium status

# Check specific project
podium status <project_name>
```
- Displays project status and health
- Shows access URLs (local and LAN)
- Provides troubleshooting suggestions if issues detected

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

### Core Development Commands
```bash
# Composer (runs inside container with correct PHP environment)
podium composer install
podium composer require laravel/sanctum
podium composer update

# Laravel Artisan (runs inside container)
podium art migrate
podium art make:controller UserController
podium art tinker
podium art queue:work

# WordPress CLI (runs inside container)  
podium wp plugin list
podium wp user create john john@example.com --role=administrator
podium wp db export backup.sql

# PHP (runs inside container)
podium php -v
podium php script.php
```

### Enhanced Laravel Workflows
```bash
# Database refresh with seeding
podium db-refresh

# Clear all Laravel caches
podium cache-refresh
```

### Service Management
```bash
# Redis CLI access
podium redis KEYS "*"
podium redis-flush

# Direct container access
podium exec bash
podium exec-root bash
```

### System Management
```bash
# Manage shared services
podium start-services
podium stop-services

# Configure Podium environment
podium configure
```

### Get Help Anytime
```bash
# See all available commands
podium help
```

## 🖥️ GUI Management Interface

### Features
- **Visual Project Dashboard** - See all projects at a glance
- **Real-time Status Updates** - Live monitoring of project health
- **One-click Operations** - Start, stop, remove projects with buttons
- **Service Health Monitoring** - Track MySQL, Redis, phpMyAdmin status
- **Cross-platform Desktop App** - Native experience on all platforms

### Installation
```bash
# Download AppImage (Linux)
wget https://github.com/CaneBayComputers/podium-gui/releases/latest/download/Podium.AppImage
chmod +x Podium.AppImage
./Podium.AppImage

# Or download from releases page for Windows/macOS
# https://github.com/CaneBayComputers/podium-gui/releases
```

### GUI Features
- **Project Creation Wizard** - Visual project setup
- **Status Dashboard** - Real-time system monitoring
- **Service Controls** - Start/stop services with buttons
- **Project Management** - Visual project operations
- **System Health** - Monitor Docker and services

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

## 🚀 Advanced Features

### Automatic Project Setup
- **Smart PHP version detection** from composer.json
- **Database creation** and configuration
- **Environment file generation** (.env for Laravel, wp-config.php for WordPress)
- **Hosts file management** for local domains
- **Port assignment** and networking

### Development Optimization
- **Redis caching** configured automatically
- **File permissions** handled correctly
- **Cross-platform compatibility** built-in

### Safety Features
- **Trash integration** (projects moved to trash, not deleted)
- **Confirmation prompts** for destructive operations
- **Non-invasive installation** (minimal system changes)
- **Isolated environments** (no conflicts between projects)

### GUI Enhancements
- **Real-time monitoring** of all services and projects
- **Visual project management** with intuitive interface
- **System health dashboard** showing resource usage
- **Automated installation** through GUI installer

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