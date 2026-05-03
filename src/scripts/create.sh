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

Read README.md and src/podium before doing anything else. Those two files are all you need. Do not read any other Podium files.

Important workflow:

1. Understand the user's project idea.
2. If the framework or stack is unclear, ask the user which framework they want to use before continuing.
3. If the user is cloning a GitHub URL, assume the repo may already contain a docker-compose.yaml. Inform the user that Podium will replace it with a managed version, then run `podium clone` with --overwrite-docker-compose.
4. If the user is setting up an existing local project directory, check whether a docker-compose.yaml already exists in that directory. If it does, inform the user it will be replaced, then run `podium setup` with --overwrite-docker-compose.
5. Create or enter the Podium-managed project first.
6. After the project exists, look for the generated project's .env file.
7. Use the .env file, if present, to understand available database, cache, mail, and service configuration.
8. Build the app using framework-native conventions.

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
12. If the user provides a GitHub HTTPS URL, clone that repo using `podium clone` with --overwrite-docker-compose and --no-github. Do not fork it. The original repo remains the upstream so the user can pull future updates. Only create a new separate GitHub repo for the user if they explicitly ask for one.
13. If the user's request matches a mature existing open-source app category, it is acceptable to ask whether they want to use/adapt an existing project instead of building from scratch.
14. Never use --json-output with `podium new`. That flag suppresses all output so you cannot tell if the command succeeded or failed. Without --json-output, success and errors are printed to stdout where you can read them.
15. When running `podium clone` or `podium setup`, always pass --overwrite-docker-compose. Existing projects almost always have their own docker-compose.yaml and Podium must replace it with its own managed version.
16. Always pass --no-github to `podium new` and `podium clone` unless the user explicitly asks to create a GitHub repository.

User project idea:

<USER_PROJECT_IDEA>
PREPEND_EOF
)

FULL_PROMPT="${PREPEND/<USER_PROJECT_IDEA>/$USER_IDEA}"

# Start in the podium-cli root so the AI can immediately read README.md and src/podium.
cd "$DEV_DIR/.."

exec "$SCRIPT_DIR/ai.sh" "$FULL_PROMPT"
