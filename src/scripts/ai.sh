#!/bin/bash

set -e

CALLER_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"
cd ..

DEV_DIR=$(pwd)

# Run standard pre-checks (loads /etc/podium-cli/.env, validates projects dir, etc.)
source scripts/pre_check.sh

SCRIPT_DIR="$DEV_DIR/scripts"

# Run the AI agent from the original directory (project root), not the CLI repo
cd "$CALLER_DIR"

usage() {
    echo-white "Usage: podium ai \"<one-off prompt>\""
    echo-white ""
    echo-white "Run a one-off AI agent prompt using the globally configured AI agent and model."
    echo-white "Must be run from a Podium project directory."
}

ONE_OFF_PROMPT="$*"

if [[ -z "$ONE_OFF_PROMPT" ]]; then
    usage
    exit 1
fi

AI_AGENT_CLI_NAME="$AI_AGENT"

if [[ -z "$AI_AGENT_CLI_NAME" ]]; then
    echo-cyan "AI agent is not configured. Run 'podium ai-set' to choose an agent and model."
    echo-white "Prompt:"
    echo-white "$ONE_OFF_PROMPT"
    cd "$CALLER_DIR"
    exit 1
fi

# Map logical CLI name to actual executable when needed
EXEC_AI_AGENT_CLI="$AI_AGENT_CLI_NAME"
if [[ "$AI_AGENT_CLI_NAME" == "deepseek" ]]; then
    EXEC_AI_AGENT_CLI="deepseek-cli"
fi

if ! command -v "$EXEC_AI_AGENT_CLI" >/dev/null 2>&1; then
    echo-yellow "Configured AI agent CLI '$AI_AGENT_CLI_NAME' (command: $EXEC_AI_AGENT_CLI) is not on PATH."
    echo-yellow "Prompt:"
    echo-white "$ONE_OFF_PROMPT"
    cd "$CALLER_DIR"
    exit 0
fi

echo-cyan "Launching AI agent CLI: $AI_AGENT_CLI_NAME (command: $EXEC_AI_AGENT_CLI)"
echo-white

case "$AI_AGENT_CLI_NAME" in
    deepseek)
        if [[ -z "$AI_API_KEY" ]]; then
            echo-yellow "AI_API_KEY is not configured; cannot call DeepSeek CLI."
            echo-yellow "Set AI_API_KEY in /etc/podium-cli/.env and re-run, or run deepseek-cli manually with this prompt:"
            echo-white "$ONE_OFF_PROMPT"
        else
            deepseek-cli chat --api-key "$AI_API_KEY" "$ONE_OFF_PROMPT"
        fi
        ;;
    codex)
        echo-yellow "Using codex exec one-off prompt with the following prompt (this is safe and recommended):"
        echo-white "$ONE_OFF_PROMPT"
        codex_args=(exec)
        if [[ -n "$AI_MODEL" ]]; then
            codex_args+=("--model" "$AI_MODEL")
        fi
        if [[ -n "$AI_API_KEY" ]]; then
            codex_args+=("--api-key" "$AI_API_KEY")
        fi
        codex_args+=("--yolo" "$ONE_OFF_PROMPT")
        codex "${codex_args[@]}"
        ;;
    claude)
        echo-yellow "Using claude one-off prompt with the following prompt (this is safe and recommended):"
        echo-white "$ONE_OFF_PROMPT"
        claude_args=(--dangerously-skip-permissions)
        if [[ -n "$AI_MODEL" ]]; then
            claude_args+=("--model" "$AI_MODEL")
        fi
        if [[ -n "$AI_API_KEY" ]]; then
            claude_args+=("--api-key" "$AI_API_KEY")
        fi
        claude_args+=(-p "$ONE_OFF_PROMPT")
        claude "${claude_args[@]}"
        ;;
    gemini)
        if [[ -n "$AI_API_KEY" ]]; then
            gemini --api-key "$AI_API_KEY" -p "$ONE_OFF_PROMPT"
        else
            gemini -p "$ONE_OFF_PROMPT"
        fi
        ;;
    ollama)
        if [[ -z "$AI_MODEL" ]]; then
            echo-yellow "AI_MODEL is not configured; cannot determine Ollama model."
            echo-yellow "Set AI_MODEL in /etc/podium-cli/.env (for example: llama3.1) and re-run, or run Ollama manually with this prompt:"
            echo-white "$ONE_OFF_PROMPT"
        else
            ollama run "$AI_MODEL" "$ONE_OFF_PROMPT"
        fi
        ;;
    aider)
        echo-yellow "Using aider one-off prompt with the following prompt (this is safe and recommended):"
        echo-white "$ONE_OFF_PROMPT"
        if [[ -n "$AI_MODEL" ]]; then
            aider --model "$AI_MODEL" -m "$ONE_OFF_PROMPT" .
        else
            aider -m "$ONE_OFF_PROMPT" .
        fi
        ;;
    *)
        echo-yellow "Automatic one-off prompt integration is not configured for '$AI_AGENT_CLI_NAME'."
        echo-yellow "Please start your AI agent CLI in this directory and use the following prompt:"
        echo-white "$ONE_OFF_PROMPT"
        ;;
esac

cd "$CALLER_DIR"
