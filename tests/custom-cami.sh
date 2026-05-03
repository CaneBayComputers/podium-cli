#!/bin/bash -l
# Custom project tests — cami, agent: codex

# Load NVM so codex is on PATH before ai-set runs
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.nvm/versions/node/v24.15.0/bin:$PATH"

mkdir -p /tmp/podium-tests/custom-sessions
LOG=/tmp/podium-tests/custom-master.log
PODIUM="/usr/local/bin/podium"

# Switch to codex
$PODIUM ai-set --agent codex
echo "AI agent set to: $(grep '^AI_AGENT=' /etc/podium-cli/.env)"

run_project() {
    local name="$1"
    local idea="$2"
    local logfile="/tmp/podium-tests/custom-sessions/${name}.log"

    echo "[$(date '+%H:%M:%S')] === Starting: $name ===" | tee -a "$LOG"

    TERM=xterm $PODIUM remove "$name" --force-db-delete > /dev/null 2>&1 || true

    timeout 2400 bash -l -c "export PATH=\"\$HOME/.nvm/versions/node/v24.15.0/bin:\$PATH\"; TERM=xterm $PODIUM create --one-off \"$idea\" > \"$logfile\" 2>&1"
    local code=$?
    echo "EXIT:$code" >> "$logfile"

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://${name}/" 2>/dev/null)
    echo "[$(date '+%H:%M:%S')] DONE: $name | exit=$code | HTTP $http_code" | tee -a "$LOG"
}

SUMMARY_SUFFIX='

After the site is verified and the README is written, create a file called SETUP_SUMMARY.md inside the project directory with exactly these sections:
## Project
[project name and framework used]
## Commands Run
[bulleted list of key podium/docker commands you ran]
## Issues & Fixes
[any problems you hit and how you resolved them, or "None" if it went smoothly]
## Result
HTTP status: [e.g. 200 or 302]
URL: http://[project-name]/
Credentials: [default login/password if any, or "None required"]
## Verdict
[one sentence: did setup go smoothly or were there major problems?]'

echo "=== Custom Project Tests (cami / codex) — $(date) ===" | tee "$LOG"
echo "" | tee -a "$LOG"

IDEA1='Build a Laravel pet health records app using `podium new pet-health --framework laravel --no-github`. Track pets with name, species (dog/cat/bird/rabbit/other), breed, date_of_birth, and owner_name. Log vet visits: date, clinic_name, reason, diagnosis, cost. Track vaccinations: vaccine_name, administered_date, due_date. Track medications: name, dosage, start_date, end_date. Pet dashboard page shows the pet'\''s full history and highlights vaccinations due in the next 30 days in yellow. Use MySQL/MariaDB. Seed with 3 pets and realistic health history.'"$SUMMARY_SUFFIX"

IDEA2='Build a FastAPI plant care journal using `podium new plant-journal --framework fastapi --no-github`. Track houseplants: name, common_name, species, room (living-room/bedroom/kitchen/bathroom/office), watering_frequency_days. Log care events: event_type (watered/fertilized/repotted/pruned), date, note. Homepage endpoint returns a "needs attention" list — plants overdue for watering (days since last watered > frequency). Use MySQL/MariaDB. Seed with 8 plants and 30 days of care events so some are overdue.'"$SUMMARY_SUFFIX"

IDEA3='Build a Node.js code snippet manager using `podium new snippets --framework node --no-github`. Snippets have title, description, language (javascript/python/sql/bash/css/go/rust/other), code_content, and tags (comma-separated string). Endpoints: list all, filter by language or tag, view one snippet, create, update, delete. Also a /stats endpoint showing count per language. Use MySQL/MariaDB. Seed with 10 snippets in at least 5 different languages with realistic code content.'"$SUMMARY_SUFFIX"

IDEA4='Build an Express game night tracker using `podium new game-night --framework express --no-github`. Track board games: name, min_players, max_players, play_time_minutes, category (strategy/party/cooperative/trivia/deck-builder). Track players: name, nickname. Log sessions: date, game_played, array of participant names, winner name. Leaderboard endpoint ranks players by win count, win_rate, and games_played. Game detail endpoint shows its full session history. Use MySQL/MariaDB. Seed with 6 games, 5 players, and 20 past sessions.'"$SUMMARY_SUFFIX"

run_project "pet-health"    "$IDEA1" &
run_project "plant-journal" "$IDEA2" &
run_project "snippets"      "$IDEA3" &
run_project "game-night"    "$IDEA4" &

wait

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
