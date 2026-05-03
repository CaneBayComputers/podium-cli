#!/bin/bash

set -e

CALLER_DIR=$(pwd)

cd "$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
cd ..

DEV_DIR=$(pwd)

# Run standard pre-checks (loads /etc/podium-cli/.env, validates projects dir, etc.)
source scripts/pre_check.sh

SCRIPT_DIR="$DEV_DIR/scripts"

# Run the AI agent from the original directory (project root), not the CLI repo
cd "$CALLER_DIR"

usage() {
    echo-white "Usage: podium ai [--one-off] \"<initial prompt>\""
    echo-white ""
    echo-white "Start an interactive AI agent session seeded with the given prompt."
    echo-white "Use --one-off to run a single non-interactive prompt and exit."
    echo-white "Must be run from a Podium project directory."
}

ONE_OFF=0
PROMPT_ARGS=()
for arg in "$@"; do
    if [[ "$arg" == "--one-off" ]]; then
        ONE_OFF=1
    else
        PROMPT_ARGS+=("$arg")
    fi
done

INIT_PROMPT="${PROMPT_ARGS[*]}"

if [[ -z "$INIT_PROMPT" ]]; then
    echo-return
    echo-cyan "AI Session Initial Prompt"; echo-white
    echo-white "You're about to start an interactive session with your configured AI agent CLI."
    echo-white "Set the stage with a clear initial instruction for this project."
    echo-return
    echo-yellow -n "Enter initial prompt: "
    echo-white -ne
    read -r INIT_PROMPT
    echo-return
fi

if [[ -z "$INIT_PROMPT" ]]; then
    echo-yellow "No initial prompt provided. Aborting 'podium ai' session."
    cd "$CALLER_DIR"
    exit 1
fi

AI_AGENT_CLI_NAME="$AI_AGENT"

if [[ -z "$AI_AGENT_CLI_NAME" ]]; then
    echo-cyan "AI agent is not configured. Run 'podium ai-set' to choose an agent and model."
    cd "$CALLER_DIR"
    exit 1
fi

if ! command -v "$AI_AGENT_CLI_NAME" >/dev/null 2>&1; then
    echo-yellow "Configured AI agent CLI '$AI_AGENT_CLI_NAME' is not on PATH."
    cd "$CALLER_DIR"
    exit 0
fi

case "$AI_AGENT_CLI_NAME" in
    codex)
        codex_args=()
        if [[ -n "$AI_MODEL" ]]; then
            codex_args+=("--model" "$AI_MODEL")
        fi
        if [[ -n "$AI_API_KEY" ]]; then
            codex_args+=("--api-key" "$AI_API_KEY")
        fi
        codex_args+=(--dangerously-bypass-approvals-and-sandbox)
        if [[ "$ONE_OFF" == "1" ]]; then
            codex exec "${codex_args[@]}" "$INIT_PROMPT"
        else
            codex "${codex_args[@]}" "$INIT_PROMPT"
        fi
        ;;
    claude)
        claude_args=(--dangerously-skip-permissions)
        if [[ "$ONE_OFF" == "1" ]]; then
            claude_args+=(-p)
        fi
        if [[ -n "$AI_MODEL" ]]; then
            claude_args+=("--model" "$AI_MODEL")
        fi
        if [[ -n "$AI_API_KEY" ]]; then
            claude_args+=("--api-key" "$AI_API_KEY")
        fi
        claude_args+=("$INIT_PROMPT")
        claude "${claude_args[@]}"
        ;;
    gemini)
        gemini_args=(--yolo --skip-trust)
        if [[ -n "$AI_MODEL" ]]; then
            gemini_args+=("--model" "$AI_MODEL")
        fi
        if [[ "$ONE_OFF" == "1" ]]; then
            # --output-format text suppresses the xterm.js TUI dump in headless mode
            gemini_args+=(--output-format text --prompt "$INIT_PROMPT")
        else
            gemini_args+=("-i" "$INIT_PROMPT")
        fi
        gemini "${gemini_args[@]}"
        ;;
    *)
        echo-yellow "Automatic integration is not configured for '$AI_AGENT_CLI_NAME'."
        echo-yellow "Please start your AI agent CLI (codex, claude, or gemini) in this directory and use the following prompt:"
        echo-white "$INIT_PROMPT"
        ;;
esac

cd "$CALLER_DIR"
