#!/bin/bash

# Podium CLI Installer Script
# Installs Podium CLI to /usr/local/share/podium-cli and creates symlink in /usr/local/bin

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/usr/local/share/podium-cli"
BIN_DIR="/usr/local/bin"
REPO_URL="https://github.com/CaneBayComputers/podium-cli.git"

echo -e "${BLUE}Podium CLI Installer${NC}"
echo "====================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}Error: This script should not be run as root${NC}"
   echo "Please run as a regular user. The script will ask for sudo when needed."
   exit 1
fi

# Check for required commands
for cmd in git docker; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: $cmd is not installed${NC}"
        echo "Please install $cmd and try again."
        exit 1
    fi
done

# Check if already installed
if [[ -d "$INSTALL_DIR" ]]; then
    echo -e "${YELLOW}Podium CLI is already installed.${NC}"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    echo -e "${YELLOW}Updating existing installation...${NC}"
    sudo rm -rf "$INSTALL_DIR"
fi

# Create installation directory
echo -e "${BLUE}Creating installation directory...${NC}"
sudo mkdir -p "$INSTALL_DIR"

# Clone repository
echo -e "${BLUE}Downloading Podium CLI...${NC}"
sudo git clone "$REPO_URL" "$INSTALL_DIR"

# Set proper permissions
echo -e "${BLUE}Setting permissions...${NC}"
sudo chown -R root:root "$INSTALL_DIR"
sudo chmod +x "$INSTALL_DIR/src/podium"

# Create symlink
echo -e "${BLUE}Creating command symlink...${NC}"
sudo ln -sf "$INSTALL_DIR/src/podium" "$BIN_DIR/podium"

# Verify installation
if command -v podium &> /dev/null; then
    echo -e "${GREEN}✓ Podium CLI installed successfully!${NC}"
    echo
    echo "Get started with:"
    echo -e "  ${BLUE}podium config${NC}     - Configure your development environment"
    echo -e "  ${BLUE}podium new${NC}        - Create a new project"  
    echo -e "  ${BLUE}podium help${NC}       - Show all available commands"
    echo
    echo "For the GUI interface, visit: https://podium.dev"
else
    echo -e "${RED}✗ Installation failed${NC}"
    echo "The podium command is not available in PATH."
    exit 1
fi
