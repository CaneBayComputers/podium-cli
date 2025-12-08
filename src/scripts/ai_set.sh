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

# AI agent configuration rules (summary)
# --------------------------------------
# Supported agents and how global vars apply:
#   - deepseek
#       * AI_MODEL: ignored for now
#       * AI_API_KEY: REQUIRED (passed as `--api-key "$AI_API_KEY"` to `deepseek`)
#   - codex
#       * AI_MODEL: OPTIONAL (when set, passed as `--model "$AI_MODEL"` to `codex`)
#       * AI_API_KEY: OPTIONAL (when set, passed as `--api-key "$AI_API_KEY"` to `codex`)
#   - claude
#       * AI_MODEL: OPTIONAL (when set, passed as `--model "$AI_MODEL"` to `claude`)
#       * AI_API_KEY: OPTIONAL (when set, passed as `--api-key "$AI_API_KEY"` to `claude`)
#   - gemini
#       * AI_MODEL: ignored for now
#       * AI_API_KEY: OPTIONAL (when set, passed as `--api-key "$AI_API_KEY"` to `gemini`)
#   - grok
#       * AI_MODEL: OPTIONAL (when set, passed as `--model "$AI_MODEL"` to `grok`)
#       * AI_API_KEY: REQUIRED (passed as `--api-key "$AI_API_KEY"` to `grok`)
#
# Initial-prompt behavior (driven by `podium ai "<prompt>"`):
#   - deepseek : `deepseek [--api-key "$AI_API_KEY"] -q "<prompt>"`
#   - codex    : `codex [--model "$AI_MODEL"] [--api-key "$AI_API_KEY"] --yolo "<prompt>"`
#   - claude   : `claude --dangerously-skip-permissions [--model "$AI_MODEL"] [--api-key "$AI_API_KEY"] "<prompt>"`
#   - gemini   : `gemini [--api-key "$AI_API_KEY"] -i "<prompt>"`
#   - grok     : `grok [--model "$AI_MODEL"] --api-key "$AI_API_KEY" "<prompt>"`

usage() {
    echo-white "Usage: podium ai-set [--agent NAME] [--model NAME] [--api-key KEY] [--json-output]"
    echo-white ""
    echo-white "Configure or inspect the global AI agent settings used by Podium."
    echo-white ""
    echo-white "Options:"
    echo-white "  --agent NAME       Set the AI agent CLI (codex, claude, gemini, deepseek, grok, or custom)."
    echo-white "  --model NAME       Set the AI model name (optional for codex, claude, grok; ignored for gemini, deepseek)."
    echo-white "  --api-key KEY      Set the AI API key (required by deepseek and grok; optional for codex, claude, gemini)."
    echo-white "  --json-output      Output configuration in JSON format (non-interactive)."
    echo-white ""
    echo-white "Notes:"
    echo-white "  - When --json-output is used, no interactive prompts are shown."
    echo-white "  - If called with only --json-output, the current configuration is returned as JSON."
    echo-white "  - Gemini and DeepSeek do not currently use AI_MODEL."
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

# Apply non-interactive overrides
if [[ -n "$NEW_AGENT" ]]; then
    AI_AGENT="$NEW_AGENT"
    # If the agent changed and no explicit model was provided, clear any stale model
    if [[ -z "$NEW_MODEL" ]]; then
        AI_MODEL=""
    fi
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
        echo-white '  1) codex'
        echo-white '  2) claude'
        echo-white '  3) gemini'
        echo-white '  4) deepseek'
        echo-white '  5) grok'
        echo-white '  6) other'
        echo-return
        echo-yellow -ne 'Enter your choice (1-6): '
        echo-white -ne
        read AI_AGENT_CHOICE
        echo-return

        case "$AI_AGENT_CHOICE" in
            1) AI_AGENT="codex"; break ;;
            2) AI_AGENT="claude"; break ;;
            3) AI_AGENT="gemini"; break ;;
            4) AI_AGENT="deepseek"; break ;;
            5) AI_AGENT="grok"; break ;;
            6)
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
                echo-yellow "Invalid selection. Please enter a number between 1 and 6."
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

    echo-yellow -ne 'Enter model name (optional, press Enter to leave blank): '
    echo-white -ne
    read NEW_MODEL
    echo-return
    if [[ -n "$NEW_MODEL" ]]; then
        AI_MODEL="$NEW_MODEL"
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

    if [[ -z "$cli_command" ]]; then
        return 0
    fi

    # If the CLI is already available, nothing to do
    if command -v "$exec_command" >/dev/null 2>&1; then
        echo-green "AI agent CLI '$cli_command' is already installed (command: $exec_command)."
        echo-white
        return 0
    fi

    echo-yellow "AI agent CLI '$cli_command' is not installed. Attempting automatic installation..."

    case "$cli_command" in
        codex)
            npm install -g @openai/codex
            ;;
        gemini)
            npm install -g @google/gemini-cli
            ;;
        claude)
            curl -fsSL https://claude.ai/install.sh | bash
            ;;
        deepseek)
            # Install deepseek-cli via pipx; binary is `deepseek`
            pipx install deepseek-cli
            ;;
        grok)
            npm install -g @vibe-kit/grok-cli
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
    if [[ "$AI_AGENT" == "deepseek" && "$JSON_OUTPUT" != "1" && -z "$AI_API_KEY" ]]; then
        echo-yellow "Warning: AI_API_KEY is not configured; DeepSeek CLI will not work until a key is set."
    fi

    ensure_ai_agent_installed "$AI_AGENT"

    # Persist configuration
    if [[ -n "$AI_AGENT" ]]; then
        sudo-podium-sed-change "/^AI_AGENT=/" "AI_AGENT=$AI_AGENT" /etc/podium-cli/.env
    fi

    if [[ -n "$AI_MODEL" ]]; then
        sudo-podium-sed-change "/^AI_MODEL=/" "AI_MODEL=$AI_MODEL" /etc/podium-cli/.env
    fi

    if [[ -n "$AI_API_KEY" ]]; then
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

if [[ "$AI_AGENT" == "deepseek" || "$AI_AGENT" == "grok" ]]; then
    configure_ai_api_key
fi

ensure_ai_agent_installed "$AI_AGENT"

# Persist configuration
if [[ -n "$AI_AGENT" ]]; then
    sudo-podium-sed-change "/^AI_AGENT=/" "AI_AGENT=$AI_AGENT" /etc/podium-cli/.env
fi

if [[ -n "$AI_MODEL" ]]; then
    sudo-podium-sed-change "/^AI_MODEL=/" "AI_MODEL=$AI_MODEL" /etc/podium-cli/.env
fi

if [[ -n "$AI_API_KEY" ]]; then
    sudo-podium-sed-change "/^AI_API_KEY=/" "AI_API_KEY=$AI_API_KEY" /etc/podium-cli/.env
fi

echo-green "AI agent configuration complete."
echo-white "  Agent: ${AI_AGENT:-<none>}"
echo-white "  Model: ${AI_MODEL:-<none>}"
echo-return

echo-yellow "IMPORTANT:"
echo-white "  All 'podium ai' commands start the selected AI CLI in a high-trust, \"dangerous\" mode (for example: --dangerously-skip-permissions, --yolo, or equivalent)."
echo-white "  Only use 'podium ai' from project directories you are comfortable letting the AI modify extensively."
echo-return

cd "$ORIG_DIR"
