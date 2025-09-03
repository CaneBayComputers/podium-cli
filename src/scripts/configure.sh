#!/bin/bash

set -e


ORIG_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"

cd ..

DEV_DIR=$(pwd)

source scripts/functions.sh

# Check for GUI mode flag and parse arguments
GUI_MODE=false
GIT_NAME=""
GIT_EMAIL=""
AWS_ACCESS_KEY=""
AWS_SECRET_KEY=""
AWS_REGION="us-east-1"
SKIP_AWS=false
PROJECTS_DIR=""
SKIP_PACKAGES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --gui-mode)
            GUI_MODE=true
            shift
            ;;
        --git-name)
            GIT_NAME="$2"
            shift 2
            ;;
        --git-email)
            GIT_EMAIL="$2"
            shift 2
            ;;
        --aws-access-key)
            AWS_ACCESS_KEY="$2"
            shift 2
            ;;
        --aws-secret-key)
            AWS_SECRET_KEY="$2"
            shift 2
            ;;
        --aws-region)
            AWS_REGION="$2"
            shift 2
            ;;
        --skip-aws)
            SKIP_AWS=true
            shift
            ;;
        --projects-dir)
            PROJECTS_DIR="$2"
            shift 2
            ;;
        --skip-packages)
            SKIP_PACKAGES=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="mac"
else
    PLATFORM="linux"
fi


# Generate stack id (cross-platform)
STACK_ID=$(openssl rand -hex 4 | cut -c1-8)


# Check for and set up environment variables
# Use /etc/podium-cli/ as primary config location
sudo mkdir -p /etc/podium-cli

if ! [ -f /etc/podium-cli/.env ]; then

	sudo cp docker-stack/env.example /etc/podium-cli/.env

	# Generate random numbers for B and C classes
	B_CLASS=$((RANDOM % 255 + 1))
	C_CLASS=$((RANDOM % 256))

	VPC_SUBNET="10.$B_CLASS.$C_CLASS"

	# Cross-platform sed with proper c\ command handling
	sudo-podium-sed-change "/^#VPC_SUBNET=/" "VPC_SUBNET=$VPC_SUBNET" /etc/podium-cli/.env
	sudo-podium-sed-change "/^#STACK_ID=/" "STACK_ID=$STACK_ID" /etc/podium-cli/.env

else

	source /etc/podium-cli/.env

fi


# Check for and set up docker compose yaml
if ! [ -f /etc/podium-cli/docker-compose.yaml ]; then

	sudo cp docker-stack/docker-compose.services.yaml /etc/podium-cli/docker-compose.yaml

	# Set projects directory if specified
	if [ -n "$PROJECTS_DIR" ]; then
		sudo-podium-sed-change "/^#PROJECTS_DIR=/" "PROJECTS_DIR=$PROJECTS_DIR" /etc/podium-cli/.env
	fi
	
	# Cross-platform sed for docker-compose.yaml
	sudo-podium-sed "s/STACK_ID/${STACK_ID}/g" /etc/podium-cli/docker-compose.yaml
	
	echo

fi


# Platform-specific permission checks (skip in GUI mode)
if [[ "$GUI_MODE" != "true" ]]; then
	if [[ "$PLATFORM" == "linux" ]]; then
		# Check and fix root perms (Linux only)
		if [[ "$(whoami)" == "root" ]]; then

			ORIG_USER=$SUDO_USER

				echo-return; echo-red "Do NOT run with sudo or as root!";

		echo-return; echo-white "Please run as regular user (you may be prompted for sudo password when needed)."; echo

		exit 1

		fi

		echo-return; echo-return

		echo-cyan 'IMPORTANT: This script must NOT be run with sudo!'

		echo-return; echo-white 'Running with sudo would configure Git and AWS for the root user instead of your user account.'

		echo-white 'The script will prompt for sudo password only when needed for system-level operations.'

		echo-return; echo-return

		if ! sudo -v; then

			echo-return; echo-red "No sudo privileges. Root access required!"; echo

			exit 1;

		fi
	elif [[ "$PLATFORM" == "mac" ]]; then
		# Mac users typically have sudo access, just verify
		echo-cyan "Verifying administrator privileges..."
		echo-white "You'll be prompted for your password to authorize system changes"
		echo
		if ! sudo -v; then
			echo-return; echo-red "Administrator privileges required for installation!"; echo
			exit 1;
		fi
		echo-green "✓ Administrator privileges confirmed"
		echo
	fi
else
	echo-cyan "Running in GUI mode - skipping permission checks"
	echo
fi

clear


# Platform-specific checks
if [[ "$PLATFORM" == "linux" ]]; then
	# Check for WSL2
	if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
		echo-cyan "Detected Windows WSL2 - Linux compatibility mode"
		echo-white "Note: Make sure Docker Desktop is running on Windows with WSL2 integration enabled"
		echo-white
	fi
	
	# Check for Ubuntu distribution
	if ! uname -a | grep Ubuntu > /dev/null; then
		if ! uname -a | grep pop-os > /dev/null; then
			echo-red "This script is for an Ubuntu based distribution!"
			exit 1
		fi
	fi
elif [[ "$PLATFORM" == "mac" ]]; then
	echo-cyan "Detected macOS - using Homebrew for package management"
	echo-white
fi


# Install Podium command globally
echo-return; echo-cyan "Installing Podium command globally..."
echo-white "This creates a 'podium' command accessible from anywhere on your system."
echo-white

if [[ "$GUI_MODE" == "true" ]]; then
	INSTALL_GLOBAL="y"
	echo-cyan "Auto-installing podium command in GUI mode..."
else
	read -p "Install podium command globally? (strongly recommended) (y/n): " INSTALL_GLOBAL
fi

if [[ "$INSTALL_GLOBAL" == "y" ]]; then
	echo
	echo-cyan "Installing podium command globally..."
	echo-white "You'll be prompted for your password to install to /usr/local/bin"
	echo
	
	# Remove existing symlink if it exists
	sudo rm -f /usr/local/bin/podium 2>/dev/null || true
	
	# Create symlink to podium script
	sudo ln -sf "$DEV_DIR/podium" /usr/local/bin/podium
	
	echo-green "Podium command installed globally!"
	echo-white "  • podium up myproject         (start project)"
	echo-white "  • podium new                  (create new project)"
	echo-white "  • podium help                 (see all commands)"
	echo-white
else
	echo-yellow "Global installation skipped - you'll need to use full paths:"
	echo-white "  $DEV_DIR/podium composer install"
	echo-white "  $DEV_DIR/podium art migrate"
fi

clear

echo-return; echo-return


# Welcome screen
echo "
          WELCOME TO PODIUM DEVELOPMENT ENVIRONMENT !

Setting up your $PLATFORM development environment for PHP projects...
Leave answers blank if you do not know the info. You can re-run the
installer to enter in new info when you have it."



###############################
# Platform-specific package installation
###############################

# Package installation is now handled by package managers (.deb dependencies or Homebrew)
echo-cyan "Package installation handled by package manager (.deb dependencies or Homebrew)"
echo-white



###############################
# Create ssh key
###############################
if ! [ -f ~/.ssh/id_rsa ]; then

  if ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa; then true; fi

fi



###############################
# Set up git committer info
###############################
echo-return; echo-cyan 'Setting up Git ...'; echo-white



# Configure Git (use GUI-provided values or prompt)
if [[ "$GUI_MODE" == "true" ]]; then
	if [[ -n "$GIT_NAME" ]]; then
		git config --global user.name "$GIT_NAME"
		echo-cyan "Git name set to: $GIT_NAME"
	fi
	if [[ -n "$GIT_EMAIL" ]]; then
		git config --global user.email "$GIT_EMAIL"
		echo-cyan "Git email set to: $GIT_EMAIL"
	fi
else
	if ! git config user.name > /dev/null 2>&1; then

		echo-yellow -ne 'Enter your full name for Git commits: '

		echo-white -ne

		read GIT_NAME

		if ! [ -z "${GIT_NAME}" ]; then

			git config --global user.name "$GIT_NAME"

		fi

		echo

	fi

	if ! git config user.email > /dev/null 2>&1; then

		echo-yellow -ne 'Enter your email address for Git commits: '

		echo-white -ne

		read GIT_EMAIL

		if ! [ -z "${GIT_EMAIL}" ]; then

			git config --global user.email $GIT_EMAIL

		fi

		echo

	fi
fi

git --version; echo

echo-green "Git configured!"; echo-white; echo



###############################
# Set up projects directory
###############################
echo-return; echo-cyan 'Setting up projects directory ...'; echo-white

# If not set via GUI mode or CLI argument, ask user
if [[ "$GUI_MODE" != "true" && -z "$PROJECTS_DIR" ]]; then
    DEFAULT_PROJECTS_DIR="$HOME/podium-projects"
    echo-yellow "Where would you like to store your development projects?"
    echo-white "Default: $DEFAULT_PROJECTS_DIR"
    echo-yellow -ne 'Enter projects directory (or press Enter for default): '
    echo-white -ne
    read USER_PROJECTS_DIR
    
    if [[ -z "$USER_PROJECTS_DIR" ]]; then
        PROJECTS_DIR="$DEFAULT_PROJECTS_DIR"
    else
        # Expand ~ to home directory
        PROJECTS_DIR="${USER_PROJECTS_DIR/#\~/$HOME}"
    fi
    echo
fi

# Set default if still empty
if [[ -z "$PROJECTS_DIR" ]]; then
    PROJECTS_DIR="$HOME/podium-projects"
fi

# Create projects directory if it doesn't exist
if [[ ! -d "$PROJECTS_DIR" ]]; then
    echo-cyan "Creating projects directory: $PROJECTS_DIR"
    mkdir -p "$PROJECTS_DIR"
fi

# Verify directory exists and is writable
if [[ ! -d "$PROJECTS_DIR" || ! -w "$PROJECTS_DIR" ]]; then
    echo-red "ERROR: Cannot create or write to projects directory: $PROJECTS_DIR"
    exit 1
fi

# Update .env file with projects directory
sudo-podium-sed-change "/^#PROJECTS_DIR=/" "PROJECTS_DIR=$PROJECTS_DIR" /etc/podium-cli/.env
sudo-podium-sed-change "/^PROJECTS_DIR=/" "PROJECTS_DIR=$PROJECTS_DIR" /etc/podium-cli/.env

echo-green "Projects directory configured: $PROJECTS_DIR"
echo-white; echo



###############################
# Set up Github authentication
###############################
echo-return; echo-cyan 'Setting up Github authentication ...'; echo-white

if ! gh auth status > /dev/null 2>&1; then

	echo
	echo-cyan "GitHub CLI needs to be authenticated for repository operations."
	echo-white "You'll be prompted to:"
	echo-white "  1. Choose authentication method (recommended: SSH)"
	echo-white "  2. Select SSH key (usually: id_rsa.pub)"  
	echo-white "  3. Provide GitHub personal access token"
	echo
	echo-yellow "Starting GitHub authentication process..."
	echo

	gh auth login --hostname github.com

fi

echo-return; echo-green "Github authentication complete!"; echo-white; echo



###############################
# AWS
###############################

# AWS Configuration
if [[ "$SKIP_AWS" == "true" ]]; then
	echo-cyan 'Skipping AWS setup (user choice)'
	echo
elif [[ "$GUI_MODE" == "true" ]]; then
	echo-cyan 'Configuring AWS with GUI-provided settings...'

	mkdir -p ~/s3

	# Install AWS CLI if not present
	if ! aws --version > /dev/null 2>&1; then
		curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" > awscli-bundle.zip
		7z x awscli-bundle.zip
		rm -f awscli-bundle.zip
		sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
		sudo chmod -R o+rx /usr/local/aws-cli/v2/current/dist
		rm -fR aws
	fi

	# Configure AWS with GUI values
	if [[ -n "$AWS_ACCESS_KEY" && -n "$AWS_SECRET_KEY" ]]; then
		aws configure set aws_access_key_id "$AWS_ACCESS_KEY"
		aws configure set aws_secret_access_key "$AWS_SECRET_KEY"
		aws configure set default.region "$AWS_REGION"
		aws configure set default.output json
		
		# Create s3fs password file
		echo "$AWS_ACCESS_KEY:$AWS_SECRET_KEY" > ~/.passwd-s3fs
		chmod 600 ~/.passwd-s3fs
		
		echo-cyan "AWS configured with region: $AWS_REGION"
	fi
else
	echo-cyan 'Installing AWS ...'

	mkdir -p ~/s3

	echo-white

	if ! aws --version > /dev/null 2>&1; then

		curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" > awscli-bundle.zip

		7z x awscli-bundle.zip

		rm -f awscli-bundle.zip

		sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update

		# Bug fix
		sudo chmod -R o+rx /usr/local/aws-cli/v2/current/dist

		rm -fR aws

	fi

	if ! aws configure get default.region > /dev/null; then

		aws configure set default.region us-east-1

	fi

	if ! aws configure get default.output > /dev/null; then

		aws configure set default.output json

	fi

	aws configure

	if ! [ -f ~/.passwd-s3fs ]; then

		# Extract the AWS access key ID
		if AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id); then

			# Extract the AWS secret access key
			if AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key); then

				echo $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY > ~/.passwd-s3fs

				chmod 600 ~/.passwd-s3fs

			fi

		fi

	fi
fi

echo

if [[ "$GUI_MODE" != "true" ]]; then
	aws --version
else
	echo-cyan 'AWS setup skipped in GUI mode'
fi

echo

echo-green "AWS installed!"

echo-white



# Docker and Node installation handled by platform-specific installers



###############################
# Hosts
###############################
echo-cyan 'Writing domain names to hosts file ...'

echo-white

# Add service entries to /etc/hosts
HOSTS_ENTRIES=(
    ".2        mariadb"
    ".3        phpmyadmin" 
    ".4        mongo"
    ".5        redis"
    ".6        postgres"
    ".7        memcached"
    ".8        mailhog"
    ".9        ollama"
)

for HOST in "${HOSTS_ENTRIES[@]}"; do
    if ! cat /etc/hosts | grep "$HOST" > /dev/null 2>&1; then
        echo "$VPC_SUBNET$HOST" | sudo tee -a /etc/hosts > /dev/null
    fi
done

echo



###############################
# Yay all done
###############################

# Configuration complete - docker-stack/.env exists



###############################
# Start services
###############################

# Start services
if [[ "$GUI_MODE" == "true" ]]; then
	echo-cyan 'Setting up docker group permissions...'
	# Add user to docker group if not already there
	sudo usermod -aG docker $USER
	echo-green 'Docker group configured!'
	echo-white
	echo-yellow 'Note: Services can be started from the dashboard after installation'
	echo-white
	echo-green 'GUI installation completed successfully!'
	echo-white
else
	source "$DEV_DIR/scripts/start_services.sh"
fi



###############################
# Yay all done
###############################

# JSON output for configuration
if [[ "$JSON_OUTPUT" == "1" ]]; then
    echo "{\"action\": \"configure\", \"status\": \"success\"}"
else
    echo-green "Configuration completed successfully!"; echo-white
fi

cd "$ORIG_DIR"