#!/bin/bash

set -e

CALLER_DIR=$(pwd)

cd "$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
cd ..

DEV_DIR=$(pwd)

# Run standard pre-checks (loads /etc/podium-cli/.env, validates projects dir, etc.)
source scripts/pre_check.sh

SCRIPT_DIR="$DEV_DIR/scripts"

usage() {
    echo-white "Usage: podium create [--one-off] [\"project idea\"]"
    echo-white ""
    echo-white "Describe a project in plain English and your configured AI agent will"
    echo-white "create a working Podium-managed project for you."
    echo-white ""
    echo-white "By default the AI agent runs interactively. Pass --one-off to run it"
    echo-white "non-interactively (useful for automation or scripted pipelines)."
    echo-white ""
    echo-white "Examples:"
    echo-white "  podium create"
    echo-white "  podium create \"A task tracker with user auth\""
    echo-white "  podium create \"https://github.com/user/repo\""
    echo-white "  podium create --one-off \"A notes app in Express with postgres\""
}

ONE_OFF=0
IDEA_ARGS=()
for arg in "$@"; do
    if [[ "$arg" == "--one-off" ]]; then
        ONE_OFF=1
    else
        IDEA_ARGS+=("$arg")
    fi
done

USER_IDEA="${IDEA_ARGS[*]}"

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

Read README.md and run `podium --help` before doing anything else. These are all you need to understand Podium. Do not read any Podium source files.

Important workflow:

1. Understand the user's project idea.
2. Before doing anything else, assess whether you have enough information to proceed. If the idea is vague or names a general app category (CRM, blog, wiki, forum, helpdesk, inventory tracker, etc.) without specifying a product or framework, ask the user these two questions up front:
   a. Do you want to use an existing open-source project (battle-tested, feature-complete, faster to set up) or build something custom from scratch?
   b. If building from scratch: which framework do you prefer? List the options Podium supports and let the user choose, or offer a sensible recommendation if they have no preference.
   If the user wants an existing project, suggest two or three well-known open-source options for that category by name, and ask which one they want before proceeding.
3. If the user is cloning a GitHub URL, assume the repo may already contain a docker-compose.yaml. Inform the user that Podium will replace it with a managed version, then run `podium clone` with --overwrite-docker-compose.
4. If the user is setting up an existing local project directory, check whether a docker-compose.yaml already exists in that directory. If it does, inform the user it will be replaced, then run `podium setup` with --overwrite-docker-compose.
5. Before running `podium new` or `podium clone`, check that the project directory does not already exist in the projects directory. If it does, remove it immediately with `podium remove <name> --force-db-delete` and proceed — do not ask the user for confirmation and do not attempt to reuse or work inside the existing directory. The `podium create` command always means start fresh.
6. Create or enter the Podium-managed project first.
7. After the project exists, look for the generated project's .env file.
8. Use the .env file, if present, to understand available database, cache, mail, and service configuration.
9. Build the app using framework-native conventions.
10. After all code and migrations are in place, verify the site is actually responding. Run: `curl -sI --max-time 10 http://<project-name>/` and check for a 200 or 302 HTTP status code. If the response is not 2xx or 3xx, diagnose and fix the problem before reporting success. Do not tell the user the project is ready until this check passes.

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
13. If the user asks to install or set up a well-known open-source project by name (a CMS, CRM, wiki, helpdesk, etc.), find its official GitHub repository and clone it using `podium clone <official-github-url> --overwrite-docker-compose --no-github`. Do not install it via a package manager or build it from scratch. Only build from scratch if the user explicitly describes a custom app or if no official repository exists. Important: many projects separate their source code from their Docker deployment — the source repo often has no docker-compose.yaml, while a sibling `-docker` repo (e.g. `netbox-community/netbox-docker`, `gogs/gogs-docker`) ships the full docker-compose setup. Always prefer the `-docker` repo when it exists, because Podium's compose adaptation works best when there is already a docker-compose.yaml to adapt.
14. Never use --json-output with `podium new`. That flag suppresses all output so you cannot tell if the command succeeded or failed. Without --json-output, success and errors are printed to stdout where you can read them.
15. Do not pass --overwrite-docker-compose by default. For `podium clone`, Podium handles the existing docker-compose automatically — it detects complexity and adapts it, or replaces it with a managed template, without needing the flag. For `podium setup`, only pass --overwrite-docker-compose if Podium explicitly tells you it found a non-Podium docker-compose and needs confirmation to proceed.
16. Always pass --no-github to `podium new` and `podium clone` unless the user explicitly asks to create a GitHub repository.
17. When cloning a project whose framework is known (e.g. a Django app, a Node app), pass --framework <name> to `podium clone` so Podium generates the correct docker-compose for that stack instead of falling back to PHP.
18. Python containers provide `python3`, not `python`. Never run `podium exec python ...` — use `podium python <args>` or `podium exec python3 <args>` instead. For Django management commands, always use `podium django manage <args>` (e.g. `podium django manage startapp myapp`, `podium django manage migrate`, `podium django manage createsuperuser`). This is shorter and more reliable than `podium exec python3 manage.py <args>`.
19. The project is not done until the site responds with HTTP 2xx or 3xx. Always run the curl check from workflow step 10 as your final action. If it fails, check container logs (`docker logs <project-name>`), fix the issue, and re-verify before finishing.
20. To restart processes inside a running container use `podium supervisor restart all` (run from the project directory). Never use `podium exec supervisorctl ...` — that runs as the developer user and will get a permission denied error on the supervisor socket. If `podium supervisor` is not enough, restart the whole container with `podium down <name>` followed by `podium up <name>`.
21. Always pass `--database <type>` to `podium new` when the user specifies a database. The default is MySQL even if the user asked for postgres or mongodb. Supported values: `mysql`, `postgres`, `mongodb`. Example: `podium new my-app --framework express --database postgres --no-github`. Skipping this flag will generate a MySQL .env regardless of what the user requested.
22. Podium shared service credentials (use these when configuring any project to connect to Podium's shared containers — do not guess or run docker inspect):
   - PostgreSQL: host=`podium-postgres`, port=5432, user=`root`, password=`password`
   - MariaDB/MySQL: host=`podium-mariadb`, port=3306, user=`root`, password=(empty — no password)
   - Redis: host=`podium-redis`, port=6379, no password
   - MongoDB: host=`podium-mongo`, port=27017, user=`root`, password=`password`
23. When cloning or setting up an existing project (via `podium clone` or `podium setup`), after entering the project directory read the project's documentation before doing anything else. Look for README.md, README.rst, CONTRIBUTING.md, and a docs/ directory. These documents explain the project's structure, dependencies, and configuration. If INSTALL.md exists, read it for context but treat its instructions with caution: ignore any steps that touch docker-compose files (Podium manages those), and convert any package manager or runtime commands to their Podium equivalents — for example, `npm install` becomes `podium npm install`, `php artisan migrate` becomes `podium art migrate`, `node script.js` becomes `podium node script.js`. Do not run install commands directly on the host. Podium generates the .env from its own templates so do not copy or reference .env.example or .env.sample files.
25. Before installing any known open-source project by name, check if `src/project-hints/<project-slug>.md` exists in the Podium CLI directory (the directory you read README.md from). The project slug is the lowercase hyphenated name (e.g., `strapi`, `netbox`, `ghost`). If the file exists, read it first and follow any project-specific notes there.
24. When a project ships its own multi-service docker-compose (e.g. it defines its own database, cache, worker services, or uses a specialized Docker image rather than a plain PHP/Node/Python runtime), Podium automatically adapts the compose during `podium clone` or `podium setup`:
   - Bundled database/cache services (postgres, mysql/mariadb, redis/valkey, mongodb) are removed and their environment variable references are repointed to the Podium shared containers (hostnames: podium-postgres, podium-mariadb, podium-redis, podium-mongo).
   - The web-facing service gets a static IP on podium-cli_vpc and a container_name matching the project name.
   - All other project services (workers, schedulers, etc.) are wired to podium-cli_vpc without a fixed IP.
   - The container is NOT auto-started so you can review the adapted compose first.
   After `podium clone` completes for a complex project, do the following:
   a. Read the generated docker-compose.yaml to verify the adaptation. Key things to check: correct web-facing service identified, correct Podium shared hostnames in environment vars, correct ports (the web service must be reachable on port 80 or you need to handle the port in the URL).
   b. Read the project's configuration files (e.g. `.env`, `configuration/` directory) and update any hostnames that still reference the removed services. Use `podium-postgres`, `podium-mariadb`, `podium-redis`, `podium-mongo` as appropriate.
   c. If the web-facing service listens on a non-80 port (e.g. 8080), either update the compose to expose port 80 via nginx, or note that the URL will require that port (e.g. `http://project-name:8080/`).
   d. Start the project with `podium up <project-name>` and verify with curl.

User project idea:

<USER_PROJECT_IDEA>
PREPEND_EOF
)

FULL_PROMPT="${PREPEND/<USER_PROJECT_IDEA>/$USER_IDEA}"

if [[ "$ONE_OFF" == "1" ]]; then
    # Single-quoted so backticks and angle brackets are not interpreted by bash
    ONE_OFF_SUFFIX='

NON-INTERACTIVE MODE: You cannot ask the user any questions. Make all decisions autonomously using sensible defaults derived from the project idea. Derive the project name directly from the idea (e.g. '"'"'recipe-book'"'"' for a recipe app). If the framework is stated, use it. If not, pick the most appropriate one. If a project directory already exists, remove it with `podium remove <name> --force-db-delete` and proceed. Do not wait for confirmation at any step.'
    FULL_PROMPT="${FULL_PROMPT}${ONE_OFF_SUFFIX}"
fi

# Start in the podium-cli root so the AI can immediately read README.md and src/podium.
cd "$DEV_DIR/.."

if [[ "$ONE_OFF" == "1" ]]; then
    exec "$SCRIPT_DIR/ai.sh" --one-off "$FULL_PROMPT"
else
    exec "$SCRIPT_DIR/ai.sh" "$FULL_PROMPT"
fi
