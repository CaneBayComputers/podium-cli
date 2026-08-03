#!/bin/bash

set -e

CALLER_DIR=$(pwd)

cd "$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
cd ..

DEV_DIR=$(pwd)

source scripts/pre_check.sh

SCRIPT_DIR="$DEV_DIR/scripts"

usage() {
    echo-white "Usage: ${PODIUM_CMD:-$0} <project>"
    echo-white ""
    echo-white "Reopen the AI session for a project, in that project's directory."
    echo-white "Resumes the previous conversation where the agent supports it,"
    echo-white "otherwise starts a fresh one."
    echo-white ""
    echo-white "Options:"
    echo-white "  --help, -h   Show this help message"
}

case "$1" in
    --help|-h)
        usage
        exit 0
        ;;
esac

# A project name is required — no interactive picker.
if [[ -z "$1" ]]; then
    echo-red "No project specified."
    echo-white "Usage: podium resume <project>"
    exit 1
fi
PROJECT_NAME="$1"

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

# Resume the AI session from the project directory
cd "$PROJECT_DIR"

AI_AGENT_CLI_NAME="$AI_AGENT"

if [[ -z "$AI_AGENT_CLI_NAME" ]]; then
    echo-cyan "AI agent is not configured. Run 'podium ai-set' to choose an agent."
    exit 1
fi

notify_resume_fallback() {
    echo-return
    echo-yellow "Could not resume previous session. Starting a new session..."
    echo-return
}

case "$AI_AGENT_CLI_NAME" in
    codex)
        common_args=()
        if [[ -n "$AI_MODEL" ]]; then
            common_args+=("--model" "$AI_MODEL")
        fi
        _export_agent_key OPENAI_API_KEY "sk-"
        _export_agent_base OPENAI_BASE_URL
        common_args+=(--dangerously-bypass-approvals-and-sandbox)
        if ! codex resume --last "${common_args[@]}"; then
            notify_resume_fallback
            exec codex "${common_args[@]}"
        fi
        ;;
    claude)
        common_args=(--dangerously-skip-permissions)
        if [[ -n "$AI_MODEL" ]]; then
            common_args+=("--model" "$AI_MODEL")
        fi
        _export_agent_key ANTHROPIC_API_KEY "sk-ant-"
        _export_agent_base ANTHROPIC_BASE_URL
        if ! claude --continue "${common_args[@]}"; then
            notify_resume_fallback
            exec claude "${common_args[@]}"
        fi
        ;;
    qwen)
        _export_agent_key OPENAI_API_KEY ""
        _export_agent_base OPENAI_BASE_URL
        common_args=(--yolo)
        if [[ -n "$AI_MODEL" ]]; then
            common_args+=("--model" "$AI_MODEL")
        fi
        if ! qwen --resume latest "${common_args[@]}"; then
            notify_resume_fallback
            exec qwen "${common_args[@]}"
        fi
        ;;
    gemini)
        common_args=(--yolo --skip-trust)
        if [[ -n "$AI_MODEL" ]]; then
            common_args+=("--model" "$AI_MODEL")
        fi
        if [[ -n "$PROJECTS_DIR_PATH" ]]; then
            common_args+=(--include-directories "$PROJECTS_DIR_PATH")
        fi
        if ! gemini --resume latest "${common_args[@]}"; then
            notify_resume_fallback
            exec gemini "${common_args[@]}"
        fi
        ;;
    aider)
        build_aider_args
        # --restore-chat-history replays this directory's .aider.chat.history.md.
        # There's nothing to fall back to: with no history aider just opens a
        # fresh session, which is the fallback behavior anyway.
        exec aider "${AIDER_ARGS[@]}" --restore-chat-history
        ;;
    *)
        echo-red "Unsupported AI agent: '$AI_AGENT_CLI_NAME'."
        echo-white "Supported agents: codex, claude, gemini, aider"
        exit 1
        ;;
esac
