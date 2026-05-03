#!/bin/bash -l
# OSS batch 2 — dingdong, agent: codex

# Load NVM so codex is on PATH before ai-set runs
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.nvm/versions/node/v24.15.0/bin:$PATH"

mkdir -p /tmp/podium-tests/oss2-sessions
LOG=/tmp/podium-tests/oss2-master.log
PODIUM="/usr/local/bin/podium"

$PODIUM ai-set --agent codex
echo "AI agent set to: $(grep '^AI_AGENT=' /etc/podium-cli/.env)"

run_project() {
    local name="$1"
    local idea="$2"
    local logfile="/tmp/podium-tests/oss2-sessions/${name}.log"

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

echo "=== OSS Batch 2 (dingdong / codex) — $(date) ===" | tee "$LOG"
echo "Agent: $(grep '^AI_AGENT=' /etc/podium-cli/.env)" | tee -a "$LOG"
echo "" | tee -a "$LOG"

IDEA_GITEA='Deploy Gitea on this Podium server. The project name is gitea — use this exact name, no changes.

Gitea is a lightweight self-hosted Git service (image: gitea/gitea:latest). It listens on port 3000. Use an nginx reverse proxy. Use the shared MariaDB (host=podium-mariadb, user=root, password=empty).

Steps:
1. mkdir -p ~/podium-projects/gitea
2. Write docker-compose.yaml: gitea-app service (env: GITEA__database__DB_TYPE=mysql, GITEA__database__HOST=podium-mariadb:3306, GITEA__database__NAME=gitea, GITEA__database__USER=root, GITEA__database__PASSWD=, GITEA__server__ROOT_URL=http://gitea/, GITEA__server__HTTP_PORT=3000; persist /data) + nginx (container_name=gitea, static VPC IP). Write nginx.conf proxying to gitea-app:3000.
3. Create DB: docker exec podium-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS gitea;"
4. cd ~/podium-projects/gitea && podium setup gitea --no-startup && podium up gitea
5. curl -sI http://gitea/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_WIKIJS='Deploy Wiki.js on this Podium server. The project name is wikijs — use this exact name, no changes.

Wiki.js is a modern wiki platform (image: ghcr.io/requarks/wiki:2). It listens on port 3000. Use an nginx reverse proxy. Use PostgreSQL (host=podium-postgres, port=5432, user=root, password=password).

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE wikijs;"
2. mkdir -p ~/podium-projects/wikijs
3. Write docker-compose.yaml: wikijs-app service (env: DB_TYPE=postgres, DB_HOST=podium-postgres, DB_PORT=5432, DB_USER=root, DB_PASS=password, DB_NAME=wikijs) + nginx (container_name=wikijs, static VPC IP). Write nginx.conf proxying to wikijs-app:3000.
4. cd ~/podium-projects/wikijs && podium setup wikijs --no-startup && podium up wikijs
5. curl -sI http://wikijs/ — expect 200.'"$SUMMARY_SUFFIX"

IDEA_JELLYFIN='Deploy Jellyfin on this Podium server. The project name is jellyfin — use this exact name, no changes.

Jellyfin is a media server (image: jellyfin/jellyfin:latest). It listens on port 8096. Use an nginx reverse proxy. No database needed.

Steps:
1. mkdir -p ~/podium-projects/jellyfin
2. Write docker-compose.yaml: jellyfin-app service (persist /config and /cache with named volumes) + nginx (container_name=jellyfin, static VPC IP). Write nginx.conf proxying to jellyfin-app:8096.
3. cd ~/podium-projects/jellyfin && podium setup jellyfin --no-startup && podium up jellyfin
4. curl -sI http://jellyfin/ — expect 200.'"$SUMMARY_SUFFIX"

IDEA_PAPERLESS='Deploy Paperless-ngx on this Podium server. The project name is paperless — use this exact name, no changes.

Paperless-ngx is a document management system (image: ghcr.io/paperless-ngx/paperless-ngx:latest). It listens on port 8000. Use an nginx reverse proxy. Use PostgreSQL (host=podium-postgres, port=5432, user=root, password=password). Also needs Redis (host=podium-redis).

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE paperless;"
2. mkdir -p ~/podium-projects/paperless
3. Write docker-compose.yaml: paperless-app service (env: PAPERLESS_DBHOST=podium-postgres, PAPERLESS_DBPORT=5432, PAPERLESS_DBUSER=root, PAPERLESS_DBPASS=password, PAPERLESS_DBNAME=paperless, PAPERLESS_REDIS=redis://podium-redis:6379, PAPERLESS_SECRET_KEY=any-random-50-char-string, PAPERLESS_URL=http://paperless; persist /usr/src/paperless/data, /usr/src/paperless/media, /usr/src/paperless/export, /usr/src/paperless/consume) + nginx (container_name=paperless, static VPC IP). Write nginx.conf proxying to paperless-app:8000.
4. cd ~/podium-projects/paperless && podium setup paperless --no-startup && podium up paperless
5. curl -sI http://paperless/ — expect 200 or 302. Default: admin/admin.'"$SUMMARY_SUFFIX"

IDEA_UPTIMEKUMA='Deploy Uptime Kuma on this Podium server. The project name is uptime-kuma — use this exact name, no changes.

Uptime Kuma is a self-hosted monitoring tool (image: louislam/uptime-kuma:1). It listens on port 3001. Use an nginx reverse proxy. No database needed — uses SQLite.

Steps:
1. mkdir -p ~/podium-projects/uptime-kuma
2. Write docker-compose.yaml: uptime-kuma-app service (persist /app/data) + nginx (container_name=uptime-kuma, static VPC IP). Write nginx.conf proxying to uptime-kuma-app:3001 (include WebSocket upgrade headers).
3. cd ~/podium-projects/uptime-kuma && podium setup uptime-kuma --no-startup && podium up uptime-kuma
4. curl -sI http://uptime-kuma/ — expect 200.'"$SUMMARY_SUFFIX"

IDEA_GHOST='Deploy Ghost on this Podium server. The project name is ghost — use this exact name, no changes.

Ghost is a blogging platform (image: ghost:latest). It listens on port 2368. Use an nginx reverse proxy. Use the shared MariaDB (host=podium-mariadb, user=root, password=empty).

Steps:
1. mkdir -p ~/podium-projects/ghost
2. Write docker-compose.yaml: ghost-app service (env: database__client=mysql, database__connection__host=podium-mariadb, database__connection__port=3306, database__connection__user=root, database__connection__password=, database__connection__database=ghost, url=http://ghost; persist /var/lib/ghost/content) + nginx (container_name=ghost, static VPC IP). Write nginx.conf proxying to ghost-app:2368.
3. cd ~/podium-projects/ghost && podium setup ghost --no-startup && podium up ghost
4. curl -sI http://ghost/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_BOOKSTACK='Deploy BookStack on this Podium server. The project name is bookstack — use this exact name, no changes.

BookStack is a wiki/documentation platform (image: lscr.io/linuxserver/bookstack:latest). It listens on port 80 — no nginx proxy needed. Use the shared MariaDB (host=podium-mariadb, user=root, password=empty).

Steps:
1. Create DB: docker exec podium-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS bookstack;"
2. mkdir -p ~/podium-projects/bookstack
3. Write docker-compose.yaml: single service, container_name=bookstack, static VPC IP. Env: PUID=1000, PGID=1000, TZ=UTC, APP_URL=http://bookstack, DB_HOST=podium-mariadb, DB_PORT=3306, DB_USER=root, DB_PASS=, DB_DATABASE=bookstack. Persist /config with a named volume.
4. cd ~/podium-projects/bookstack && podium setup bookstack --no-startup && podium up bookstack
5. curl -sI http://bookstack/ — expect 200 or 302. Default: admin@admin.com / password.'"$SUMMARY_SUFFIX"

IDEA_HOMER='Deploy Homer on this Podium server. The project name is homer — use this exact name, no changes.

Homer is a static application dashboard (image: b4bz/homer:latest). It listens on port 8080. Use an nginx reverse proxy. No database needed.

Steps:
1. mkdir -p ~/podium-projects/homer
2. Write docker-compose.yaml: homer-app service (env: INIT_ASSETS=1; persist /www/assets) + nginx (container_name=homer, static VPC IP). Write nginx.conf proxying to homer-app:8080.
3. cd ~/podium-projects/homer && podium setup homer --no-startup && podium up homer
4. curl -sI http://homer/ — expect 200.'"$SUMMARY_SUFFIX"

run_project "gitea"       "$IDEA_GITEA" &
run_project "wikijs"      "$IDEA_WIKIJS" &
run_project "jellyfin"    "$IDEA_JELLYFIN" &
run_project "paperless"   "$IDEA_PAPERLESS" &
run_project "uptime-kuma" "$IDEA_UPTIMEKUMA" &
run_project "ghost"       "$IDEA_GHOST" &
run_project "bookstack"   "$IDEA_BOOKSTACK" &
run_project "homer"       "$IDEA_HOMER" &

wait

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
