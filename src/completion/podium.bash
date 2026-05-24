# Bash completion for the Podium CLI.
# Installed to /etc/bash_completion.d/podium by `podium configure` (and the
# platform installers). Provides:
#   - subcommand (verb) completion
#   - project-name completion for up/down/status/remove/setup/resume
#   - installer-name completion for install / update-installer
#   - framework/database/agent value completion
#   - per-command flag completion
#
# No dependency on the bash-completion package — we read COMP_WORDS directly.

# Only meaningful in bash with the `complete` builtin.
[ -n "$BASH_VERSION" ] || return 0

# List project directories (reads PROJECTS_DIR from the env file directly so we
# don't pay the cost of invoking `podium` on every TAB).
_podium_projects() {
    local dir=""
    if [ -f /etc/podium-cli/.env ]; then
        dir=$(grep -E '^[[:space:]]*PROJECTS_DIR=' /etc/podium-cli/.env 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"'"'"' ')
        dir="${dir/#\~/$HOME}"
    fi
    [ -z "$dir" ] && dir="$HOME/podium-projects"
    [ -d "$dir" ] && find -L "$dir" -maxdepth 1 -mindepth 1 -type d ! -name '.*' -printf '%f\n' 2>/dev/null
}

# List available installer slugs.
_podium_installers() {
    local d="/usr/local/share/podium-cli/src/installers"
    [ -d "$d" ] || return 0
    local f
    for f in "$d"/*.sh; do
        [ -e "$f" ] || continue
        basename "$f" .sh
    done
}

_podium() {
    local cur prev verb cword
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cword=$COMP_CWORD
    verb="${COMP_WORDS[1]}"

    local verbs="ai ai-set art bash cache-refresh clone composer configure create \
create-installer db-refresh django down exec exec-root exec-tty exec-tty-root help \
install memcache memcache-flush memcache-stats mysql new node npm npx php phpcbf \
phpcs phpmd pip projects-dir python redis redis-flush remove resume setup shell \
start-services status stop-services supervisor supervisor-status tinker uninstall \
up update update-installer wp"

    local frameworks="laravel wordpress php fastapi django python express nestjs fastify node"

    # First token after `podium` → the verb.
    if [ "$cword" -eq 1 ]; then
        COMPREPLY=( $(compgen -W "$verbs" -- "$cur") )
        return 0
    fi

    # Value completion for flags that take an argument.
    case "$prev" in
        --framework)
            COMPREPLY=( $(compgen -W "$frameworks" -- "$cur") ); return 0 ;;
        --database)
            COMPREPLY=( $(compgen -W "mysql postgres mongodb" -- "$cur") ); return 0 ;;
        --agent)
            COMPREPLY=( $(compgen -W "claude codex gemini" -- "$cur") ); return 0 ;;
        --db-name|--version|--github-org|--model|--api-key|--git-name|--git-email|--projects-dir|--vpc-subnet|-f|--file|--prompt-file)
            return 0 ;;  # freeform value — nothing sensible to suggest
    esac

    # Per-verb completion.
    case "$verb" in
        up|down)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--all --json-output --no-colors --debug" -- "$cur") )
            else
                COMPREPLY=( $(compgen -W "$(_podium_projects)" -- "$cur") )
            fi ;;
        status)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--running --json-output --no-colors --debug" -- "$cur") )
            else
                COMPREPLY=( $(compgen -W "$(_podium_projects)" -- "$cur") )
            fi ;;
        remove)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--force-db-delete --preserve-database --force --json-output" -- "$cur") )
            else
                COMPREPLY=( $(compgen -W "$(_podium_projects)" -- "$cur") )
            fi ;;
        resume)
            COMPREPLY=( $(compgen -W "$(_podium_projects)" -- "$cur") ) ;;
        setup)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--framework --db-name --overwrite-env --no-migration --no-storage-symlink --no-startup --overwrite-docker-compose --json-output --no-colors --debug" -- "$cur") )
            else
                COMPREPLY=( $(compgen -W "$(_podium_projects)" -- "$cur") )
            fi ;;
        install)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--list --one-off" -- "$cur") )
            else
                COMPREPLY=( $(compgen -W "$(_podium_installers)" -- "$cur") )
            fi ;;
        update-installer)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--all --one-off --print" -- "$cur") )
            else
                COMPREPLY=( $(compgen -W "$(_podium_installers)" -- "$cur") )
            fi ;;
        new)
            COMPREPLY=( $(compgen -W "--framework --version --database --db-name --no-migration --github --github-org --no-github --public --private --no-storage-symlink --one-off --json-output --no-colors --debug" -- "$cur") ) ;;
        clone)
            COMPREPLY=( $(compgen -W "--framework --database --db-name --overwrite-env --no-migration --overwrite-docker-compose --no-startup --github --github-org --no-github --public --private --no-storage-symlink --one-off --json-output --no-colors --debug" -- "$cur") ) ;;
        create)
            COMPREPLY=( $(compgen -W "--one-off -f --file" -- "$cur") ) ;;
        create-installer)
            COMPREPLY=( $(compgen -W "--one-off --print" -- "$cur") ) ;;
        ai)
            COMPREPLY=( $(compgen -W "--one-off" -- "$cur") ) ;;
        ai-set)
            COMPREPLY=( $(compgen -W "--agent --model --api-key --json-output" -- "$cur") ) ;;
        configure)
            COMPREPLY=( $(compgen -W "--git-name --git-email --projects-dir --vpc-subnet --json-output" -- "$cur") ) ;;
        django)
            [ "$cword" -eq 2 ] && COMPREPLY=( $(compgen -W "manage shell" -- "$cur") ) ;;
        update)
            COMPREPLY=( $(compgen -W "--full" -- "$cur") ) ;;
        uninstall)
            COMPREPLY=( $(compgen -W "--delete-images --json-output" -- "$cur") ) ;;
        *)
            # Unknown / freeform verb — offer global flags only.
            [[ "$cur" == -* ]] && COMPREPLY=( $(compgen -W "--json-output --no-colors --debug --help" -- "$cur") ) ;;
    esac

    return 0
}

complete -F _podium podium
