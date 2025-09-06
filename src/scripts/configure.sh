#!/bin/bash

set -e


ORIG_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"

cd ..

DEV_DIR=$(pwd)

source scripts/functions.sh

# Define SCRIPT_DIR for file operations
SCRIPT_DIR="$DEV_DIR/scripts"

# Parse arguments
GIT_NAME=""
GIT_EMAIL=""
AWS_ACCESS_KEY=""
AWS_SECRET_KEY=""
AWS_REGION="us-east-1"
SKIP_AWS=false
PROJECTS_DIR=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --json-output)
            export JSON_OUTPUT=1
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

        *)
            shift
            ;;
    esac
done




# Check for and set up environment variables
# Use /etc/podium-cli/ as primary config location
sudo mkdir -p /etc/podium-cli

if ! [ -f /etc/podium-cli/.env ]; then

	sudo cp "$SCRIPT_DIR/../docker-stack/env.example" /etc/podium-cli/.env

	# Generate random numbers for B and C classes
	B_CLASS=$((RANDOM % 255 + 1))
	C_CLASS=$((RANDOM % 256))

	VPC_SUBNET="10.$B_CLASS.$C_CLASS"

	# Cross-platform sed with proper c\ command handling
	sudo-podium-sed-change "/^#VPC_SUBNET=/" "VPC_SUBNET=$VPC_SUBNET" /etc/podium-cli/.env

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
	
	
	echo-return

fi

# Check if running as root
if [[ "$(whoami)" == "root" ]]; then
	error "Do NOT run with sudo or as root! Please run as regular user (you may be prompted for sudo password when needed)."
fi

# Install Podium command globally
echo-return
echo-cyan "Installing Podium command globally..."
echo-white "Creating 'podium' command accessible from anywhere on your system."
echo-white "You'll be prompted for your password to install to /usr/local/bin"
echo-return

if ! sudo -v; then
	error "No sudo privileges. Root access required!"
fi

# Remove existing symlink if it exists
sudo rm -f /usr/local/bin/podium 2>/dev/null || true

# Create symlink to podium script
sudo ln -sf "$DEV_DIR/podium" /usr/local/bin/podium



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
if [[ "$JSON_OUTPUT" == "1" ]]; then
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

		echo-return

	fi

	if ! git config user.email > /dev/null 2>&1; then

		echo-yellow -ne 'Enter your email address for Git commits: '

		echo-white -ne

		read GIT_EMAIL

		if ! [ -z "${GIT_EMAIL}" ]; then

			git config --global user.email $GIT_EMAIL

		fi

		echo-return

	fi
fi

git --version; echo

echo-green "Git configured!"; echo-white; echo



###############################
# Set up projects directory
###############################
echo-return; echo-cyan 'Setting up projects directory ...'; echo-white

# If not set via JSON mode or CLI argument, ask user
if [[ "$JSON_OUTPUT" != "1" && -z "$PROJECTS_DIR" ]]; then
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
	echo-return
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
    error "ERROR: Cannot create or write to projects directory: $PROJECTS_DIR"
fi

# Update .env file with projects directory
sudo-podium-sed-change "/^#PROJECTS_DIR=/" "PROJECTS_DIR=$PROJECTS_DIR" /etc/podium-cli/.env
sudo-podium-sed-change "/^PROJECTS_DIR=/" "PROJECTS_DIR=$PROJECTS_DIR" /etc/podium-cli/.env

echo-green "Projects directory configured: $PROJECTS_DIR"
echo-white; echo



###############################
# Set up Github authentication
###############################
if [[ "$JSON_OUTPUT" == "1" ]]; then
	echo-cyan 'Skipping GitHub authentication in GUI mode'
	echo-white 'GitHub setup can be done later if needed for repository operations'
	echo-return
else
	echo-return; echo-cyan 'GitHub Authentication Setup'; echo-white
	
	if ! gh auth status > /dev/null 2>&1; then
		echo-return
		echo-cyan "GitHub CLI can be set up for repository operations."
		echo-white "This process requires:"
		echo-white "  1. A GitHub account"
		echo-white "  2. Choosing authentication method (SSH recommended)"
		echo-white "  3. Selecting your SSH key (usually: id_rsa.pub)"  
		echo-white "  4. Creating/providing a GitHub personal access token"
		echo-white "  5. Following the web browser authentication flow"
		echo-return
		echo-yellow "This is optional - you can skip and set up later if needed."
		echo-return
		read -p "Do you want to set up GitHub authentication now? [N/y]: " -n 1 -r SETUP_GITHUB
		echo-return
		
		if [[ $SETUP_GITHUB =~ ^[Yy]$ ]]; then
			echo-return
			echo-yellow "Starting GitHub authentication process..."
			echo-return
			gh auth login --hostname github.com
			echo-return; echo-green "GitHub authentication complete!"; echo-white; echo
		else
			echo-cyan "Skipping GitHub authentication"
			echo-white "You can set it up later with: gh auth login"
			echo-return
		fi
	else
		echo-green "GitHub authentication already configured!"; echo-white; echo
	fi
fi



###############################
# AWS
###############################

# AWS Configuration
if [[ "$SKIP_AWS" == "true" ]]; then
	echo-cyan 'Skipping AWS setup (user choice)'
	echo-return
elif [[ "$JSON_OUTPUT" == "1" ]]; then
	if [[ -n "$AWS_ACCESS_KEY" && -n "$AWS_SECRET_KEY" ]]; then
		echo-cyan 'Configuring AWS with GUI-provided settings...'

		mkdir -p ~/s3

		# Configure AWS with GUI values
		aws configure set aws_access_key_id "$AWS_ACCESS_KEY"
		aws configure set aws_secret_access_key "$AWS_SECRET_KEY"
		aws configure set default.region "$AWS_REGION"
		aws configure set default.output json
		
		# Create s3fs password file
		echo "$AWS_ACCESS_KEY:$AWS_SECRET_KEY" > ~/.passwd-s3fs
		chmod 600 ~/.passwd-s3fs
		
		echo-cyan "AWS configured with region: $AWS_REGION"
		echo-return
	else
		echo-cyan 'Skipping AWS setup in GUI mode (no credentials provided)'
		echo-return
	fi
else
	echo-return; echo-cyan 'AWS Setup'; echo-white
	
	echo-cyan "AWS CLI can be configured for cloud storage and services."
	echo-white "To set up AWS, you will need:"
	echo-white "  1. An AWS account (aws.amazon.com)"
	echo-white "  2. Your AWS Access Key ID"
	echo-white "  3. Your AWS Secret Access Key"
	echo-white "  4. Your preferred AWS region (e.g., us-east-1)"
	echo-return
	echo-white "To get your AWS credentials:"
	echo-white "  • Log into AWS Console → IAM → Users → Your User → Security Credentials"
	echo-white "  • Create Access Key → Command Line Interface (CLI)"
	echo-white "  • Download or copy the Access Key ID and Secret Access Key"
	echo-return
	echo-yellow "This is optional - you can skip and set up later if needed."
	echo-return
	read -p "Do you want to set up AWS now? [N/y]: " -n 1 -r SETUP_AWS
	echo-return
	
	if [[ $SETUP_AWS =~ ^[Yy]$ ]]; then
		echo-cyan 'Setting up AWS...'

		mkdir -p ~/s3

		echo-white


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
	else
		echo-cyan "Skipping AWS setup"
		echo-white "You can set it up later with: aws configure"
		echo-return
	fi

fi

echo-return

if [[ "$JSON_OUTPUT" != "1" ]]; then
	if command -v aws >/dev/null 2>&1; then
		aws --version
		echo-green "AWS setup completed!"
	else
		echo-cyan "AWS setup skipped"
	fi
else
	echo-cyan 'AWS setup completed in GUI mode'
fi

echo-white



# Docker and Node installation handled by platform-specific installers



###############################
# Hosts
###############################
echo-cyan 'Writing domain names to hosts file ...'

echo-white

# Dynamically get container names from docker-compose.yaml
COMPOSE_FILE="/etc/podium-cli/docker-compose.yaml"

if [ -f "$COMPOSE_FILE" ]; then
    # Extract container names from docker-compose file
    CONTAINER_NAMES=$(grep -E "^\s*container_name:" "$COMPOSE_FILE" | sed 's/.*container_name:[[:space:]]*\([^[:space:]]*\).*/\1/' | tr '\n' ' ')
    
    if [ -n "$CONTAINER_NAMES" ]; then
        # Start IP counter for hosts file entries
        IP_COUNTER=2
        
        for container_name in $CONTAINER_NAMES; do
            # Check if entry already exists in hosts file
            if ! grep -q "[[:space:]]${container_name}[[:space:]]*$" /etc/hosts 2>/dev/null; then
                echo-white "Adding hosts entry: $VPC_SUBNET.$IP_COUNTER -> $container_name"
                echo "$VPC_SUBNET.$IP_COUNTER        $container_name" | sudo tee -a /etc/hosts > /dev/null
            fi
            ((IP_COUNTER++))
        done
        echo-green "Hosts file updated with container entries"
    else
        echo-yellow "No container names found in docker-compose file"
    fi
else
    echo-yellow "Docker compose file not found: $COMPOSE_FILE"
fi

echo-return

echo-green "Configuration completed successfully!"; echo-white




###############################
# Start services
###############################
if [[ "$JSON_OUTPUT" == "1" ]]; then
    # Capture start_services JSON output
    START_SERVICES_OUTPUT=$(source "$DEV_DIR/scripts/start_services.sh" 2>&1)
    START_SERVICES_RESULT=$?
    
    if [ $START_SERVICES_RESULT -eq 0 ]; then
        # Merge the start_services JSON output with configure result
        echo "{\"action\": \"configure\", \"status\": \"success\", \"services_result\": $START_SERVICES_OUTPUT}"
    else
        echo "{\"action\": \"configure\", \"status\": \"success\", \"warning\": \"Services failed to start but configuration completed\", \"services_result\": null}"
    fi
else
    source "$DEV_DIR/scripts/start_services.sh"
fi

cd "$ORIG_DIR"