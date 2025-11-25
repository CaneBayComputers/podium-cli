#!/bin/bash

set -e

ORIG_DIR=$(pwd)

cd "$(dirname "$(realpath "$0")")"
cd ..

DEV_DIR=$(pwd)

source scripts/functions.sh

SCRIPT_DIR="$DEV_DIR/scripts"

NEW_AGENT=""
NEW_MODEL=""
NEW_API_KEY=""

usage() {
    echo-white "Usage: podium ai-set [--agent NAME] [--model NAME] [--api-key KEY] [--json-output]"
    echo-white ""
    echo-white "Configure or inspect the global AI agent settings used by Podium."
    echo-white ""
    echo-white "Options:"
    echo-white "  --agent NAME       Set the AI agent CLI (ollama, codex, claude, gemini, deepseek, aider, or custom)."
    echo-white "  --model NAME       Set the AI model name (required for ollama; optional for codex, claude, aider)."
    echo-white "  --api-key KEY      Set the AI API key (used by deepseek and other CLIs that require a key)."
    echo-white "  --json-output      Output configuration in JSON format (non-interactive)."
    echo-white ""
    echo-white "Notes:"
    echo-white "  - When --json-output is used, no interactive prompts are shown."
    echo-white "  - If called with only --json-output, the current configuration is returned as JSON."
    echo-white "  - For ollama, a model is required and must be provided via --model or existing AI_MODEL."
    echo-white "  - Gemini and DeepSeek one-off prompts do not use AI_MODEL (it is ignored for those agents)."
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json-output)
            export JSON_OUTPUT=1
            shift
            ;;
        --agent)
            NEW_AGENT="$2"
            shift 2
            ;;
        --model)
            NEW_MODEL="$2"
            shift 2
            ;;
        --api-key)
            NEW_API_KEY="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            if [[ "$JSON_OUTPUT" == "1" ]]; then
                echo "{\"action\": \"ai_set\", \"status\": \"error\", \"error\": \"unknown_option\", \"details\": \"Unknown option: $1\"}"
            else
                echo-red "Unknown option: $1"
                usage
            fi
            exit 1
            ;;
    esac
done

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

# Load configuration
if [ -f /etc/podium-cli/.env ]; then
    # shellcheck disable=SC1091
    source /etc/podium-cli/.env
fi

# Backward compatibility: if AI_AGENT is empty but AI_AGENT_CLI exists, reuse it
if [[ -z "$AI_AGENT" && -n "$AI_AGENT_CLI" ]]; then
    AI_AGENT="$AI_AGENT_CLI"
fi

# Apply non-interactive overrides
if [[ -n "$NEW_AGENT" ]]; then
    AI_AGENT="$NEW_AGENT"
fi
if [[ -n "$NEW_MODEL" ]]; then
    AI_MODEL="$NEW_MODEL"
fi
if [[ -n "$NEW_API_KEY" ]]; then
    AI_API_KEY="$NEW_API_KEY"
fi

NONINTERACTIVE=0
if [[ "$JSON_OUTPUT" == "1" || -n "$NEW_AGENT" || -n "$NEW_MODEL" || -n "$NEW_API_KEY" ]]; then
    NONINTERACTIVE=1
fi

select_ai_agent() {
    while true; do
        echo-return
        echo-cyan 'AI Agent CLI Selection'; echo-white
        echo-white 'Choose the AI agent CLI you prefer to use:'
        echo-white '  1) ollama'
        echo-white '  2) codex'
        echo-white '  3) claude'
        echo-white '  4) gemini'
        echo-white '  5) deepseek'
        echo-white '  6) aider'
        echo-white '  7) other'
        echo-return
        echo-yellow -ne 'Enter your choice (1-7): '
        echo-white -ne
        read AI_AGENT_CHOICE
        echo-return

        case "$AI_AGENT_CHOICE" in
            1) AI_AGENT="ollama"; break ;;
            2) AI_AGENT="codex"; break ;;
            3) AI_AGENT="claude"; break ;;
            4) AI_AGENT="gemini"; break ;;
            5) AI_AGENT="deepseek"; break ;;
            6) AI_AGENT="aider"; break ;;
            7)
                echo-yellow -ne 'Enter the command name for your AI agent CLI: '
                echo-white -ne
                read CUSTOM_AI_AGENT
                echo-return
                if [[ -z "$CUSTOM_AI_AGENT" ]]; then
                    echo-yellow "AI agent CLI command cannot be empty. Please try again."
                    continue
                fi
                AI_AGENT="$CUSTOM_AI_AGENT"
                break
                ;;
            *)
                echo-yellow "Invalid selection. Please enter a number between 1 and 7."
                ;;
        esac
    done
}

prompt_ai_model() {
    echo-return
    echo-cyan "AI Model Configuration"; echo-white

    if [[ -n "$AI_MODEL" ]]; then
        echo-white "Current model: $AI_MODEL"
    else
        echo-white "No model is currently configured."
    fi

    if [[ "$AI_AGENT" == "ollama" ]]; then
        # Model required for Ollama
        while true; do
            echo-yellow -ne 'Enter Ollama model name (required, for example: llama3.1): '
            echo-white -ne
            read NEW_MODEL
            echo-return
            if [[ -n "$NEW_MODEL" ]]; then
                AI_MODEL="$NEW_MODEL"
                break
            fi
            echo-yellow "Model name cannot be empty for Ollama."
        done
    else
        echo-yellow -ne 'Enter model name (optional, press Enter to leave blank): '
        echo-white -ne
        read NEW_MODEL
        echo-return
        if [[ -n "$NEW_MODEL" ]]; then
            AI_MODEL="$NEW_MODEL"
        fi
    fi
}

configure_ai_api_key() {
    echo-return
    echo-cyan "AI API key configuration"; echo-white
    if [[ -n "$AI_API_KEY" ]]; then
        echo-white "An AI API key is already configured."
        echo-yellow "You can press Enter to keep it, or enter a new key."
    else
        echo-white "No AI API key is currently configured."
    fi
    echo-yellow -ne 'Enter AI API key (Enter to keep existing): '
    echo-white -ne
    read -r NEW_AI_API_KEY
    echo-return

    if [[ -n "$NEW_AI_API_KEY" ]]; then
        AI_API_KEY="$NEW_AI_API_KEY"
    fi
}

ensure_ai_agent_installed() {
    local cli_command="$1"
    local exec_command="$cli_command"

    # DeepSeek uses the deepseek-cli binary even though the logical choice is "deepseek"
    if [[ "$cli_command" == "deepseek" ]]; then
        exec_command="deepseek-cli"
    fi

    if [[ -z "$cli_command" ]]; then
        return 0
    fi

    if command -v "$exec_command" >/dev/null 2>&1; then
        echo-green "AI agent CLI '$cli_command' is already installed (command: $exec_command)."
        echo-white
        return 0
    fi

    echo-yellow "AI agent CLI '$cli_command' is not installed. Attempting automatic installation..."

    case "$cli_command" in
        aider)
            if command -v pipx >/dev/null 2>&1; then
                pipx install aider-chat || true
            elif command -v pip >/dev/null 2>&1; then
                pip install --user aider-chat || true
            else
                echo-yellow "Neither pipx nor pip is available. Please install 'aider' manually."
            fi
            ;;
        ollama)
            if command -v curl >/dev/null 2>&1; then
                curl -fsSL https://ollama.com/install.sh | sh || true
            else
                echo-yellow "curl is not available. Please install 'ollama' manually from https://ollama.com."
            fi
            ;;
        codex)
            if command -v npm >/dev/null 2>&1; then
                npm install -g @openai/codex || true
            else
                echo-yellow "npm is not available. Please install '@openai/codex' globally using npm."
            fi
            ;;
        gemini)
            if command -v npm >/dev/null 2>&1; then
                npm install -g @google/gemini-cli || true
            else
                echo-yellow "npm is not available. Please install '@google/gemini-cli' globally using npm."
            fi
            ;;
        claude)
            if command -v curl >/dev/null 2>&1; then
                curl -fsSL https://claude.ai/install.sh | bash || true
            else
                echo-yellow "curl is not available. Please install the Claude CLI manually from https://claude.ai."
            fi
            ;;
        deepseek)
            if command -v npm >/dev/null 2>&1; then
                npm install -g run-deepseek-cli || true
            else
                echo-yellow "npm is not available. Please install 'run-deepseek-cli' globally using npm."
            fi
            ;;
        *)
            echo-yellow "Automatic installation for '$cli_command' is not configured. Please install it manually."
            ;;
    esac

    if command -v "$exec_command" >/dev/null 2>&1; then
        echo-green "AI agent CLI '$cli_command' installed successfully (command: $exec_command)."
        echo-white
        return 0
    fi

    echo-yellow "AI agent CLI '$cli_command' is still not available on PATH."
        echo-yellow "You can install it manually and re-run 'podium ai-set' or choose a different CLI."
    echo-white
}

if [[ "$NONINTERACTIVE" -eq 1 ]]; then
    # Validation for non-interactive mode
    if [[ "$AI_AGENT" == "ollama" && -z "$AI_MODEL" ]]; then
        if [[ "$JSON_OUTPUT" == "1" ]]; then
            echo "{\"action\": \"ai_set\", \"status\": \"error\", \"error\": \"missing_model\", \"details\": \"AI_MODEL is required when AI_AGENT is 'ollama'.\"}"
        else
            echo-red "Error: AI_MODEL is required when AI_AGENT is 'ollama'."
        fi
        exit 1
    fi

    if [[ "$AI_AGENT" == "deepseek" && "$JSON_OUTPUT" != "1" && -z "$AI_API_KEY" ]]; then
        echo-yellow "Warning: AI_API_KEY is not configured; DeepSeek CLI will not work until a key is set."
    fi

    ensure_ai_agent_installed "$AI_AGENT"

    # Persist configuration
    if [[ -n "$AI_AGENT" ]]; then
        sudo-podium-sed-change "/^#AI_AGENT=/" "AI_AGENT=$AI_AGENT" /etc/podium-cli/.env
        sudo-podium-sed-change "/^AI_AGENT=/" "AI_AGENT=$AI_AGENT" /etc/podium-cli/.env
        # Backward compatibility
        sudo-podium-sed-change "/^#AI_AGENT_CLI=/" "AI_AGENT_CLI=$AI_AGENT" /etc/podium-cli/.env
        sudo-podium-sed-change "/^AI_AGENT_CLI=/" "AI_AGENT_CLI=$AI_AGENT" /etc/podium-cli/.env
    fi

    if [[ -n "$AI_MODEL" ]]; then
        sudo-podium-sed-change "/^#AI_MODEL=/" "AI_MODEL=$AI_MODEL" /etc/podium-cli/.env
        sudo-podium-sed-change "/^AI_MODEL=/" "AI_MODEL=$AI_MODEL" /etc/podium-cli/.env
    fi

    if [[ -n "$AI_API_KEY" ]]; then
        sudo-podium-sed-change "/^#AI_API_KEY=/" "AI_API_KEY=$AI_API_KEY" /etc/podium-cli/.env
        sudo-podium-sed-change "/^AI_API_KEY=/" "AI_API_KEY=$AI_API_KEY" /etc/podium-cli/.env
    fi

    if [[ "$JSON_OUTPUT" == "1" ]]; then
        has_api_key="false"
        if [[ -n "$AI_API_KEY" ]]; then
            has_api_key="true"
        fi
        echo "{\"action\": \"ai_set\", \"status\": \"success\", \"agent\": \"${AI_AGENT:-}\", \"model\": \"${AI_MODEL:-}\", \"has_api_key\": $has_api_key}"
    else
        echo-green "AI agent configuration updated."
        echo-white "  Agent: ${AI_AGENT:-<none>}"
        echo-white "  Model: ${AI_MODEL:-<none>}"
        echo-return
    fi

    cd "$ORIG_DIR"
    exit 0
fi

echo-return
echo-cyan "Podium AI Agent Configuration"; echo-white

if [[ -n "$AI_AGENT" ]]; then
    echo-white "Current AI agent: $AI_AGENT"
    echo-yellow -ne "Do you want to change the AI agent? (y/N): "
    echo-white -ne
    read CHANGE_AGENT
    echo-return
    if [[ "$CHANGE_AGENT" =~ ^[Yy]$ ]]; then
        select_ai_agent
    fi
else
    select_ai_agent
fi

prompt_ai_model

if [[ "$AI_AGENT" == "deepseek" ]]; then
    configure_ai_api_key
fi

ensure_ai_agent_installed "$AI_AGENT"

# Persist configuration
if [[ -n "$AI_AGENT" ]]; then
    sudo-podium-sed-change "/^#AI_AGENT=/" "AI_AGENT=$AI_AGENT" /etc/podium-cli/.env
    sudo-podium-sed-change "/^AI_AGENT=/" "AI_AGENT=$AI_AGENT" /etc/podium-cli/.env
    # Backward compatibility
    sudo-podium-sed-change "/^#AI_AGENT_CLI=/" "AI_AGENT_CLI=$AI_AGENT" /etc/podium-cli/.env
    sudo-podium-sed-change "/^AI_AGENT_CLI=/" "AI_AGENT_CLI=$AI_AGENT" /etc/podium-cli/.env
fi

if [[ -n "$AI_MODEL" ]]; then
    sudo-podium-sed-change "/^#AI_MODEL=/" "AI_MODEL=$AI_MODEL" /etc/podium-cli/.env
    sudo-podium-sed-change "/^AI_MODEL=/" "AI_MODEL=$AI_MODEL" /etc/podium-cli/.env
fi

if [[ -n "$AI_API_KEY" ]]; then
    sudo-podium-sed-change "/^#AI_API_KEY=/" "AI_API_KEY=$AI_API_KEY" /etc/podium-cli/.env
    sudo-podium-sed-change "/^AI_API_KEY=/" "AI_API_KEY=$AI_API_KEY" /etc/podium-cli/.env
fi

echo-green "AI agent configuration complete."
echo-white "  Agent: ${AI_AGENT:-<none>}"
echo-white "  Model: ${AI_MODEL:-<none>}"
echo-return

cd "$ORIG_DIR"
