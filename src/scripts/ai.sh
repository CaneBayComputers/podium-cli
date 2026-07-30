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
    echo-white "Usage: podium ai [--interactive] \"<prompt>\""
    echo-white ""
    echo-white "Send a one-off prompt to your configured AI agent and exit."
    echo-white "Durable project context lives in the project's AGENTS.md, so each"
    echo-white "prompt can stand alone — the agent reads that file to pick the"
    echo-white "project up cold."
    echo-white ""
    echo-white "Options:"
    echo-white "  --interactive, -i  Open a persistent interactive session instead"
    echo-white "  --one-off          Accepted for compatibility (now the default)"
    echo-white ""
    echo-white "Must be run from a Podium project directory."
}

# One-off is the DEFAULT. --interactive opts back into a persistent session;
# --one-off is still accepted so existing scripts and callers keep working.
ONE_OFF=1
PROMPT_ARGS=()
for arg in "$@"; do
    case "$arg" in
        --one-off)
            ONE_OFF=1
            ;;
        --interactive|-i)
            ONE_OFF=0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            PROMPT_ARGS+=("$arg")
            ;;
    esac
done

INIT_PROMPT="${PROMPT_ARGS[*]}"

# An initial prompt is required — no interactive prompt.
if [[ -z "$INIT_PROMPT" ]]; then
    echo-red "No initial prompt provided."
    echo-white "Usage: podium ai [--interactive] \"<prompt>\""
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
    echo-red "Configured AI agent CLI '$AI_AGENT_CLI_NAME' is not on PATH."
    echo-white "Run 'podium ai-set' to choose a different agent, or ensure $AI_AGENT_CLI_NAME is installed."
    cd "$CALLER_DIR"
    exit 1
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
        # Add projects directory to workspace so gemini's file tools can reach it
        if [[ -n "$PROJECTS_DIR_PATH" ]]; then
            gemini_args+=(--include-directories "$PROJECTS_DIR_PATH")
        fi
        if [[ "$ONE_OFF" == "1" ]]; then
            # --output-format text suppresses the xterm.js TUI dump in headless mode
            gemini_args+=(--output-format text --prompt "$INIT_PROMPT")
        else
            gemini_args+=("-i" "$INIT_PROMPT")
        fi
        gemini "${gemini_args[@]}"
        ;;
    aider)
        build_aider_args
        if [[ "$ONE_OFF" == "1" ]]; then
            aider "${AIDER_ARGS[@]}" --message "$INIT_PROMPT"
        else
            write_aider_seed_file "$INIT_PROMPT"
            aider "${AIDER_ARGS[@]}" --load "$AIDER_SEED_FILE"
            rm -f "$AIDER_SEED_FILE"
        fi
        ;;
    *)
        echo-red "Unsupported AI agent: '$AI_AGENT_CLI_NAME'."
        echo-white "Supported agents: codex, claude, gemini, aider"
        echo-white "Run 'podium ai-set' to choose a supported agent."
        exit 1
        ;;
esac

cd "$CALLER_DIR"
