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

echo -e "${BLUE}Podium CLI Arch Installer${NC}"
echo "========================="
echo

# Ensure we're in a valid directory
if ! pwd &>/dev/null; then
    echo "⚠️  Current directory is invalid, changing to home directory..."
    cd "$HOME" || cd /tmp
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
    docker nodejs npm \
    trash-cli pipx

###############################
# Install AWS CLI (if not present)
###############################
if ! command -v aws &> /dev/null; then
    echo -e "${BLUE}Installing AWS CLI...${NC}"
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
    echo -e "${GREEN}✓ AWS CLI installed${NC}"
else
    echo -e "${GREEN}✓ AWS CLI already installed${NC}"
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
if [[ -d "$INSTALL_DIR" ]]; then
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

echo -e "${CYAN}Installing Podium CLI...${NC}"

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
