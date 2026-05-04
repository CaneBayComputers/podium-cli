#!/bin/bash

set -e

CALLER_DIR=$(pwd)

cd "$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
cd ..

DEV_DIR=$(pwd)

source scripts/pre_check.sh

SCRIPT_DIR="$DEV_DIR/scripts"

# Build sorted list of project directories
mapfile -t PROJECTS < <(find "$PROJECTS_DIR_PATH" -maxdepth 1 -mindepth 1 -type d | xargs -I{} basename {} | sort)

if [[ ${#PROJECTS[@]} -eq 0 ]]; then
    echo-yellow "No projects found in $PROJECTS_DIR_PATH."
    exit 1
fi

# If a project name was passed directly, use it
if [[ -n "$1" ]]; then
    PROJECT_NAME="$1"
else
    echo-return
    echo-cyan "Select a project to resume:"
    echo-return
    for i in "${!PROJECTS[@]}"; do
        printf "  %2d) %s\n" "$((i + 1))" "${PROJECTS[$i]}"
    done
    echo-return
    echo-yellow -n "Enter number: "
    echo-white -ne
    read -r SELECTION
    echo-return

    if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || (( SELECTION < 1 || SELECTION > ${#PROJECTS[@]} )); then
        echo-red "Invalid selection."
        exit 1
    fi

    PROJECT_NAME="${PROJECTS[$((SELECTION - 1))]}"
fi

PROJECT_DIR="$PROJECTS_DIR_PATH/$PROJECT_NAME"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo-red "Project directory not found: $PROJECT_DIR"
    exit 1
fi

# Start the project
echo-cyan "Starting $PROJECT_NAME..."
(cd "$PROJECTS_DIR_PATH" && "$SCRIPT_DIR/startup.sh" "$PROJECT_NAME")

echo-return

# Show status
(cd "$PROJECTS_DIR_PATH" && "$SCRIPT_DIR/status.sh" "$PROJECT_NAME")

echo-return
echo-cyan "============================================"
echo-cyan "  Project : $PROJECT_NAME"
echo-cyan "  URL     : http://$PROJECT_NAME/"
echo-cyan "============================================"
echo-return
echo-white "Ctrl+click (or right-click) the URL above to open it in your browser."
echo-white "The AI will resume the last session for this project."
echo-return
echo-yellow "Press any key to start the AI session..."
read -r -s -n 1
echo-return

# Resume the AI session from the project directory
cd "$PROJECT_DIR"

AI_AGENT_CLI_NAME="$AI_AGENT"

if [[ -z "$AI_AGENT_CLI_NAME" ]]; then
    echo-cyan "AI agent is not configured. Run 'podium ai-set' to choose an agent."
    exit 1
fi

case "$AI_AGENT_CLI_NAME" in
    codex)
        resume_args=()
        if [[ -n "$AI_MODEL" ]]; then
            resume_args+=("--model" "$AI_MODEL")
        fi
        if [[ -n "$AI_API_KEY" ]]; then
            resume_args+=("--api-key" "$AI_API_KEY")
        fi
        resume_args+=(--dangerously-bypass-approvals-and-sandbox)
        exec codex resume --last "${resume_args[@]}"
        ;;
    claude)
        resume_args=(--dangerously-skip-permissions --continue)
        if [[ -n "$AI_MODEL" ]]; then
            resume_args+=("--model" "$AI_MODEL")
        fi
        if [[ -n "$AI_API_KEY" ]]; then
            resume_args+=("--api-key" "$AI_API_KEY")
        fi
        exec claude "${resume_args[@]}"
        ;;
    gemini)
        resume_args=(--yolo --skip-trust --resume latest)
        if [[ -n "$AI_MODEL" ]]; then
            resume_args+=("--model" "$AI_MODEL")
        fi
        if [[ -n "$PROJECTS_DIR_PATH" ]]; then
            resume_args+=(--include-directories "$PROJECTS_DIR_PATH")
        fi
        exec gemini "${resume_args[@]}"
        ;;
    *)
        echo-red "Unsupported AI agent: '$AI_AGENT_CLI_NAME'."
        echo-white "Supported agents: codex, claude, gemini"
        exit 1
        ;;
esac
