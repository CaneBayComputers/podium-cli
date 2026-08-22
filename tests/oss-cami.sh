#!/bin/bash -l
# OSS project tests — cami, agent: codex

# Load NVM so codex/npm are on PATH before ai-set runs
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.nvm/versions/node/v24.15.0/bin:$PATH"

mkdir -p /tmp/zeltro-tests/oss-sessions
LOG=/tmp/zeltro-tests/oss-master.log
ZELTRO="/usr/local/bin/zeltro"

# Switch to codex
$ZELTRO ai-set --agent codex
echo "AI agent set to: $(grep '^AI_AGENT=' /etc/zeltro-cli/.env)"

run_project() {
    local name="$1"
    local idea="$2"
    local logfile="/tmp/zeltro-tests/oss-sessions/${name}.log"

    echo "[$(date '+%H:%M:%S')] === Starting: $name ===" | tee -a "$LOG"

    TERM=xterm $ZELTRO remove "$name" --force-db-delete > /dev/null 2>&1 || true

    timeout 2400 bash -l -c "export PATH=\"\$HOME/.nvm/versions/node/v24.15.0/bin:\$PATH\"; TERM=xterm $ZELTRO create --one-off \"$idea\" > \"$logfile\" 2>&1"
    local code=$?
    echo "EXIT:$code" >> "$logfile"

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://${name}/" 2>/dev/null)
    echo "[$(date '+%H:%M:%S')] DONE: $name | exit=$code | HTTP $http_code" | tee -a "$LOG"
}

SUMMARY_SUFFIX='

After the site is verified, create a file called SETUP_SUMMARY.md inside the project directory with exactly these sections:
## Project
[project name and Docker image used]
## Commands Run
[bulleted list of key commands you ran]
## Issues & Fixes
[any problems you hit and how you resolved them, or "None" if it went smoothly]
## Result
HTTP status: [e.g. 200 or 302]
URL: http://[project-name]/
Credentials: [default login/password if any, or "None required"]
## Verdict
[one sentence: did setup go smoothly or were there major problems?]'

echo "=== OSS Project Tests (cami / codex) — $(date) ===" | tee "$LOG"
echo "Agent: $(grep '^AI_AGENT=' /etc/zeltro-cli/.env)" | tee -a "$LOG"
echo "" | tee -a "$LOG"

IDEA_FRESHRSS='Deploy FreshRSS on this Zeltro server. The project name is freshrss — use this exact name, no changes.

FreshRSS is an RSS aggregator (image: freshrss/freshrss:latest). It serves on port 80 directly — no nginx proxy needed. Uses SQLite by default.

Steps:
1. mkdir -p ~/zeltro-projects/freshrss
2. Write docker-compose.yaml: single service, container_name=freshrss, static VPC IP, persist /var/www/FreshRSS/data and /var/www/FreshRSS/extensions with named volumes.
3. cd ~/zeltro-projects/freshrss && zeltro setup freshrss --no-startup && zeltro up freshrss
4. curl -sI http://freshrss/ — expect 200 or 302. Run web installer on first visit.'"$SUMMARY_SUFFIX"

IDEA_MEMOS='Deploy Memos on this Zeltro server. The project name is memos — use this exact name, no changes.

Memos is a lightweight self-hosted memo hub (image: neosmemo/memos:stable). It listens on port 5230. Use an nginx reverse proxy. Uses SQLite — no external database needed.

Steps:
1. mkdir -p ~/zeltro-projects/memos
2. Write docker-compose.yaml: memos-app service (persist /var/opt/memos) + nginx (container_name=memos, static VPC IP). Write nginx.conf proxying to memos-app:5230.
3. cd ~/zeltro-projects/memos && zeltro setup memos --no-startup && zeltro up memos
4. curl -sI http://memos/ — expect 200. First user to register becomes admin.'"$SUMMARY_SUFFIX"

IDEA_GROCY='Deploy Grocy on this Zeltro server. The project name is grocy — use this exact name, no changes.

Grocy is a self-hosted household management ERP (image: lscr.io/linuxserver/grocy:latest). It serves on port 80 directly — no nginx proxy needed. Uses SQLite.

Steps:
1. mkdir -p ~/zeltro-projects/grocy
2. Write docker-compose.yaml: single service, container_name=grocy, static VPC IP, env: PUID=1000, PGID=1000, TZ=UTC. Persist /config with a named volume.
3. cd ~/zeltro-projects/grocy && zeltro setup grocy --no-startup && zeltro up grocy
4. curl -sI http://grocy/ — expect 200. Default login: admin/admin.'"$SUMMARY_SUFFIX"

IDEA_SNIPEIT='Deploy Snipe-IT on this Zeltro server. The project name is snipe-it — use this exact name, no changes.

Snipe-IT is an IT asset management system (image: snipe/snipe-it:latest). It serves on port 80 directly. Requires MySQL (use zeltro-mariadb: host=zeltro-mariadb, user=root, password=empty).

CRITICAL: You MUST generate an APP_KEY before starting. Run:
docker run --rm snipe/snipe-it php artisan key:generate --show
Copy the output and set it as APP_KEY in docker-compose.yaml.

Steps:
1. Create DB: docker exec zeltro-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS snipeit;"
2. Generate APP_KEY as above.
3. mkdir -p ~/zeltro-projects/snipe-it
4. Write docker-compose.yaml: single service, container_name=snipe-it, static VPC IP. Env: APP_KEY=<generated>, APP_URL=http://snipe-it, APP_ENV=production, DB_HOST=zeltro-mariadb, DB_DATABASE=snipeit, DB_USERNAME=root, DB_PASSWORD=, MAIL_DRIVER=log. Persist /var/lib/snipeit.
5. cd ~/zeltro-projects/snipe-it && zeltro setup snipe-it --no-startup && zeltro up snipe-it
6. Wait 60s for migrations, then curl -sI http://snipe-it/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_KIMAI='Deploy Kimai on this Zeltro server. The project name is kimai — use this exact name, no changes.

Kimai is a time-tracking application (image: kimai/kimai2:apache). It listens on port 8001. Use an nginx reverse proxy. Use the shared MariaDB (host=zeltro-mariadb, user=root, password=empty).

Steps:
1. mkdir -p ~/zeltro-projects/kimai
2. Write docker-compose.yaml: kimai-app service (env: APP_ENV=prod, DATABASE_URL=mysql://root:@zeltro-mariadb:3306/kimai, APP_SECRET=any-random-string, ADMINMAIL=admin@example.com, ADMINPASS=admin123, TRUSTED_HOSTS=kimai; persist /opt/kimai/var) + nginx (container_name=kimai, static VPC IP). Write nginx.conf proxying to kimai-app:8001.
3. cd ~/zeltro-projects/kimai && zeltro setup kimai --no-startup && zeltro up kimai
4. curl -sI http://kimai/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_REDMINE='Deploy Redmine on this Zeltro server. The project name is redmine — use this exact name, no changes.

Redmine is a project management tool (image: redmine:latest). It listens on port 3000. Use an nginx reverse proxy. Use the shared MariaDB (host=zeltro-mariadb, user=root, password=empty).

Steps:
1. Create DB: docker exec zeltro-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS redmine CHARACTER SET utf8mb4;"
2. mkdir -p ~/zeltro-projects/redmine
3. Write docker-compose.yaml: redmine-app service (env: REDMINE_DB_MYSQL=zeltro-mariadb, REDMINE_DB_USERNAME=root, REDMINE_DB_PASSWORD=, REDMINE_DB_DATABASE=redmine, REDMINE_SECRET_KEY_BASE=any-long-random-string; persist /usr/src/redmine/files) + nginx (container_name=redmine, static VPC IP). Write nginx.conf proxying to redmine-app:3000.
4. cd ~/zeltro-projects/redmine && zeltro setup redmine --no-startup && zeltro up redmine
5. Wait 60s for initial migrations, then curl -sI http://redmine/ — expect 200. Default: admin/admin.'"$SUMMARY_SUFFIX"

IDEA_LYCHEE='Deploy Lychee on this Zeltro server. The project name is lychee — use this exact name, no changes.

Lychee is a photo management system (image: lycheeorg/lychee:latest). It serves on port 80 directly. Use the shared MariaDB (host=zeltro-mariadb, user=root, password=empty).

Steps:
1. mkdir -p ~/zeltro-projects/lychee
2. Write docker-compose.yaml: single service, container_name=lychee, static VPC IP. Env: DB_CONNECTION=mysql, DB_HOST=zeltro-mariadb, DB_PORT=3306, DB_DATABASE=lychee, DB_USERNAME=root, DB_PASSWORD=, APP_URL=http://lychee, TIMEZONE=UTC. Persist /var/www/html/public/uploads.
3. cd ~/zeltro-projects/lychee && zeltro setup lychee --no-startup && zeltro up lychee
4. curl -sI http://lychee/ — expect 200 or 302. Setup wizard on first visit.'"$SUMMARY_SUFFIX"

IDEA_WALLABAG='Deploy Wallabag on this Zeltro server. The project name is wallabag — use this exact name, no changes.

Wallabag is a read-it-later application (image: wallabag/wallabag:latest). It serves on port 80 directly. Use the shared MariaDB (host=zeltro-mariadb, user=root, password=empty).

Steps:
1. mkdir -p ~/zeltro-projects/wallabag
2. Write docker-compose.yaml: single service, container_name=wallabag, static VPC IP. Env: SYMFONY__ENV__DATABASE_DRIVER=pdo_mysql, SYMFONY__ENV__DATABASE_HOST=zeltro-mariadb, SYMFONY__ENV__DATABASE_PORT=3306, SYMFONY__ENV__DATABASE_NAME=wallabag, SYMFONY__ENV__DATABASE_USER=root, SYMFONY__ENV__DATABASE_PASSWORD=, SYMFONY__ENV__DOMAIN_NAME=http://wallabag, POPULATE_DATABASE=true. Persist /var/www/wallabag/web/assets/images.
3. cd ~/zeltro-projects/wallabag && zeltro setup wallabag --no-startup && zeltro up wallabag
4. Wait 30s, then curl -sI http://wallabag/ — expect 200 or 302. Default: wallabag/wallabag.'"$SUMMARY_SUFFIX"

run_project "freshrss"  "$IDEA_FRESHRSS" &
run_project "memos"     "$IDEA_MEMOS" &
run_project "grocy"     "$IDEA_GROCY" &
run_project "snipe-it"  "$IDEA_SNIPEIT" &
run_project "kimai"     "$IDEA_KIMAI" &
run_project "redmine"   "$IDEA_REDMINE" &
run_project "lychee"    "$IDEA_LYCHEE" &
run_project "wallabag"  "$IDEA_WALLABAG" &

wait

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
