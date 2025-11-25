#!/bin/bash

set -e

ORIG_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"
cd ..

DEV_DIR=$(pwd)

source scripts/functions.sh

SCRIPT_DIR="$DEV_DIR/scripts"

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

# Ensure primary config exists
sudo mkdir -p /etc/podium-cli

if ! [ -f /etc/podium-cli/.env ]; then
    sudo cp "$SCRIPT_DIR/../docker-stack/env.example" /etc/podium-cli/.env

    # Initialize VPC_SUBNET on first creation (same behavior as configure.sh)
    B_CLASS=$((RANDOM % 255 + 1))
    C_CLASS=$((RANDOM % 256))
    VPC_SUBNET="10.$B_CLASS.$C_CLASS"
    sudo-podium-sed-change "/^#VPC_SUBNET=/" "VPC_SUBNET=$VPC_SUBNET" /etc/podium-cli/.env
fi

if [ -f /etc/podium-cli/.env ]; then
    # shellcheck disable=SC1091
    source /etc/podium-cli/.env
fi

# Backward compatibility: if AI_AGENT is empty but AI_AGENT_CLI exists, reuse it
if [[ -z "$AI_AGENT" && -n "$AI_AGENT_CLI" ]]; then
    AI_AGENT="$AI_AGENT_CLI"
fi

AI_AGENT_CLI_NAME="$AI_AGENT"

if [[ -z "$AI_AGENT_CLI_NAME" ]]; then
    echo-cyan "AI agent is not configured. Launching 'podium ai-set' to configure it..."
    echo-white
    podium ai-set
    if [ -f /etc/podium-cli/.env ]; then
        # shellcheck disable=SC1091
        source /etc/podium-cli/.env
    fi
    AI_AGENT_CLI_NAME="$AI_AGENT"
    if [[ -z "$AI_AGENT_CLI_NAME" && -n "$AI_AGENT_CLI" ]]; then
        AI_AGENT_CLI_NAME="$AI_AGENT_CLI"
    fi
fi

if [[ -z "$AI_AGENT_CLI_NAME" ]]; then
    echo-yellow "AI agent is still not configured. Skipping AI agent launch."
    echo-yellow "Prompt:"
    echo-white "$ONE_OFF_PROMPT"
    cd "$ORIG_DIR"
    exit 0
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
    cd "$ORIG_DIR"
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
        if [[ -n "$AI_API_KEY" ]]; then
            codex exec --api-key "$AI_API_KEY" --yolo "$ONE_OFF_PROMPT"
        else
            codex exec --yolo "$ONE_OFF_PROMPT"
        fi
        ;;
    claude)
        echo-yellow "Using claude one-off prompt with the following prompt (this is safe and recommended):"
        echo-white "$ONE_OFF_PROMPT"
        if [[ -n "$AI_API_KEY" ]]; then
            claude --dangerously-skip-permissions --api-key "$AI_API_KEY" -p "$ONE_OFF_PROMPT"
        else
            claude --dangerously-skip-permissions -p "$ONE_OFF_PROMPT"
        fi
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
        aider -m "$ONE_OFF_PROMPT" .
        ;;
    *)
        echo-yellow "Automatic one-off prompt integration is not configured for '$AI_AGENT_CLI_NAME'."
        echo-yellow "Please start your AI agent CLI in this directory and use the following prompt:"
        echo-white "$ONE_OFF_PROMPT"
        ;;
esac

cd "$ORIG_DIR"
