#!/bin/bash

# Write display metadata into a project's x-metadata block.
#
# Exists so nothing outside the CLI has to edit docker-compose.yaml. The GUI was
# doing it with targeted regexes, carefully enough not to disturb last_on or
# status -- which works, but makes every consumer responsible for preserving
# keys it does not own, and needs filesystem access it otherwise would not need
# once it manages remote hosts.
#
# Only the three human-editable fields are settable here. last_on is written by
# start/stop and status by enable/disable; letting them be set by hand would let
# a project claim to be enabled while parked.

set -e

ORIG_DIR=$(pwd)
cd "$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
cd ..
DEV_DIR=$(pwd)

source scripts/pre_check.sh

PROJECT_NAME=""
NEW_EMOJI=""; SET_EMOJI=0
NEW_NAME="";  SET_NAME=0
NEW_DESC="";  SET_DESC=0
JSON_OUTPUT="${JSON_OUTPUT:-}"

usage() {
    echo-white "Usage: zeltro set-metadata <project> [options]"
    echo-white ""
    echo-white "Set the display metadata shown for a project."
    echo-white ""
    echo-white "Options:"
    echo-white "  --emoji EMOJI          Emoji shown next to the project"
    echo-white "  --name NAME            Display name (the project slug is unchanged)"
    echo-white "  --description TEXT     One-line description"
    echo-white "  --json-output          Machine-readable result"
    echo-white "  --help                 Show this message"
    echo-white ""
    echo-white "last_on and status are not settable: they are written by"
    echo-white "start/stop and by 'zeltro disable'/'zeltro enable'."
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --emoji)       NEW_EMOJI="${2-}"; SET_EMOJI=1; shift 2 ;;
        --name)        NEW_NAME="${2-}";  SET_NAME=1;  shift 2 ;;
        --description) NEW_DESC="${2-}";  SET_DESC=1;  shift 2 ;;
        --json-output) JSON_OUTPUT=1; export JSON_OUTPUT; shift ;;
        --no-colors)   NO_COLOR=1; export NO_COLOR; shift ;;
        --help|-h)     usage; exit 0 ;;
        -*)            error "Unknown option: $1" ;;
        *)
            if [ -z "$PROJECT_NAME" ]; then PROJECT_NAME="$1"; else error "Too many arguments"; fi
            shift ;;
    esac
done

if [ -z "$PROJECT_NAME" ]; then
    [[ "$JSON_OUTPUT" == "1" ]] && json_error "project name is required"
    usage; exit 1
fi

if [ "$SET_EMOJI" = "0" ] && [ "$SET_NAME" = "0" ] && [ "$SET_DESC" = "0" ]; then
    [[ "$JSON_OUTPUT" == "1" ]] && json_error "nothing to set: pass --emoji, --name or --description"
    error "Nothing to set. Pass at least one of --emoji, --name or --description."
fi

PROJECT_DIR="$PROJECTS_DIR_PATH/$PROJECT_NAME"
if [ ! -d "$PROJECT_DIR" ]; then
    [[ "$JSON_OUTPUT" == "1" ]] && json_error "project '$PROJECT_NAME' not found"
    error "Project '$PROJECT_NAME' not found in $PROJECTS_DIR_PATH."
fi

COMPOSE_FILE="$(zeltro_project_compose "$PROJECT_NAME")"
if [ -z "$COMPOSE_FILE" ]; then
    [[ "$JSON_OUTPUT" == "1" ]] && json_error "project '$PROJECT_NAME' has no docker-compose file"
    error "Project '$PROJECT_NAME' has no docker-compose file. Run: zeltro setup $PROJECT_NAME"
fi

_fail() {
    [[ "$JSON_OUTPUT" == "1" ]] && json_error "could not write project metadata"
    error "Could not update project metadata."
}

# Written one key at a time on purpose: set_x_metadata_key rewrites only the key
# it is given, so keys this command does not own (last_on, status) are never at
# risk of being dropped by a bulk rewrite.
[ "$SET_EMOJI" = "1" ] && { set_x_metadata_key "$COMPOSE_FILE" "$PROJECT_NAME" "emoji"       "$NEW_EMOJI" || _fail; }
[ "$SET_NAME"  = "1" ] && { set_x_metadata_key "$COMPOSE_FILE" "$PROJECT_NAME" "name"        "$NEW_NAME"  || _fail; }
[ "$SET_DESC"  = "1" ] && { set_x_metadata_key "$COMPOSE_FILE" "$PROJECT_NAME" "description" "$NEW_DESC"  || _fail; }

UPDATED="$(read_x_metadata_json "$COMPOSE_FILE")"
[ -n "$UPDATED" ] || UPDATED="{}"

if [[ "$JSON_OUTPUT" == "1" ]]; then
    echo "{\"action\": \"set_metadata\", \"status\": \"success\", \"project\": \"$PROJECT_NAME\", \"metadata\": $UPDATED}"
else
    echo-green "Metadata updated for '$PROJECT_NAME'."
    [ "$SET_EMOJI" = "1" ] && echo-white "  emoji:       $NEW_EMOJI"
    [ "$SET_NAME"  = "1" ] && echo-white "  name:        $NEW_NAME"
    [ "$SET_DESC"  = "1" ] && echo-white "  description: $NEW_DESC"
fi

cd "$ORIG_DIR"
