#!/bin/bash

# Podium CLI Mac Installer Script
# Complete installation of Podium CLI with all dependencies for macOS

set -e

# Clear screen and suppress script echoing
clear 2>/dev/null || true

# Immediate feedback to user (prevents showing script content)
echo "🚀 Starting Podium CLI installation..."

# Ensure we're in a valid directory (fix for "Unable to read current working directory" error)
if ! pwd &>/dev/null; then
    echo "⚠️  Current directory is invalid, changing to home directory..."
    cd "$HOME" || cd /tmp
fi

sleep 1

# Check for dry-run mode
DRY_RUN=0
if [[ "$1" == "--dry-run" || "$1" == "--test" ]]; then
    DRY_RUN=1
    echo "🧪 DRY RUN MODE - No actual installations will be performed"
    echo
fi

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

echo -e "${BLUE}Podium CLI Mac Installer${NC}"
echo "========================"
echo

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This installer is for macOS only${NC}"
    echo "For Linux, use: curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install.sh | bash"
    exit 1
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}Error: This script should not be run as root${NC}"
   echo "Please run as a regular user. The script will ask for sudo when needed."
   exit 1
fi

# Request sudo access upfront
echo -e "${YELLOW}This installer will install system packages and may require sudo access.${NC}"
echo

echo -e "${CYAN}Installing system dependencies...${NC}"

###############################
# Install Homebrew if not present
###############################
if ! command -v brew &> /dev/null; then
    echo -e "${BLUE}Installing Homebrew...${NC}"
    if [ "$DRY_RUN" = "1" ]; then
        echo "  [DRY RUN] Would install Homebrew"
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Add Homebrew to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon Mac
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        # Intel Mac
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    echo -e "${GREEN}✓ Homebrew installed${NC}"
else
    echo -e "${GREEN}✓ Homebrew already installed${NC}"
fi

###############################
# Update Homebrew
###############################
echo -e "${BLUE}Updating Homebrew...${NC}"
if [ "$DRY_RUN" = "1" ]; then
    echo "  [DRY RUN] Would update Homebrew"
else
    brew update
fi

###############################
# Install Docker Desktop
###############################
if ! command -v docker &> /dev/null; then
    echo -e "${BLUE}Installing Docker Desktop...${NC}"
    if [ "$DRY_RUN" = "1" ]; then
        echo "  [DRY RUN] Would install Docker Desktop via: brew install --cask docker"
    else
        brew install --cask docker
        
        echo -e "${GREEN}✓ Docker Desktop installed${NC}"
        echo -e "${YELLOW}⚠️  Please start Docker Desktop from Applications before continuing${NC}"
        echo "Press any key once Docker Desktop is running..."
        read -n 1 -s
    fi
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi

###############################
# Install Node.js and NPM via NVM
###############################
if ! command -v node &> /dev/null || [[ $(node -v | cut -d'v' -f2 | cut -d'.' -f1) -lt 16 ]]; then
    echo -e "${BLUE}Installing Node.js (via NVM)...${NC}"
    if [ "$DRY_RUN" = "1" ]; then
        echo "  [DRY RUN] Would install NVM and latest LTS Node.js"
    else
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
    fi
else
    echo -e "${GREEN}✓ Node.js already installed${NC}"
fi

###############################
# Install additional tools
###############################
echo -e "${BLUE}Installing additional tools...${NC}"

# Install git if not present (usually pre-installed)
if ! command -v git &> /dev/null; then
    brew install git
fi

# Install other useful tools
echo -e "Installing: jq, trash ..."
brew install jq trash >/dev/null 2>&1 && echo -e "${GREEN}✓ Additional tools installed${NC}" || echo -e "${YELLOW}⚠️ Some tools may have failed to install${NC}"

###############################
# Ensure local bin directory and PATH
###############################
mkdir -p "$HOME/.local/bin"
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

# Install GitHub CLI (optional but recommended)
if ! command -v gh &> /dev/null; then
    echo -e "Installing GitHub CLI..."
    brew install gh >/dev/null 2>&1 && echo -e "${GREEN}✓ GitHub CLI installed${NC}" || echo -e "${YELLOW}⚠️ GitHub CLI installation failed${NC}"
else
    echo -e "${GREEN}✓ GitHub CLI already installed${NC}"
fi

# Install pipx
echo -e "${BLUE}Installing pipx...${NC}"
brew install pipx >/dev/null 2>&1 || echo -e "${YELLOW}⚠️ pipx installation may have failed${NC}"

# Install AWS CLI (if not present)
if ! command -v aws &> /dev/null; then
    echo -e "${BLUE}Installing AWS CLI...${NC}"
    if [ "$DRY_RUN" = "1" ]; then
        echo "  [DRY RUN] Would download and install AWS CLI from AWSCLIV2.pkg"
    else
        curl -fsSL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
        sudo installer -pkg "AWSCLIV2.pkg" -target /
        rm -f "AWSCLIV2.pkg"
    fi
    echo -e "${GREEN}✓ AWS CLI installed (or installation attempted)${NC}"
else
    echo -e "${GREEN}✓ AWS CLI already installed${NC}"
fi


###############################
# Check if already installed
###############################
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
sudo chown root:wheel "$INSTALL_DIR/src/podium"

# Create symlink
echo -e "${BLUE}Creating command symlink...${NC}"
sudo ln -sf "$INSTALL_DIR/src/podium" "$BIN_DIR/podium"

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
    
    # Check Docker status
    if ! docker info &>/dev/null; then
        echo -e "${YELLOW}⚠️  Docker Desktop needs to be running${NC}"
        echo -e "   Please start Docker Desktop from Applications"
    fi
    
    echo
    echo -e "${CYAN}ℹ️  Note: Any 'Outdated Formulae' warnings above are normal${NC}"
    echo -e "   Your installation is complete and working. You can upgrade later with 'brew upgrade'"
    echo
    echo -e "${CYAN}🚀 Next Steps:${NC}"
    echo -e "  1. Make sure Docker Desktop is running"
    echo -e "  2. ${BLUE}podium configure${NC} - Configure your development environment"
    echo -e "  3. ${BLUE}podium new my-project${NC} - Create your first project"
    echo -e "  4. ${BLUE}podium status${NC}     - Check system status"
    echo -e "  5. ${BLUE}podium help${NC}       - Show all available commands"
    echo
    echo -e "${CYAN}🗑️  To Uninstall Later:${NC}"
    echo -e "  ${BLUE}brew uninstall podium-cli${NC} - Complete removal (includes Docker cleanup)"
    echo -e "  ${BLUE}podium uninstall${NC}     - Manual Docker cleanup only"
    echo -e "  ${BLUE}sudo rm -rf /etc/podium-cli${NC} - Remove config directory"
    echo
    echo -e "${CYAN}📱 Want a GUI?${NC}"
    echo "   Contact: canebaycomputers@gmail.com for the premium desktop interface"
    echo
    echo -e "${CYAN}📖 Documentation:${NC}"
    echo "   https://podiumdev.io"
    echo
    echo -e "${YELLOW}IMPORTANT:${NC} If you just installed Docker Desktop or Homebrew, you may need to ${YELLOW}restart Docker Desktop and open a new terminal or reboot${NC} before using Podium (for example: ${BLUE}podium configure${NC} or ${BLUE}podium up${NC})."
else
    echo -e "${RED}✗ Installation failed${NC}"
    echo "The podium command is not available in PATH."
    exit 1
fi
