#!/bin/bash -l
# Custom project tests — dingdong, agent: claude

mkdir -p /tmp/podium-tests/custom-sessions
LOG=/tmp/podium-tests/custom-master.log
PODIUM="/usr/local/bin/podium"

run_project() {
    local name="$1"
    local idea="$2"
    local logfile="/tmp/podium-tests/custom-sessions/${name}.log"

    echo "[$(date '+%H:%M:%S')] === Starting: $name ===" | tee -a "$LOG"

    TERM=xterm $PODIUM remove "$name" --force-db-delete > /dev/null 2>&1 || true

    timeout 2400 bash -l -c "TERM=xterm $PODIUM create --one-off \"$idea\" > \"$logfile\" 2>&1"
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

echo "=== Custom Project Tests (dingdong / claude) — $(date) ===" | tee "$LOG"
echo "Agent: $(grep '^AI_AGENT=' /etc/podium-cli/.env)" | tee -a "$LOG"
echo "" | tee -a "$LOG"

IDEA1='Build a PHP movie watchlist app using the PHP framework via `podium new movie-watchlist --framework php --no-github`. Users add movies with title, director, genre (action/comedy/drama/sci-fi/horror/other), release year, and a poster URL. Mark movies as watched or want-to-watch. Rate watched movies 1-5 stars with a short review. Homepage shows a filterable list by genre and watch status. Stats bar at top: total movies, watched count, average rating. Use MySQL/MariaDB. Seed with 12 diverse sample movies across genres, half of them watched and rated.'"$SUMMARY_SUFFIX"

IDEA2='Build a Django team standup board using `podium new standup-board --framework django --no-github`. Team members (stored in DB with name and a colour like "blue" or "green") post daily updates with three fields: Yesterday (what they did), Today (what they plan), Blockers (impediments or "None"). Homepage shows today'\''s standups as cards sorted by member name. Archive endpoint lists past standups grouped by date. Use MySQL/MariaDB. Seed with 4 team members and 5 days of past standup posts.'"$SUMMARY_SUFFIX"

IDEA3='Build a Fastify fitness log using `podium new fitness-log --framework fastify --no-github`. Users log workouts: exercise name, category (strength/cardio/flexibility), sets, reps, weight_lbs, and date. Auto-track personal records (PR) per exercise — flag when a new weight PR is set. Weekly summary endpoint shows total workouts, total volume (sets×reps×weight), breakdown by category. Use MySQL/MariaDB. Seed with 6 exercises and 14 days of logged workouts, including a couple of PRs.'"$SUMMARY_SUFFIX"

IDEA4='Build a NestJS flashcard study app using `podium new flashcards --framework nestjs --no-github`. Users create decks (name, description). Each deck has cards with a front (question) and back (answer). Study mode returns cards one at a time; users POST a result of "got_it" or "still_learning" per card. Deck stats endpoint returns: total cards, mastered count, last_studied date. Use MySQL/MariaDB. Seed with 3 decks: "World Capitals" (15 cards), "Programming Concepts" (10 cards), "Spanish Vocabulary" (12 cards).'"$SUMMARY_SUFFIX"

run_project "movie-watchlist"  "$IDEA1" &
run_project "standup-board"    "$IDEA2" &
run_project "fitness-log"      "$IDEA3" &
run_project "flashcards"       "$IDEA4" &

wait

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
