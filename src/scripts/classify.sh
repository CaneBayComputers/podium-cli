#!/bin/bash

# Stack classification for `podium create`.
#
# Phase 1 of create: ask the AI ONLY which stack fits the user's idea, get a
# small JSON answer back, then let the user confirm with a menu. Podium itself
# then runs `podium new` / `podium install` — deterministically, with no AI
# involved in the actual creation.
#
# This exists because the old single-prompt approach made the agent hold the
# whole 100-app catalogue AND build the app in one context, and a wrong stack
# guess wasn't discovered until after a full build.
#
# Sourced by create.sh. Sets, on success:
#   CHOSEN_KIND  app|framework
#   CHOSEN_SLUG  installer slug or framework name
#   CHOSEN_DB    database engine (frameworks only; empty for apps)
#   CHOSEN_NAME  project directory / hostname
# Returns non-zero if classification failed, so the caller can fall back.

CATALOG_DIR="$DEV_DIR/catalog"

# Compact catalogue text for the prompt. Kept terse — this is paid for on every
# `podium create`.
_catalog_for_prompt() {
    python3 - "$CATALOG_DIR" << 'PYEOF'
import json, os, sys
d = sys.argv[1]
apps = json.load(open(os.path.join(d, "apps.json")))["apps"]
fws  = json.load(open(os.path.join(d, "frameworks.json")))["frameworks"]
print("READY-TO-RUN APPS (installed via `podium install <slug>`; database is fixed by the installer):")
print(", ".join(a["slug"] for a in apps))
print()
print("FRAMEWORKS (scaffolded via `podium new <slug> <name>`; the user writes the app):")
for f in fws:
    print(f"  {f['slug']} — {f['display']} ({f['runtime']}); databases: {', '.join(f['databases'])}")
PYEOF
}

_classifier_prompt() {
    local idea="$1"
    cat << PROMPTEOF
You are helping a user start a new project with Podium. Do NOT create anything.
Your only job is to decide which stack fits, and answer with JSON.

$(_catalog_for_prompt)

The user's idea:

$idea

Decide which options fit. Rules:
- If a ready-to-run app CLOSELY matches the idea, rank it first — it is far
  cheaper and faster than building the same thing from scratch.
- Do NOT force a fit. A vaguely-related app is worse than a custom build: the
  user ends up fighting someone else's product instead of getting what they
  asked for. If nothing matches well, return frameworks only — that is a
  perfectly good answer and is expected for anything bespoke.
- You are NOT limited to the app list.
- Offer between 1 and 4 candidates, best first. Mixing apps and frameworks is
  fine and often the most useful answer.
- For frameworks, recommend databases from that framework's allowed list only.
- Suggest a short lowercase hyphenated project name derived from the idea.

Reply with ONLY this JSON. No prose, no markdown fences:

{
  "project_name": "short-hyphenated-name",
  "candidates": [
    {"kind": "app",       "slug": "<app slug>",       "why": "<max 10 words>"},
    {"kind": "framework", "slug": "<framework slug>", "why": "<max 10 words>"}
  ],
  "databases": ["<engine>", "..."]
}
PROMPTEOF
}

# Pull JSON out of whatever the agent returned and validate every slug against
# the catalogue. Agents wrap JSON in prose or code fences often enough that
# naive parsing fails regularly; anything unrecognised is dropped rather than
# passed downstream where it would become a confusing `podium new` error.
# Takes the agent's reply as a FILE PATH, not on stdin: `python3 - <<EOF` reads
# the script itself from stdin, so a piped payload never reaches sys.stdin.
_parse_classification() {
    local raw_file="$1"
    python3 - "$CATALOG_DIR" "$raw_file" << 'PYEOF'
import json, os, re, sys

cat_dir = sys.argv[1]
raw = open(sys.argv[2], encoding="utf-8", errors="replace").read()

apps = {a["slug"]: a for a in json.load(open(os.path.join(cat_dir, "apps.json")))["apps"]}
fws  = {f["slug"]: f for f in json.load(open(os.path.join(cat_dir, "frameworks.json")))["frameworks"]}

# Strip fences, then take the outermost {...}
raw = re.sub(r"^\s*```[a-zA-Z]*\s*", "", raw.strip())
raw = re.sub(r"\s*```\s*$", "", raw)
start, end = raw.find("{"), raw.rfind("}")
if start == -1 or end == -1 or end <= start:
    sys.exit(1)
try:
    doc = json.loads(raw[start:end + 1])
except Exception:
    sys.exit(1)

out = []
for c in (doc.get("candidates") or []):
    kind, slug = c.get("kind"), (c.get("slug") or "").strip()
    why = (c.get("why") or "").strip().replace("\t", " ")
    if kind == "app" and slug in apps:
        out.append(("app", slug, apps[slug]["display"], apps[slug]["database"], why))
    elif kind == "framework" and slug in fws:
        out.append(("framework", slug, fws[slug]["display"], ",".join(fws[slug]["databases"]), why))
if not out:
    sys.exit(1)

name = (doc.get("project_name") or "").strip().lower()
name = re.sub(r"[^a-z0-9-]+", "-", name).strip("-")[:40]
if not name:
    name = "new-project"

dbs = [d for d in (doc.get("databases") or []) if isinstance(d, str)]

# TSV so bash can read it without another parser.
print("NAME\t" + name)
print("DBS\t" + ",".join(dbs))
for kind, slug, display, db, why in out[:4]:
    print(f"CAND\t{kind}\t{slug}\t{display}\t{db}\t{why}")
PYEOF
}

# Ask the agent, with one retry — a single malformed reply is common enough to
# be worth retrying, but two means something is genuinely wrong and the caller
# should fall back rather than loop.
_run_classifier() {
    local idea="$1" attempt out parsed
    for attempt in 1 2; do
        local tmp; tmp=$(mktemp)
        "$SCRIPT_DIR/ai.sh" --one-off "$(_classifier_prompt "$idea")" > "$tmp" 2>/dev/null || true
        parsed=$(_parse_classification "$tmp" 2>/dev/null) || parsed=""
        rm -f "$tmp"
        if [[ -n "$parsed" ]]; then
            printf '%s' "$parsed"
            return 0
        fi
        [[ $attempt -eq 1 ]] && echo-yellow "Could not read the AI's stack recommendation; retrying once ..." >&2
    done
    return 1
}

# Numbered, coloured menu. Plain text rather than whiptail/dialog so it works
# identically on Linux and macOS with no extra dependency, and matches the
# picker `podium new` already uses.
# Args: prompt, default index, then "label|hint" entries.
_menu_choose() {
    local title="$1" default="$2"; shift 2
    local -a entries=("$@")
    local i=1 choice

    echo-return
    echo-cyan "$title"
    echo-return
    for e in "${entries[@]}"; do
        local label="${e%%|*}" hint="${e#*|}"
        printf "  \033[1;33m%d)\033[0m %s" "$i" "$label" >&2
        [[ -n "$hint" && "$hint" != "$label" ]] && printf "  \033[2m— %s\033[0m" "$hint" >&2
        printf "\n" >&2
        i=$((i + 1))
    done
    echo-return
    echo-yellow -ne "Enter choice [$default]: "
    read choice || choice=""
    echo-return
    [[ -z "$choice" ]] && choice="$default"
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#entries[@]} )); then
        echo-yellow "Invalid choice — using $default."
        choice="$default"
    fi
    printf '%s' "$choice"
}

# Orchestrates phase 1. Falls back to caller on failure.
classify_project() {
    local idea="$1"
    local non_interactive="$2"   # 1 = pick the top recommendation silently

    echo-return
    echo-cyan "Working out which stack fits ..."

    local parsed
    parsed=$(_run_classifier "$idea") || return 1

    local suggested_name suggested_dbs
    suggested_name=$(printf '%s' "$parsed" | awk -F'\t' '$1=="NAME"{print $2; exit}')
    suggested_dbs=$(printf '%s' "$parsed" | awk -F'\t' '$1=="DBS"{print $2; exit}')

    local -a kinds slugs displays dbs whys labels
    while IFS=$'\t' read -r tag kind slug display db why; do
        [[ "$tag" != "CAND" ]] && continue
        kinds+=("$kind"); slugs+=("$slug"); displays+=("$display"); dbs+=("$db"); whys+=("$why")
    done < <(printf '%s\n' "$parsed")

    [[ ${#slugs[@]} -eq 0 ]] && return 1

    local idx=1
    if [[ "$non_interactive" == "1" ]]; then
        idx=1
    else
        # Candidates arrive ranked, best first. Mark the top one only when there
        # is actually a choice to make — "(Recommended)" against a single option
        # is noise.
        local n tag rec=""
        [[ ${#slugs[@]} -gt 1 ]] && rec="  \033[1;32m(Recommended)\033[0m"
        for n in "${!slugs[@]}"; do
            if [[ "${kinds[$n]}" == "app" ]]; then
                tag="(ready-to-run app)"
            else
                tag="(custom build — more tokens and time)"
            fi
            if [[ $n -eq 0 ]]; then
                labels+=("$(printf '%s  %s%b' "${displays[$n]}" "$tag" "$rec")|${whys[$n]}")
            else
                labels+=("${displays[$n]}  $tag|${whys[$n]}")
            fi
        done
        labels+=("I don't know — just choose for me|uses the top recommendation")
        idx=$(_menu_choose "What would you like to build this with?" 1 "${labels[@]}")
        # The trailing "just choose" entry maps back to the first candidate.
        (( idx > ${#slugs[@]} )) && idx=1
    fi

    local sel=$((idx - 1))
    CHOSEN_KIND="${kinds[$sel]}"
    CHOSEN_SLUG="${slugs[$sel]}"
    CHOSEN_DB=""

    if [[ "$CHOSEN_KIND" == "app" ]]; then
        # The installer's compose fixes the engine, so there is nothing to ask.
        local appdb="${dbs[$sel]}"
        if [[ -n "$appdb" ]]; then
            echo-white "Database: $appdb (set by the ${displays[$sel]} installer)"
        else
            echo-white "Database: managed internally by ${displays[$sel]}"
        fi
    else
        # Offer only engines this framework actually works with, recommended first.
        local -a allowed recommended ordered
        IFS=',' read -r -a allowed <<< "${dbs[$sel]}"
        IFS=',' read -r -a recommended <<< "$suggested_dbs"
        local d r
        for r in "${recommended[@]}"; do
            for d in "${allowed[@]}"; do
                [[ "$r" == "$d" ]] && ordered+=("$r")
            done
        done
        for d in "${allowed[@]}"; do
            local seen=0 o
            for o in "${ordered[@]}"; do [[ "$o" == "$d" ]] && seen=1; done
            [[ $seen -eq 0 ]] && ordered+=("$d")
        done

        if [[ "$non_interactive" == "1" || ${#ordered[@]} -eq 1 ]]; then
            CHOSEN_DB="${ordered[0]}"
            [[ ${#ordered[@]} -eq 1 ]] && echo-white "Database: ${ordered[0]} (only engine ${displays[$sel]} supports)"
        else
            local -a dblabels
            local first=1 o
            for o in "${ordered[@]}"; do
                if [[ $first -eq 1 ]]; then dblabels+=("$o|recommended"); first=0
                else dblabels+=("$o|"); fi
            done
            local dbidx
            dbidx=$(_menu_choose "Which database for ${displays[$sel]}?" 1 "${dblabels[@]}")
            CHOSEN_DB="${ordered[$((dbidx - 1))]}"
        fi
    fi

    CHOSEN_NAME="$suggested_name"
    if [[ "$non_interactive" != "1" ]]; then
        echo-return
        echo-yellow -ne "Project name [$CHOSEN_NAME]: "
        local typed
        read typed || typed=""
        echo-return
        [[ -n "$typed" ]] && CHOSEN_NAME=$(echo "$typed" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]\+/-/g; s/^-//; s/-$//')
    fi
    [[ -z "$CHOSEN_NAME" ]] && CHOSEN_NAME="new-project"

    return 0
}
