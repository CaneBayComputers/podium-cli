#!/bin/bash

# Podium CLI Installer Script
# Complete installation of Podium CLI with all dependencies

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
CONFIG_DIR="/etc/podium-cli"
BIN_DIR="/usr/local/bin"
REPO_URL="https://github.com/CaneBayComputers/podium-cli.git"

echo -e "${BLUE}Podium CLI Complete Installer${NC}"
echo "=============================="
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
# Install basic packages
###############################
echo -e "${BLUE}Installing basic packages...${NC}"
sudo apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https \
    git unzip jq software-properties-common build-essential mariadb-client \
    p7zip-full trash-cli net-tools

###############################
# Install Docker
###############################
if ! command -v docker &> /dev/null; then
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
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi

###############################
# Install Node.js and NPM
###############################
if ! command -v node &> /dev/null || [[ $(node -v | cut -d'v' -f2 | cut -d'.' -f1) -lt 16 ]]; then
    echo -e "${BLUE}Installing Node.js...${NC}"
    
    # Install NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    echo -e "${GREEN}✓ Node.js $(node -v) and NPM $(npm -v) installed${NC}"
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
    
    # Backup existing configuration before removing installation
    if [[ -d "$INSTALL_DIR/src/docker-stack" ]]; then
        echo -e "${CYAN}Backing up existing configuration...${NC}"
        sudo mkdir -p "$CONFIG_DIR"
        
        # Backup .env and docker-compose.yaml if they exist
        if [[ -f "$INSTALL_DIR/src/docker-stack/.env" ]]; then
            sudo cp "$INSTALL_DIR/src/docker-stack/.env" "$CONFIG_DIR/.env.backup"
        fi
        if [[ -f "$INSTALL_DIR/src/docker-stack/docker-compose.yaml" ]]; then
            sudo cp "$INSTALL_DIR/src/docker-stack/docker-compose.yaml" "$CONFIG_DIR/docker-compose.yaml.backup"
        fi
        
        echo -e "${GREEN}✓ Configuration backed up to $CONFIG_DIR${NC}"
    fi
    
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
    
    # Restore backed up configuration if it exists
    if [[ -f "$CONFIG_DIR/.env.backup" ]]; then
        echo -e "${CYAN}Restoring previous configuration...${NC}"
        sudo cp "$CONFIG_DIR/.env.backup" "$INSTALL_DIR/src/docker-stack/.env"
        sudo cp "$CONFIG_DIR/docker-compose.yaml.backup" "$INSTALL_DIR/src/docker-stack/docker-compose.yaml" 2>/dev/null || true
        echo -e "${GREEN}✓ Previous configuration restored${NC}"
    fi
    
    # Check if user needs to log out for docker group
    if ! groups | grep -q docker; then
        echo -e "${YELLOW}⚠️  You need to log out and back in for Docker access${NC}"
        echo -e "   Or run: ${BLUE}newgrp docker${NC}"
    fi
    
    echo
    echo -e "${CYAN}🚀 Next Steps:${NC}"
    echo -e "  1. ${BLUE}podium config${NC}     - Configure your development environment"
    echo -e "  2. ${BLUE}podium new my-project${NC} - Create your first project"  
    echo -e "  3. ${BLUE}podium status${NC}     - Check system status"
    echo -e "  4. ${BLUE}podium help${NC}       - Show all available commands"
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
