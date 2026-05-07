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
    echo-white "The AI creates the project non-interactively, then drops you into an"
    echo-white "interactive session inside the new project directory."
    echo-white ""
    echo-white "Pass --one-off to skip the interactive follow-up (useful for automation"
    echo-white "or scripted pipelines)."
    echo-white ""
    echo-white "Examples:"
    echo-white "  podium create"
    echo-white "  podium create \"A task tracker with user auth\""
    echo-white "  podium create \"https://github.com/user/repo\""
    echo-white "  podium create --one-off \"A notes app in Express with postgres\""
}

SKIP_INTERACTIVE=0
IDEA_ARGS=()
for arg in "$@"; do
    if [[ "$arg" == "--one-off" ]]; then
        SKIP_INTERACTIVE=1
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

Read AGENTS.md and run `podium --help` before doing anything else. These are all you need to understand Podium. Do not read any Podium source files.

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
25. When the user asks to set up or install a known open-source application by name, FIRST check whether a Podium installer exists for it by running `ls /usr/local/share/podium-cli/src/installers/`. The installer file name is the lowercase hyphenated project name with a `.sh` extension (e.g. `n8n.sh`, `gitea.sh`, `portainer.sh`). If a matching installer exists, run `podium install <project-name>` — this is always the fastest and most reliable path. It handles all Docker compose setup, database creation, key generation, and startup automatically. Do NOT attempt to clone, build, or hand-craft a docker-compose for any app that has an installer. If the user's prompt includes customization beyond a basic install (e.g. "set up n8n and add a webhook for Slack"), run `podium install <name>` first to get it running, then apply the requested customizations on top.
26. If no installer exists, check if `src/project-hints/<project-slug>.md` exists in the Podium CLI directory (the directory you read AGENTS.md from). The project slug is the lowercase hyphenated name (e.g., `strapi`, `netbox`, `ghost`). If the file exists, read it first and follow any project-specific notes there.
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

# Creation always runs non-interactively — the agent makes all decisions autonomously.
# Single-quoted so backticks and angle brackets inside are not expanded by bash.
ONE_OFF_SUFFIX='

NON-INTERACTIVE MODE: You cannot ask the user any questions. Make all decisions autonomously using sensible defaults derived from the project idea. Derive the project name directly from the idea (e.g. '"'"'recipe-book'"'"' for a recipe app). If the framework is stated, use it. If not, pick the most appropriate one. If a project directory already exists, remove it with `podium remove <name> --force-db-delete` and proceed. Do not wait for confirmation at any step.'

FULL_PROMPT="${PREPEND/<USER_PROJECT_IDEA>/$USER_IDEA}${ONE_OFF_SUFFIX}"

# Start in the podium-cli root so the agent can read AGENTS.md.
cd "$DEV_DIR/.."

# Mark time before creation so we can detect the new project directory afterward.
TIMESTAMP_FILE=$(mktemp)

# Phase 1 runs the AI agent in -p mode (no streaming output), so without a
# progress indicator the terminal looks frozen for what can be 30+ minutes
# on a complex prompt. Show a spinner + elapsed timer + names of files the
# agent has just written to the project directory. TTY-only so we don't
# corrupt piped output or JSON callers.
SPINNER_PID=""
SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

show_progress() {
    local start_ts=$(date +%s)
    local last_check=$start_ts
    local count=0
    local frame=0
    while true; do
        local now=$(date +%s)
        local elapsed=$(( now - start_ts ))
        local mm=$(( elapsed / 60 ))
        local ss=$(( elapsed % 60 ))
        local timer
        if (( mm > 0 )); then timer="${mm}m ${ss}s"; else timer="${ss}s"; fi

        # Every couple of seconds, check the projects dir for newly-written files
        # and announce them above the spinner line.
        if (( now - last_check >= 2 )); then
            while IFS= read -r f; do
                [[ -z "$f" ]] && continue
                local rel="${f#${PROJECTS_DIR_PATH}/}"
                printf "\r\033[K  \033[36m+\033[0m %s\n" "$rel" >&2
                count=$(( count + 1 ))
            done < <(find "$PROJECTS_DIR_PATH" -mindepth 2 -type f \
                -newermt "@$last_check" \
                -not -path '*/node_modules/*' \
                -not -path '*/.git/*' \
                -not -path '*/vendor/*' \
                -not -path '*/__pycache__/*' \
                -not -name 'package-lock.json' \
                -not -name 'composer.lock' \
                -not -name 'yarn.lock' \
                2>/dev/null | head -25)
            last_check=$now
        fi

        printf "\r\033[K\033[36m%s\033[0m  AI agent working...  \033[2m%s  (%d files written)\033[0m" \
            "${SPINNER_FRAMES[frame]}" "$timer" "$count" >&2
        frame=$(( (frame + 1) % 10 ))
        sleep 0.15
    done
}

stop_progress() {
    if [[ -n "$SPINNER_PID" ]] && kill -0 "$SPINNER_PID" 2>/dev/null; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null || true
    fi
    SPINNER_PID=""
    if [[ -t 2 ]]; then
        printf "\r\033[K" >&2
    fi
}

if [[ -t 2 ]]; then
    show_progress &
    SPINNER_PID=$!
    trap 'stop_progress; rm -f "$TIMESTAMP_FILE" 2>/dev/null; exit 130' INT TERM
fi

# Phase 1: create the project non-interactively.
"$SCRIPT_DIR/ai.sh" --one-off "$FULL_PROMPT" || true

stop_progress
trap - INT TERM

# --one-off flag: skip the interactive follow-up (useful for automation/scripted pipelines).
if [[ "$SKIP_INTERACTIVE" == "1" ]]; then
    rm -f "$TIMESTAMP_FILE"
    exit 0
fi

# Phase 2: find the project that was just created or replaced, then start an interactive
# session inside it so the user is in the right directory for continued development.
NEW_PROJECT=$(find "$PROJECTS_DIR_PATH" -maxdepth 1 -mindepth 1 -type d -newer "$TIMESTAMP_FILE" 2>/dev/null | xargs -I{} basename {} 2>/dev/null | head -1)
rm -f "$TIMESTAMP_FILE"

if [[ -n "$NEW_PROJECT" ]] && [[ -d "$PROJECTS_DIR_PATH/$NEW_PROJECT" ]]; then
    echo-return
    echo-cyan "Project ready. Starting interactive session in $NEW_PROJECT..."
    echo-return
    cd "$PROJECTS_DIR_PATH/$NEW_PROJECT"
    exec "$SCRIPT_DIR/ai.sh" "Read README.md to understand the project. It is running at http://$NEW_PROJECT/. You are the developer. Wait for the user's first instruction."
else
    echo-yellow "Could not detect the project directory. Navigate to your project and run 'podium ai' to continue."
fi
