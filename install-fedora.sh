#!/bin/bash

# Podium CLI Fedora Installer Script
# Complete installation of Podium CLI with all dependencies for Fedora

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/usr/local/share/podium-cli"
BIN_DIR="/usr/local/bin"
REPO_URL="https://github.com/CaneBayComputers/podium-cli.git"
NVM_FALLBACK_VERSION="v0.40.1"

get_latest_nvm_version() {
    local tag
    tag="$(
        curl -fsSL "https://api.github.com/repos/nvm-sh/nvm/releases/latest" 2>/dev/null | \
            sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | \
            head -n 1
    )"
    if [[ -n "$tag" ]]; then
        echo "$tag"
        return 0
    fi
    return 1
}

echo -e "${BLUE}Podium CLI Fedora Installer${NC}"
echo "========================="
echo

# Ensure we're in a valid directory
if ! pwd &>/dev/null; then
    echo "⚠️  Current directory is invalid, changing to home directory..."
    cd "$HOME" || cd /tmp
fi

# Detect a local Podium CLI checkout (for development installs)
CURRENT_DIR="$(pwd -P)"
LOCAL_REPO_DIR=""
if [[ -f "$CURRENT_DIR/README.md" && -f "$CURRENT_DIR/src/podium" && -f "$CURRENT_DIR/src/scripts/functions.sh" ]]; then
    LOCAL_REPO_DIR="$CURRENT_DIR"
fi

# Basic help
for arg in "$@"; do
    case "$arg" in
        --help|-h)
            echo "Podium CLI Fedora Installer"
            echo
            echo "Usage: $0 [options]"
            echo
            echo "Options:"
            echo "  --help, -h   Show this help message"
            echo
            echo "This installer targets Fedora and Fedora-based distributions."
            exit 0
            ;;
    esac
done

# Check for Fedora (or at least dnf)
if ! command -v dnf >/dev/null 2>&1; then
    echo -e "${RED}Error: This installer requires Fedora/RHEL (dnf).${NC}"
    echo "For Ubuntu/Debian use install-ubuntu.sh; for Arch use install-arch.sh."
    exit 1
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}Error: This script should not be run as root.${NC}"
   echo "Please run as a regular user. The script will ask for sudo when needed."
   exit 1
fi

# Request sudo upfront with a clear explanation, then keep credentials alive.
# Probe with `sudo -n` first: systems that grant passwordless sudo (cloud
# images, CI runners) usually ALSO carry a password-requiring rule, and plain
# `sudo -v` authenticates against every matching rule — so it prompts even
# though each individual command would run fine without a password.
if sudo -n true 2>/dev/null; then
    echo -e "${GREEN}✓ Passwordless sudo available${NC}"
else
    echo
    echo -e "${YELLOW}Podium needs sudo to install system packages and configure Docker.${NC}"
    echo -e "${YELLOW}You'll be asked for your password once — it won't be asked again during the install.${NC}"
    echo
    if ! sudo -v; then
        echo -e "${RED}Error: sudo access is required. Please run as a user with sudo privileges.${NC}"
        exit 1
    fi
fi
# `|| true` matters: set -e is inherited by this subshell, and `sudo -n -v`
# fails wherever a password-requiring sudoers rule coexists with NOPASSWD.
# Without it the keepalive dies instantly and the EXIT trap below kills a
# dead PID.
( while true; do sudo -n -v 2>/dev/null || true; sleep 50; done ) &
SUDO_KEEPALIVE_PID=$!
# Preserve the real exit status — a bare `exit` here would return the status
# of `kill`, reporting failure after a fully successful install.
trap 'rc=$?; kill $SUDO_KEEPALIVE_PID 2>/dev/null || true; exit $rc' INT TERM EXIT

echo -e "${CYAN}Installing system dependencies...${NC}"

###############################
# Update package databases
###############################
echo -e "${BLUE}Updating package databases...${NC}"
sudo dnf update -y

###############################
# Install core tools
###############################
echo -e "${BLUE}Installing base packages...${NC}"
sudo dnf install -y \
    git curl jq unzip \
    dnf-plugins-core \
    trash-cli \
    ImageMagick librsvg2-tools \
    policycoreutils-python-utils

# Docker (using official Docker CE repo - most reliable)
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${BLUE}Setting up Docker repository...${NC}"
    sudo dnf remove -y docker docker-client docker-client-latest docker-common \
                       docker-latest docker-latest-logrotate docker-logrotate \
                       docker-selinux docker-engine-selinux docker-engine 2>/dev/null || true

    sudo dnf install -y dnf-plugins-core

    # dnf5 (Fedora 41+) dropped `config-manager --add-repo` in favour of the
    # `addrepo` subcommand. Try the new syntax first, fall back to dnf4's.
    DOCKER_REPO_URL="https://download.docker.com/linux/fedora/docker-ce.repo"
    if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
        if ! sudo dnf config-manager addrepo --from-repofile="$DOCKER_REPO_URL" 2>/dev/null; then
            sudo dnf config-manager --add-repo "$DOCKER_REPO_URL"
        fi
    fi

    echo -e "${BLUE}Installing Docker...${NC}"
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

###############################
# Ensure local bin directory and PATH
###############################
mkdir -p "$HOME/.local/bin"
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

###############################
# Install Node.js and NPM via NVM
###############################
if ! command -v node &> /dev/null || [[ $(node -v | cut -d'v' -f2 | cut -d'.' -f1) -lt 16 ]]; then
    echo -e "${BLUE}Installing Node.js (via NVM)...${NC}"

    if [ ! -d "$HOME/.nvm" ]; then
        NVM_VERSION="$(get_latest_nvm_version || echo "$NVM_FALLBACK_VERSION")"
        curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    fi

    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1090
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if command -v nvm >/dev/null 2>&1; then
        nvm install --lts
        nvm alias default 'lts/*'
        echo -e "${GREEN}✓ Node.js $(node -v) and NPM $(npm -v) installed via NVM${NC}"
    else
        echo -e "${YELLOW}⚠️ NVM did not initialize correctly; please install Node.js manually.${NC}"
    fi
else
    echo -e "${GREEN}✓ Node.js already installed${NC}"
fi

###############################
# Install GitHub CLI
###############################
if ! command -v gh >/dev/null 2>&1; then
    echo -e "${BLUE}Installing GitHub CLI...${NC}"
    if sudo dnf install -y gh; then
        echo -e "${GREEN}✓ GitHub CLI installed${NC}"
    else
        echo -e "${YELLOW}⚠️ GitHub CLI install failed. You can install it later with: sudo dnf install gh${NC}"
    fi
else
    echo -e "${GREEN}✓ GitHub CLI already installed${NC}"
fi

###############################
# Configure Docker
###############################
echo -e "${BLUE}Configuring Docker...${NC}"

# Enable and start Docker service
sudo systemctl enable --now docker.service 2>/dev/null || true

# Add user to docker group
if ! id -nG "$USER" | grep -q "\bdocker\b"; then
    sudo usermod -aG docker "$USER"
    echo -e "${YELLOW}You were added to the 'docker' group. Log out and back in (or reboot) for this to take effect.${NC}"
fi

###############################
# SELinux
###############################
# Fedora/RHEL ship SELinux enforcing. Podium bind-mounts each project directory
# into its container, which SELinux denies unless the directory carries the
# container_file_t label. The projects directory doesn't exist yet at install
# time — 'podium configure' creates it and applies the label there.
if command -v getenforce >/dev/null 2>&1 && [[ "$(getenforce 2>/dev/null)" == "Enforcing" ]]; then
    echo -e "${BLUE}SELinux is enforcing.${NC}"
    echo -e "${CYAN}  'podium configure' will label your projects directory so containers can access it.${NC}"
fi

###############################
# Install / Update Podium CLI
###############################
echo -e "${CYAN}Installing Podium CLI...${NC}"

if [[ -n "$LOCAL_REPO_DIR" ]]; then
    echo -e "${GREEN}✓ Detected existing Podium CLI checkout${NC}"
    echo -e "${CYAN}Using local directory:${NC} $LOCAL_REPO_DIR"

    desired_target="$(readlink -f "$LOCAL_REPO_DIR")"
    current_target="$(readlink -f "$INSTALL_DIR" 2>/dev/null || true)"

    if [[ -e "$INSTALL_DIR" || -L "$INSTALL_DIR" ]]; then
        if [[ -n "$current_target" && "$current_target" != "$desired_target" ]]; then
            echo -e "${YELLOW}Podium CLI is already installed at:${NC} $INSTALL_DIR -> $current_target"

            if [ -t 0 ]; then
                read -p "Do you want to repoint it to this local checkout? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo "Installation cancelled."
                    exit 0
                fi
            else
                echo -e "${CYAN}Non-interactive run - automatically repointing...${NC}"
            fi
        fi
    fi

    sudo mkdir -p "$(dirname "$INSTALL_DIR")"
    if [[ -L "$INSTALL_DIR" ]]; then
        sudo ln -sfn "$desired_target" "$INSTALL_DIR"
    elif [[ -e "$INSTALL_DIR" ]]; then
        backup_dir="${INSTALL_DIR}.backup.$(date +%Y%m%d%H%M%S)"
        echo -e "${YELLOW}Backing up existing install to:${NC} $backup_dir"
        sudo mv "$INSTALL_DIR" "$backup_dir"
        sudo ln -s "$desired_target" "$INSTALL_DIR"
    else
        sudo ln -s "$desired_target" "$INSTALL_DIR"
    fi

    sudo chmod +x "$INSTALL_DIR/src/podium" 2>/dev/null || true
    sudo ln -sf "$INSTALL_DIR/src/podium" "$BIN_DIR/podium"
else
    if [[ -d "$INSTALL_DIR" || -L "$INSTALL_DIR" ]]; then
        echo -e "${YELLOW}Podium CLI is already installed.${NC}"
        if [ -t 0 ]; then
            read -p "Do you want to update it? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Installation cancelled."
                exit 0
            fi
        else
            echo -e "${CYAN}Non-interactive mode - updating...${NC}"
        fi
        sudo rm -rf "$INSTALL_DIR"
    fi

    sudo mkdir -p "$INSTALL_DIR"
    echo -e "${BLUE}Cloning repository...${NC}"
    sudo git clone "$REPO_URL" "$INSTALL_DIR"

    echo -e "${BLUE}Setting permissions...${NC}"
    sudo chmod +x "$INSTALL_DIR/src/podium"
    sudo chmod +x "$INSTALL_DIR/src/scripts"/*.sh 2>/dev/null || true
    sudo chown -R "$(whoami):$(id -gn)" "$INSTALL_DIR"
    sudo chown root:root "$INSTALL_DIR/src/podium" 2>/dev/null || true

    echo -e "${BLUE}Creating command symlink...${NC}"
    sudo ln -sf "$INSTALL_DIR/src/podium" "$BIN_DIR/podium"
fi

###############################
# Final verification
###############################
echo
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo "=========================="

if command -v podium >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Podium CLI installed successfully${NC}"
    echo
    echo -e "${CYAN}🚀 Next Steps:${NC}"
    echo -e "  1. ${YELLOW}Log out and back in${NC} (or reboot) so Docker group works"
    echo -e "  2. Run ${BLUE}podium configure${NC}"
    echo -e "  3. Create your first project: ${BLUE}podium create \"A task tracker with user login\"${NC}"
    echo
    echo -e "${CYAN}📖 Docs:${NC} https://github.com/CaneBayComputers/podium-cli"
    echo
    echo -e "${CYAN}🗑️  Uninstall:${NC} podium uninstall"
else
    echo -e "${RED}✗ Installation failed.${NC}"
    exit 1
fi