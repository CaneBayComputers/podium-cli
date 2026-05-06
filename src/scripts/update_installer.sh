#!/bin/bash

set -e

CALLER_DIR=$(pwd)

cd "$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
cd ..

DEV_DIR=$(pwd)

# Run standard pre-checks (loads /etc/podium-cli/.env, validates projects dir, etc.)
source scripts/pre_check.sh

usage() {
    echo-white "Usage: podium update-installer <app>"
    echo-white "       podium update-installer --all"
    echo-white ""
    echo-white "Launches the configured AI agent with a pre-built prompt that instructs"
    echo-white "it to read AGENTS.md, diff the named installer against the upstream"
    echo-white "project's current docker-compose, regenerate the installer + hint file,"
    echo-white "and verify with an end-to-end test run."
    echo-white ""
    echo-white "Options:"
    echo-white "  --all          Iterate over every installer in src/installers/"
    echo-white "  --one-off      Non-interactive single-shot run (no follow-up turns)"
    echo-white "  --print        Print the prompt to stdout and exit (don't invoke an agent)"
    echo-white "  -h, --help     Show this help"
}

ONE_OFF=0
ALL=0
PRINT_ONLY=0
APP=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)      ALL=1 ;;
        --one-off)  ONE_OFF=1 ;;
        --print)    PRINT_ONLY=1 ;;
        -h|--help)  usage; exit 0 ;;
        --*)        echo-red "Unknown option: $1"; usage; exit 1 ;;
        *)
            if [[ -z "$APP" ]]; then
                APP="$1"
            else
                echo-red "Unexpected extra argument: $1"; usage; exit 1
            fi
            ;;
    esac
    shift
done

if [[ "$ALL" == "1" && -n "$APP" ]]; then
    echo-red "Cannot combine an app name with --all."; exit 1
fi
if [[ "$ALL" == "0" && -z "$APP" ]]; then
    usage; exit 1
fi

if [[ "$ALL" == "0" ]]; then
    if [[ ! -f "$DEV_DIR/installers/$APP.sh" ]]; then
        echo-red "No installer found for: $APP"
        echo-white "Run 'podium install --list' to see available apps."
        exit 1
    fi
fi

# Detect reachable remote test machines (silently — empty if none).
REMOTES=""
for host in cami cassie; do
    if ssh -o ConnectTimeout=3 -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
           "$host@$host" "true" >/dev/null 2>&1; then
        REMOTES="${REMOTES}${REMOTES:+, }$host"
    fi
done

INSTALL_DIR="/usr/local/share/podium-cli"

if [[ "$ALL" == "1" ]]; then
    TARGET_LINE="Update **every** installer in $INSTALL_DIR/src/installers/. Iterate one app at a time, finishing each before moving on (commit per app)."
    SCOPE_LINE="for each installer file in $INSTALL_DIR/src/installers/*.sh"
else
    TARGET_LINE="Update the '$APP' installer at $INSTALL_DIR/src/installers/$APP.sh and its hint file at $INSTALL_DIR/src/project-hints/$APP.md (create the hint if it doesn't exist and one is warranted)."
    SCOPE_LINE="for the '$APP' app"
fi

if [[ -n "$REMOTES" ]]; then
    REMOTES_LINE="Remote test machines reachable via SSH: $REMOTES. Connect as \`ssh <name>@<name>\`. Their podium-cli checkouts live at /usr/local/share/podium-cli (pull with \`sudo git -C /usr/local/share/podium-cli pull\`). You may use these to verify on a second machine, or to parallelize work across machines for --all runs."
else
    REMOTES_LINE="No remote test machines are reachable from this host right now. Verify on the local machine only."
fi

PROMPT=$(cat <<EOF
You are working on the podium-cli repository at $INSTALL_DIR.

# Goal
$TARGET_LINE

# Required reading (do this first)
1. $INSTALL_DIR/AGENTS.md — read in full. The sections you must internalize:
   - "Installer Maintenance Strategy" (this is the workflow you are executing)
   - "Project Hints Library" (rules for what belongs in hint files)
   - "Complex Compose Adaptation" + "Upstream compose preservation"
   - "VPC Networking & IP Allocation" (so any compose you write fits the .2-.8 / .32-.63 / .100-.250 partitioning)
   - "Design Context: What Podium Optimizes For"
2. The existing installer file ($SCOPE_LINE) and any matching hint file in $INSTALL_DIR/src/project-hints/.

# Process per app
1. Read the existing installer + hint file. Note the current image tag, env vars, services, and integration glue.
2. Locate the upstream project's reference docker-compose (typically in their GitHub repo, often \`docker-compose.yml\`, \`docker/docker-compose.yml\`, or \`examples/docker-compose.yml\`). Fetch the current version. Also skim the project's recent CHANGELOG for breaking changes since our installer was last touched.
3. Diff: identify added/removed/renamed env vars, new required services, image schema migrations, integration changes (e.g. new sidecar required, new mount path, new init step).
4. Regenerate the installer to match upstream:
   - Pin image tags to a specific recent version (e.g. \`zulip/docker-zulip:8.0\`, not \`:latest\`). Bumps must be intentional.
   - Preserve Podium conventions: shared service hostnames (podium-postgres, podium-mariadb, podium-redis, podium-mongo, podium-memcached) instead of bundled DBs; entry-point service named in a way that setup_project.sh's web-service detection picks up (\`nginx\`, \`web\`, \`app\`, \`api\`, \`server\`, \`frontend\`, \`backend\`, \`http\`); helper services on the default network without static IPs.
   - Keep the format: INSTALL_DISPLAY, INSTALL_CREDENTIALS, INSTALL_NOTES, optional pre_install(), required write_files(). Generate any required secrets via \`openssl rand -hex\`.
5. Update the hint file (or create one) only with non-obvious gotchas — things an agent would reliably get wrong without guidance. Do not duplicate upstream README content.

# Verification (do this for every app you touch — no exceptions)
1. Run \`podium install $APP\` (or the iterated app name) on this machine. The install must succeed.
2. \`podium status <app>\` must show RUNNING. \`curl -sI http://<app>/\` (or the documented entry path) must return a sane status code (200/301/302/401/403 are all acceptable; 502/000 are failures).
3. $REMOTES_LINE
4. After verifying, run \`podium remove <app> --force-db-delete\` to leave a clean slate before moving on. Do this on every machine you tested on.

# Constraints
- If an upstream project has materially shifted (deprecated, restructured beyond a tractable rewrite, or now requires features Podium doesn't support), document the situation in the commit message and skip rather than committing a broken installer.
- Never commit \`:latest\` tags — pin every image.
- Never commit an installer that hasn't completed end-to-end verification.
- Commit each app as its own commit with a clear message naming the app and what changed (e.g. \`zulip: bump to 8.0, rename SECRETS_* envs\`). Push to origin/master when finished.
- If \`set -e\` aborts mid-run because of \`tput\` (no TTY) or \`trash-put\` (collision), see AGENTS.md "Shell Script Gotchas" for the established workarounds — don't disable \`set -e\`.

Begin.
EOF
)

if [[ "$PRINT_ONLY" == "1" ]]; then
    printf "%s\n" "$PROMPT"
    exit 0
fi

# Verify AI agent is configured (same pattern as ai.sh).
AI_AGENT_CLI_NAME="$AI_AGENT"
if [[ -z "$AI_AGENT_CLI_NAME" ]]; then
    echo-cyan "AI agent is not configured. Run 'podium ai-set' to choose an agent and model."
    exit 1
fi
if ! command -v "$AI_AGENT_CLI_NAME" >/dev/null 2>&1; then
    echo-red "Configured AI agent CLI '$AI_AGENT_CLI_NAME' is not on PATH."
    echo-white "Run 'podium ai-set' to choose a different agent, or ensure $AI_AGENT_CLI_NAME is installed."
    exit 1
fi

# Run the agent from the repo root so file references resolve correctly.
cd "$DEV_DIR"

case "$AI_AGENT_CLI_NAME" in
    codex)
        codex_args=()
        [[ -n "$AI_MODEL" ]] && codex_args+=("--model" "$AI_MODEL")
        [[ -n "$AI_API_KEY" ]] && codex_args+=("--api-key" "$AI_API_KEY")
        codex_args+=(--dangerously-bypass-approvals-and-sandbox)
        if [[ "$ONE_OFF" == "1" ]]; then
            codex exec "${codex_args[@]}" "$PROMPT"
        else
            codex "${codex_args[@]}" "$PROMPT"
        fi
        ;;
    claude)
        claude_args=(--dangerously-skip-permissions)
        [[ "$ONE_OFF" == "1" ]] && claude_args+=(-p)
        [[ -n "$AI_MODEL" ]] && claude_args+=("--model" "$AI_MODEL")
        [[ -n "$AI_API_KEY" ]] && claude_args+=("--api-key" "$AI_API_KEY")
        claude_args+=("$PROMPT")
        claude "${claude_args[@]}"
        ;;
    gemini)
        gemini_args=(--yolo --skip-trust)
        [[ -n "$AI_MODEL" ]] && gemini_args+=("--model" "$AI_MODEL")
        gemini_args+=(--include-directories "$DEV_DIR")
        if [[ "$ONE_OFF" == "1" ]]; then
            gemini_args+=(--output-format text --prompt "$PROMPT")
        else
            gemini_args+=("-i" "$PROMPT")
        fi
        gemini "${gemini_args[@]}"
        ;;
    *)
        echo-red "Unsupported AI agent: '$AI_AGENT_CLI_NAME'."
        echo-white "Supported agents: codex, claude, gemini"
        exit 1
        ;;
esac

cd "$CALLER_DIR"
