#!/bin/bash

# Podium CLI Arch Linux Installer Script
# Complete installation of Podium CLI with all dependencies for Arch-based systems

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

echo -e "${BLUE}Podium CLI Arch Installer${NC}"
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
            echo "Podium CLI Arch Linux Installer"
            echo
            echo "Usage: $0 [options]"
            echo
            echo "Options:"
            echo "  --help, -h   Show this help message"
            echo
            echo "This installer targets Arch Linux and Arch-based distributions."
            exit 0
            ;;
    esac
done

# Check for Arch (or at least pacman)
if ! command -v pacman >/dev/null 2>&1; then
    echo -e "${RED}Error: This installer requires Arch Linux (pacman).${NC}"
    echo "For Ubuntu/Debian use install-ubuntu.sh, or install dependencies manually."
    exit 1
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}Error: This script should not be run as root.${NC}"
   echo "Please run as a regular user. The script will ask for sudo when needed."
   exit 1
fi

# Request sudo access upfront
echo -e "${YELLOW}This installer will install system packages and requires sudo access.${NC}"
if ! sudo -v; then
    echo -e "${RED}Error: Sudo access required.${NC}"
    exit 1
fi

echo -e "${CYAN}Installing system dependencies...${NC}"

###############################
# Update package databases
###############################
echo -e "${BLUE}Updating package databases...${NC}"
sudo pacman -Syu --noconfirm

###############################
# Install core tools
###############################
echo -e "${BLUE}Installing base packages...${NC}"
sudo pacman -S --noconfirm --needed \
    git curl jq unzip \
    docker \
    trash-cli

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
# Install GitHub CLI (optional but recommended)
###############################
if ! command -v gh >/dev/null 2>&1; then
    echo -e "${BLUE}Installing GitHub CLI...${NC}"
    if sudo pacman -S --noconfirm --needed github-cli; then
        echo -e "${GREEN}✓ GitHub CLI installed${NC}"
    else
        echo -e "${YELLOW}⚠️ GitHub CLI package not found or failed to install. Skipping.${NC}"
    fi
else
    echo -e "${GREEN}✓ GitHub CLI already installed${NC}"
fi

###############################
# Configure Docker
###############################
echo -e "${BLUE}Configuring Docker...${NC}"

# Enable and start Docker service
if ! systemctl is-enabled docker.service >/dev/null 2>&1; then
    sudo systemctl enable docker.service
fi

if ! systemctl is-active docker.service >/dev/null 2>&1; then
    sudo systemctl start docker.service
fi

# Add user to docker group
if ! id -nG "$USER" | grep -q "\bdocker\b"; then
    sudo usermod -aG docker "$USER"
    echo -e "${YELLOW}You were added to the 'docker' group. You may need to log out and back in for this to take effect.${NC}"
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
                echo -e "${CYAN}Non-interactive run - automatically repointing to local checkout...${NC}"
                sleep 1
            fi
        fi
    fi

    if [[ "$desired_target" == "$INSTALL_DIR" ]]; then
        echo -e "${BLUE}Using existing directory at installation path...${NC}"
    else
        echo -e "${BLUE}Linking installation directory to local checkout...${NC}"
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
    fi

    echo -e "${BLUE}Creating command symlink...${NC}"
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
            echo -e "${CYAN}Running in non-interactive mode - updating existing installation...${NC}"
        fi
        echo -e "${YELLOW}Updating existing installation...${NC}"
        sudo rm -rf "$INSTALL_DIR"
    fi

    sudo mkdir -p "$INSTALL_DIR"
    echo -e "${BLUE}Cloning repository...${NC}"
    sudo git clone "$REPO_URL" "$INSTALL_DIR"

    echo -e "${BLUE}Setting permissions...${NC}"
    sudo chmod +x "$INSTALL_DIR/src/podium"
    sudo chmod +x "$INSTALL_DIR/src/scripts"/*.sh
    sudo chown -R "$(whoami):$(id -gn)" "$INSTALL_DIR"
    sudo chown root:root "$INSTALL_DIR/src/podium"

    echo -e "${BLUE}Creating command symlink...${NC}"
    sudo ln -sf "$INSTALL_DIR/src/podium" "$BIN_DIR/podium"
fi

###############################
# Final verification and instructions
###############################
echo
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo "=========================="

if command -v podium >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Podium CLI installed successfully${NC}"
    echo
    echo -e "${CYAN}🚀 Next Steps:${NC}"
    echo -e "  1. Ensure Docker is running: ${BLUE}systemctl status docker${NC}"
    echo -e "  2. ${BLUE}podium configure${NC} - Configure your development environment"
    echo -e "  3. ${BLUE}podium new my-project${NC} - Create your first project"
    echo -e "  4. ${BLUE}podium status${NC}     - Check system status"
    echo -e "  5. ${BLUE}podium help${NC}       - Show all available commands"
    echo
    echo -e "${CYAN}🗑️  To Uninstall Later:${NC}"
    echo -e "  ${BLUE}podium uninstall${NC}     - Remove all Docker resources"
    echo -e "  ${BLUE}sudo rm -f /usr/local/bin/podium${NC}"
    echo -e "  ${BLUE}sudo rm -rf /usr/local/share/podium-cli${NC}"
    echo -e "  ${BLUE}sudo rm -rf /etc/podium-cli${NC}"
    echo
    echo -e "${YELLOW}IMPORTANT:${NC} For Docker permissions to work correctly, please ${YELLOW}log out and back in or reboot your system${NC} before using Podium (including running ${BLUE}podium configure${NC} or ${BLUE}podium up${NC})."
else
    echo -e "${RED}✗ Installation failed.${NC}"
    echo "The podium command is not available in PATH."
    exit 1
fi
