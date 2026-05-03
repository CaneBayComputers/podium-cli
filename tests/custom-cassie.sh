#!/bin/bash -l
# Custom project tests — cassie, agent: gemini

# Load NVM so gemini is on PATH before ai-set runs
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.nvm/versions/node/v24.15.0/bin:$PATH"

mkdir -p /tmp/podium-tests/custom-sessions
LOG=/tmp/podium-tests/custom-master.log
PODIUM="/usr/local/bin/podium"

# Switch to gemini
$PODIUM ai-set --agent gemini
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

echo "=== Custom Project Tests (cassie / gemini) — $(date) ===" | tee "$LOG"
echo "" | tee -a "$LOG"

IDEA1='Build a Python book club manager using `podium new book-club --framework python --no-github`. Track books: title, author, genre (fiction/non-fiction/sci-fi/mystery/biography/other), page_count, date_read_by_club, group_rating (1-5), and a short group_verdict text. Add discussion_notes per book: date and note_text. Reading stats page returns JSON with: books per month (last 6 months), most common genre, average group rating, total pages read, and top-rated book. Use MySQL/MariaDB. Seed with 8 books across genres and their discussion notes.'"$SUMMARY_SUFFIX"

IDEA2='Build a Django household budget tracker using `podium new budget-tracker --framework django --no-github`. Track income and expenses: amount, type (income/expense), category (housing/food/transport/entertainment/utilities/health/other), date, description. Monthly budget limits are set per category. A monthly summary endpoint returns: total income, total expenses, spending by category as a percentage of its budget limit, and whether the month is under or over budget overall. Use MySQL/MariaDB. Seed with monthly budget limits and 3 months of realistic transactions.'"$SUMMARY_SUFFIX"

IDEA3='Build a Laravel restaurant reviewer using `podium new restaurant-reviews --framework laravel --no-github`. Restaurants: name, cuisine (Italian/Japanese/Mexican/American/Thai/Indian/other), neighborhood, price_range (1-3 representing $/$$/$$$), phone, website. Reviews: restaurant_id, reviewer_name, rating (1-5), visit_date, dish_ordered, review_text. Homepage lists restaurants sorted by average rating with review count. Detail page shows all reviews for a restaurant. Filter by cuisine or price range. Use MySQL/MariaDB. Seed with 8 restaurants and 3+ reviews each.'"$SUMMARY_SUFFIX"

IDEA4='Build a WordPress events board. Install WordPress using `podium new events-board --framework wordpress --no-github`. After setup, use WP-CLI (`podium wp`) to: register a custom post type "event" with meta fields for event_date, location, category (music/sports/food/arts/community), organizer, and is_free (yes/no). Create a page template that lists upcoming events sorted by date with category filter. Use `podium wp post create` to seed 10 upcoming events across all categories with realistic titles, descriptions, and dates in the next 60 days.'"$SUMMARY_SUFFIX"

run_project "book-club"           "$IDEA1" &
run_project "budget-tracker"      "$IDEA2" &
run_project "restaurant-reviews"  "$IDEA3" &
run_project "events-board"        "$IDEA4" &

wait

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
