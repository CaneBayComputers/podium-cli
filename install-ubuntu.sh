#!/bin/bash

# Podium CLI Installer Script
# Complete installation of Podium CLI with all dependencies

set -e

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --help)
            echo "Podium CLI Ubuntu Installer"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --help           Show this help message"
            echo ""
            echo "This installer automatically detects if Docker is already available"
            echo "(e.g., from Docker Desktop) and skips Docker installation if found."
            exit 0
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/usr/local/share/podium-cli"
CONFIG_DIR="/etc/podium-cli"
BIN_DIR="/usr/local/bin"
REPO_URL="https://github.com/CaneBayComputers/podium-cli.git"

echo -e "${BLUE}Podium CLI Complete Installer${NC}"
echo "=============================="

# Ensure we're in a valid directory (fix for "Unable to read current working directory" error)
if ! pwd &>/dev/null; then
    echo "⚠️  Current directory is invalid, changing to home directory..."
    cd "$HOME" || cd /tmp
fi

echo

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}Error: This script should not be run as root${NC}"
   echo "Please run as a regular user. The script will ask for sudo when needed."
   exit 1
fi

# Check for Ubuntu/Debian
if ! command -v apt-get &> /dev/null; then
    echo -e "${RED}Error: This installer requires Ubuntu/Debian (apt-get)${NC}"
    echo "For other distributions, please install dependencies manually:"
    echo "- Docker"
    echo "- Node.js 16+"
    echo "- Git"
    exit 1
fi

# Request sudo access upfront
echo -e "${YELLOW}This installer will install system packages and requires sudo access.${NC}"
if ! sudo -v; then
    echo -e "${RED}Error: Sudo access required${NC}"
    exit 1
fi

echo -e "${CYAN}Installing system dependencies...${NC}"

###############################
# Update package lists
###############################
echo -e "${BLUE}Updating package lists...${NC}"
sudo apt-get update -y -q

###############################
# Add Ubuntu repos
###############################
sudo add-apt-repository -y universe
sudo add-apt-repository -y multiverse   # harmless if already enabled
sudo apt-get update -y -q

###############################
# Install basic packages
###############################
echo -e "${BLUE}Installing basic packages...${NC}"
sudo apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https \
    git jq software-properties-common trash-cli pipx unzip

###############################
# Install Docker
###############################
# Check if Docker is already available (e.g., from Docker Desktop)
if command -v docker &> /dev/null && docker --version &> /dev/null; then
    DOCKER_VERSION=$(docker --version 2>/dev/null | head -n1)
    echo -e "${GREEN}✓ Docker already available: $DOCKER_VERSION${NC}"
    
    # Check if it's Docker Desktop (common on Windows/Mac)
    if docker context ls 2>/dev/null | grep -q "desktop-linux\|default.*docker-desktop"; then
        echo -e "${CYAN}  Detected Docker Desktop integration${NC}"
    fi
elif ! command -v docker &> /dev/null; then
    echo -e "${BLUE}Installing Docker...${NC}"
    
    # Remove any old Docker packages
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        sudo apt-get remove -y $pkg 2>/dev/null || true
    done
    
    # Add Docker's official GPG key and repository
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt-get update -y -q
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${RED}Error: Docker command version check failed${NC}"
    exit 1
fi

# Add user to docker group even if docker is already installed
sudo usermod -aG docker "$USER"
echo -e "${YELLOW}Note: You may need to log out and back in (or start a new shell with 'newgrp docker') for Docker group changes to take effect.${NC}"

###############################
# Install Node.js and NPM via NVM
###############################
if ! command -v node &> /dev/null || [[ $(node -v | cut -d'v' -f2 | cut -d'.' -f1) -lt 16 ]]; then
    echo -e "${BLUE}Installing Node.js (via NVM)...${NC}"

    # Install NVM if not present
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
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
if ! command -v gh &> /dev/null; then
    echo -e "${BLUE}Installing GitHub CLI...${NC}"
    
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    
    sudo apt-get update -y -q
    sudo apt-get install -y gh
    
    echo -e "${GREEN}✓ GitHub CLI installed${NC}"
else
    echo -e "${GREEN}✓ GitHub CLI already installed${NC}"
fi

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
# Clean up
###############################
sudo apt-get autoremove -y -q

# Check if already installed
if [[ -d "$INSTALL_DIR" ]]; then
    echo -e "${YELLOW}Podium CLI is already installed.${NC}"
    
    # Check if we're running in a pipe (curl | bash) or interactive terminal
    if [ -t 0 ]; then
        # Interactive terminal - ask user
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
    else
        # Running via pipe (curl | bash) - auto-update
        echo -e "${CYAN}Running via curl | bash - automatically updating...${NC}"
        sleep 2
    fi
    
    echo -e "${YELLOW}Updating existing installation...${NC}"
    
    # Configuration is now stored in /etc/podium-cli/ and will persist across reinstalls
    
    sudo rm -rf "$INSTALL_DIR"
fi

###############################
# Install Podium CLI
###############################
echo -e "${CYAN}Installing Podium CLI...${NC}"

# Create installation directory
echo -e "${BLUE}Creating installation directory...${NC}"
sudo mkdir -p "$INSTALL_DIR"

# Clone repository
echo -e "${BLUE}Downloading Podium CLI...${NC}"
sudo git clone "$REPO_URL" "$INSTALL_DIR"

# Set proper permissions
echo -e "${BLUE}Setting permissions...${NC}"
# Keep most files accessible to users, only set execute permissions for scripts
sudo chmod +x "$INSTALL_DIR/src/podium"
sudo chmod +x "$INSTALL_DIR/src/scripts"/*.sh
# Make sure current user can read/write config files
sudo chown -R "$(whoami):$(id -gn)" "$INSTALL_DIR"
# Only the main binary needs special permissions
sudo chown root:root "$INSTALL_DIR/src/podium"

# Create symlink
echo -e "${BLUE}Creating command symlink...${NC}"
sudo ln -sf "$INSTALL_DIR/src/podium" "$BIN_DIR/podium"

###############################
# Configure Docker service
###############################
echo -e "${BLUE}Configuring Docker service...${NC}"

# Enable and start Docker service
if ! systemctl is-enabled docker.service >/dev/null 2>&1; then
    sudo systemctl enable docker.service
fi

if ! systemctl is-active docker.service >/dev/null 2>&1; then
    sudo systemctl start docker.service
fi

###############################
# Final verification and instructions
###############################
echo
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo "=========================="

# Verify installation
if command -v podium &> /dev/null; then
    echo -e "${GREEN}✓ Podium CLI installed successfully${NC}"
    
    # Configuration is now permanently stored in /etc/podium-cli/ - no restoration needed
    
    echo
    echo -e "${CYAN}🚀 Next Steps:${NC}"
    echo -e "  1. ${BLUE}podium configure${NC} - Configure your development environment"
    echo -e "  2. ${BLUE}podium new my-project${NC} - Create your first project"
    echo -e "  3. ${BLUE}podium status${NC}     - Check system status"
    echo -e "  4. ${BLUE}podium help${NC}       - Show all available commands"
    echo
    echo -e "${CYAN}🗑️  To Uninstall Later:${NC}"
    echo -e "  ${BLUE}podium uninstall${NC}     - Remove all Docker resources"
    echo -e "  ${BLUE}sudo rm -f /usr/local/bin/podium${NC} - Remove CLI binary"
    echo -e "  ${BLUE}sudo rm -rf /usr/local/share/podium-cli${NC} - Remove CLI files"
    echo -e "  ${BLUE}sudo rm -rf /etc/podium-cli${NC} - Remove config directory"
    echo
    echo -e "${CYAN}📱 Want a GUI?${NC}"
    echo "   Contact: Cane Bay Computers for the premium desktop interface"
    echo
    echo -e "${CYAN}📖 Documentation:${NC}"
    echo "   https://github.com/CaneBayComputers/podium-cli"
    echo
else
    echo -e "${RED}✗ Installation failed${NC}"
    echo "The podium command is not available in PATH."
    exit 1
fi

echo
echo -e "${YELLOW}IMPORTANT:${NC} For Docker permissions to work correctly, please ${YELLOW}log out and back in or reboot your system${NC} before using Podium (including running ${BLUE}podium configure${NC} or ${BLUE}podium up${NC})."
