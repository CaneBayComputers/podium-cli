#!/bin/bash

set -e

CALLER_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"
cd ..

DEV_DIR=$(pwd)

# Run standard pre-checks (loads /etc/podium-cli/.env, validates projects dir, etc.)
source scripts/pre_check.sh

SCRIPT_DIR="$DEV_DIR/scripts"

usage() {
    echo-white "Usage: podium create [\"project idea\"]"
    echo-white ""
    echo-white "Describe a project in plain English and your configured AI agent will"
    echo-white "create a working Podium-managed project for you."
    echo-white ""
    echo-white "Examples:"
    echo-white "  podium create"
    echo-white "  podium create \"A task tracker with user auth\""
    echo-white "  podium create \"https://github.com/user/repo\""
}

USER_IDEA="$*"

if [[ -z "$USER_IDEA" ]]; then
    echo-return
    echo-cyan "What would you like to build?"; echo-white
    echo-white "Describe your project in plain English. The AI will create a Podium-managed project for you."
    echo-white "You can also paste a GitHub HTTPS URL to clone and set up an existing project."
    echo-return
    echo-yellow -n "Your project idea: "
    echo-white -ne
    read -r USER_IDEA
    echo-return
fi

if [[ -z "$USER_IDEA" ]]; then
    echo-yellow "No project idea provided. Aborting."
    exit 1
fi

# Build the full prompt by substituting the user's idea into the prepend template.
# cat + $() avoids the read -d '' + set -e silent-exit trap (read returns 1 on EOF).
PREPEND=$(cat << 'PREPEND_EOF'
You are creating a new local project using Podium.

Podium is a Docker based local development environment manager.

Your job is to turn the user's plain English project idea into a working Podium managed project.

Read README.md and src/podium to understand available Podium commands and workflow. Those two files are sufficient. Do not read other internal scripts.

Important workflow:

1. Understand the user's project idea.
2. If the framework or stack is unclear, ask the user which framework they want to use before continuing.
3. Create or enter the Podium-managed project first.
4. After the project exists, look for the generated project's .env file.
5. Use the .env file, if present, to understand available database, cache, mail, and service configuration.
6. Build the app using framework-native conventions.

Rules:

1. Use Podium commands and conventions.
2. Do not install runtimes or services directly on the host machine.
3. The user edits files locally, but project tooling should run inside the Podium container.
4. Keep generated app files inside the project directory.
5. Do not modify Podium core files unless the user specifically asked to modify Podium itself.
6. Prefer simple working code over complex architecture.
7. Make the project boot successfully in the Podium environment.
8. Use framework native models, migrations, seeders, fixtures, and configuration when the app needs data.
9. Do not require the user to manually create database tables.
10. If the app needs mail, cache, queues, sessions, or database access, use the available .env configuration when present.
11. Update the generated project's README with startup instructions, local URL, useful commands, and default credentials if any.
12. If the user provides a GitHub HTTPS URL, consider cloning or setting up that project using Podium conventions.
13. If the user's request matches a mature existing open-source app category, it is acceptable to ask whether they want to use/adapt an existing project instead of building from scratch.

User project idea:

<USER_PROJECT_IDEA>
PREPEND_EOF
)

FULL_PROMPT="${PREPEND/<USER_PROJECT_IDEA>/$USER_IDEA}"

# Start in the podium-cli root so the AI can immediately read README.md and src/podium.
cd "$DEV_DIR"

exec "$SCRIPT_DIR/ai.sh" "$FULL_PROMPT"
