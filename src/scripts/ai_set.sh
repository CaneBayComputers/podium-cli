#!/bin/bash

set -e

ORIG_DIR=$(pwd)

cd "$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
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
#   - codex
#       * AI_MODEL: OPTIONAL (when set, passed as `--model "$AI_MODEL"` to `codex`)
#       * AI_API_KEY: OPTIONAL (when set, passed as `--api-key "$AI_API_KEY"` to `codex`) if you choose API-key auth
#   - claude
#       * AI_MODEL: OPTIONAL (when set, passed as `--model "$AI_MODEL"` to `claude`)
#       * AI_API_KEY: OPTIONAL (when set, passed as `--api-key "$AI_API_KEY"` to `claude`)
#   - gemini
#       * AI_MODEL: OPTIONAL (when set, passed as `--model "$AI_MODEL"` to `gemini`)
#       * AI_API_KEY: not used (gemini uses Google account auth or GEMINI_API_KEY env var)
#
# Initial-prompt behavior (driven by `podium ai "<prompt>"`):
#   - codex  : `codex [--model "$AI_MODEL"] [--api-key "$AI_API_KEY"] --dangerously-bypass-approvals-and-sandbox "<prompt>"`
#   - claude : `claude --dangerously-skip-permissions [--model "$AI_MODEL"] [--api-key "$AI_API_KEY"] "<prompt>"`
#   - gemini : `gemini --yolo --skip-trust [--model "$AI_MODEL"] -i "<prompt>"`

usage() {
    echo-white "Usage: podium ai-set [--agent NAME] [--model NAME] [--api-key KEY] [--json-output]"
    echo-white ""
    echo-white "Configure or inspect the global AI agent settings used by Podium."
    echo-white ""
    echo-white "Options:"
    echo-white "  --agent NAME       Set the AI agent CLI (codex, claude, or gemini)."
    echo-white "  --model NAME       Set the AI model name (optional for codex, claude, gemini)."
    echo-white "  --api-key KEY      Set the AI API key (optional for codex and claude)."
    echo-white "  --json-output      Output configuration in JSON format (non-interactive)."
    echo-white ""
    echo-white "Notes:"
    echo-white "  - When --json-output is used, no interactive prompts are shown."
    echo-white "  - If called with only --json-output, the current configuration is returned as JSON."
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
        echo-return
        echo-yellow -ne 'Enter your choice (1-3): '
        echo-white -ne
        read AI_AGENT_CHOICE
        echo-return

        case "$AI_AGENT_CHOICE" in
            1)
                AI_AGENT="codex"
                sudo-podium-sed-change "/^AI_AGENT=/" "AI_AGENT=$AI_AGENT" /etc/podium-cli/.env
                break
                ;;
            2)
                AI_AGENT="claude"
                sudo-podium-sed-change "/^AI_AGENT=/" "AI_AGENT=$AI_AGENT" /etc/podium-cli/.env
                break
                ;;
            3)
                AI_AGENT="gemini"
                sudo-podium-sed-change "/^AI_AGENT=/" "AI_AGENT=$AI_AGENT" /etc/podium-cli/.env
                break
                ;;
            *)
                echo-yellow "Invalid selection. Please enter 1, 2, or 3."
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

configure_codex_auth() {
    echo-return
    echo-cyan "Codex Authentication"; echo-white
    echo-white "You can authenticate Codex via:"
    echo-white "  1) Login (recommended - uses your ChatGPT billing/account)"
    echo-white "  2) API key"
    echo-return
    echo-yellow -ne "Choose authentication method for Codex (1-2): "
    echo-white -ne
    read CODEX_AUTH_CHOICE
    echo-return

    case "$CODEX_AUTH_CHOICE" in
        1)
            while true; do
                echo-yellow "Starting 'codex login' ..."; echo-white
                if codex login; then
                    echo-green "Codex login completed successfully."; echo-white
                    echo-return
                    break
                fi
                echo-yellow "Codex login failed or was cancelled."; echo-white
                echo-yellow -ne "Would you like to try 'codex login' again? (y/N): "
                echo-white -ne
                read RETRY_CODEX_LOGIN
                echo-return
                if [[ ! "$RETRY_CODEX_LOGIN" =~ ^[Yy]$ ]]; then
                    echo-cyan "Continuing without successful Codex login."; echo-white
                    echo-return
                    break
                fi
            done
            ;;
        2)
            echo-return
            echo-white "OpenAI API keys: https://platform.openai.com/api-keys"
            configure_ai_api_key
            ;;
        *)
            echo-yellow "Invalid selection. Skipping Codex authentication helper."; echo-white
            ;;
    esac
}

configure_claude_auth() {
    echo-return
    echo-cyan "Claude Authentication"; echo-white
    echo-white "You can configure Claude via:"
    echo-white "  1) Interactive CLI (run 'claude' to configure)"
    echo-white "  2) API key"
    echo-return
    echo-yellow -ne "Choose authentication method for Claude (1-2): "
    echo-white -ne
    read CLAUDE_AUTH_CHOICE
    echo-return

    case "$CLAUDE_AUTH_CHOICE" in
        1)
            while true; do
                echo-yellow "Starting 'claude' ..."; echo-white
                if claude; then
                    echo-green "Claude CLI finished without errors."; echo-white
                    echo-return
                    break
                fi
                echo-yellow "Claude CLI exited with an error or was cancelled."; echo-white
                echo-yellow -ne "Would you like to run 'claude' again? (y/N): "
                echo-white -ne
                read RETRY_CLAUDE
                echo-return
                if [[ ! "$RETRY_CLAUDE" =~ ^[Yy]$ ]]; then
                    echo-cyan "Continuing without additional Claude setup."; echo-white
                    echo-return
                    break
                fi
            done
            ;;
        2)
            echo-return
            echo-white "Claude API keys: https://console.anthropic.com/"
            configure_ai_api_key
            ;;
        *)
            echo-yellow "Invalid selection. Skipping Claude authentication helper."; echo-white
            ;;
    esac
}

configure_gemini_auth() {
    echo-return
    echo-cyan "Gemini Authentication"; echo-white
    echo-white "You can configure Gemini via:"
    echo-white "  1) Interactive CLI (run 'gemini' to configure)"
    echo-white "  2) API key"
    echo-return
    echo-yellow -ne "Choose authentication method for Gemini (1-2): "
    echo-white -ne
    read GEMINI_AUTH_CHOICE
    echo-return

    case "$GEMINI_AUTH_CHOICE" in
        1)
            while true; do
                echo-yellow "Starting 'gemini' ..."; echo-white
                if gemini; then
                    echo-green "Gemini CLI finished without errors."; echo-white
                    echo-return
                    break
                fi
                echo-yellow "Gemini CLI exited with an error or was cancelled."; echo-white
                echo-yellow -ne "Would you like to run 'gemini' again? (y/N): "
                echo-white -ne
                read RETRY_GEMINI
                echo-return
                if [[ ! "$RETRY_GEMINI" =~ ^[Yy]$ ]]; then
                    echo-cyan "Continuing without additional Gemini setup."; echo-white
                    echo-return
                    break
                fi
            done
            ;;
        2)
            echo-return
            echo-white "Gemini API keys: https://aistudio.google.com/app/api-keys"
            configure_ai_api_key
            ;;
        *)
            echo-yellow "Invalid selection. Skipping Gemini authentication helper."; echo-white
            ;;
    esac
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
    else
        # Ensure current agent is persisted immediately as well
        sudo-podium-sed-change "/^AI_AGENT=/" "AI_AGENT=$AI_AGENT" /etc/podium-cli/.env
    fi
else
    select_ai_agent
fi

prompt_ai_model

ensure_ai_agent_installed "$AI_AGENT"

if [[ "$AI_AGENT" == "codex" ]]; then
    configure_codex_auth
elif [[ "$AI_AGENT" == "claude" ]]; then
    configure_claude_auth
elif [[ "$AI_AGENT" == "gemini" ]]; then
    configure_gemini_auth
fi

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
