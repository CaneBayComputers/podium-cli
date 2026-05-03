#!/bin/bash -l
# OSS project tests — cassie, agent: gemini

# Load NVM so gemini is on PATH before ai-set runs
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.nvm/versions/node/v24.15.0/bin:$PATH"

mkdir -p /tmp/podium-tests/oss-sessions
LOG=/tmp/podium-tests/oss-master.log
PODIUM="/usr/local/bin/podium"

# Switch to gemini
$PODIUM ai-set --agent gemini
echo "AI agent set to: $(grep '^AI_AGENT=' /etc/podium-cli/.env)"

run_project() {
    local name="$1"
    local idea="$2"
    local logfile="/tmp/podium-tests/oss-sessions/${name}.log"

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

echo "=== OSS Project Tests (cassie / gemini) — $(date) ===" | tee "$LOG"
echo "Agent: $(grep '^AI_AGENT=' /etc/podium-cli/.env)" | tee -a "$LOG"
echo "" | tee -a "$LOG"

IDEA_STIRLING='Deploy Stirling PDF on this Podium server. The project name is stirling-pdf — use this exact name, no changes.

Stirling PDF is a web-based PDF tool (image: frooodle/s-pdf:latest). It listens on port 8080. Use an nginx reverse proxy. No database needed.

Steps:
1. mkdir -p ~/podium-projects/stirling-pdf
2. Write docker-compose.yaml: stirling-pdf-app service (env: DOCKER_ENABLE_SECURITY=false, SECURITY_ENABLE_LOGIN=false; optional volume for tessdata) + nginx (container_name=stirling-pdf, static VPC IP). Write nginx.conf proxying to stirling-pdf-app:8080 with client_max_body_size 100M.
3. cd ~/podium-projects/stirling-pdf && podium setup stirling-pdf --no-startup && podium up stirling-pdf
4. curl -sI http://stirling-pdf/ — expect 200.'"$SUMMARY_SUFFIX"

IDEA_ITTOOLS='Deploy IT Tools on this Podium server. The project name is it-tools — use this exact name, no changes.

IT Tools is a collection of web-based utilities (image: corentinth/it-tools:latest). It serves on port 80 directly — no nginx proxy, no database, no configuration needed. This is the simplest possible deployment.

Steps:
1. mkdir -p ~/podium-projects/it-tools
2. Write docker-compose.yaml: single service, container_name=it-tools, static VPC IP.
3. cd ~/podium-projects/it-tools && podium setup it-tools --no-startup && podium up it-tools
4. curl -sI http://it-tools/ — expect 200.'"$SUMMARY_SUFFIX"

IDEA_CHANGEDETECTION='Deploy Changedetection.io on this Podium server. The project name is changedetection — use this exact name, no changes.

Changedetection.io monitors websites for changes (image: ghcr.io/dgtlmoon/changedetection.io:latest). It listens on port 5000. Use an nginx reverse proxy. No database needed — stores data in /datastore.

Steps:
1. mkdir -p ~/podium-projects/changedetection
2. Write docker-compose.yaml: changedetection-app service (env: BASE_URL=http://changedetection; persist /datastore with a named volume) + nginx (container_name=changedetection, static VPC IP). Write nginx.conf proxying to changedetection-app:5000 (include WebSocket upgrade headers).
3. cd ~/podium-projects/changedetection && podium setup changedetection --no-startup && podium up changedetection
4. curl -sI http://changedetection/ — expect 200.'"$SUMMARY_SUFFIX"

IDEA_FLAME='Deploy Flame on this Podium server. The project name is flame — use this exact name, no changes.

Flame is a self-hosted startpage/dashboard (image: pawelmalak/flame:latest). It listens on port 5005. Use an nginx reverse proxy. No database needed — uses SQLite at /app/data.

Steps:
1. mkdir -p ~/podium-projects/flame
2. Write docker-compose.yaml: flame-app service (env: PASSWORD=admin; persist /app/data) + nginx (container_name=flame, static VPC IP). Write nginx.conf proxying to flame-app:5005.
3. cd ~/podium-projects/flame && podium setup flame --no-startup && podium up flame
4. curl -sI http://flame/ — expect 200. Password: admin.'"$SUMMARY_SUFFIX"

IDEA_HEIMDALL='Deploy Heimdall on this Podium server. The project name is heimdall — use this exact name, no changes.

Heimdall is an application dashboard (image: lscr.io/linuxserver/heimdall:latest). It serves on port 80 directly — no nginx proxy needed. Uses SQLite — no database needed.

Steps:
1. mkdir -p ~/podium-projects/heimdall
2. Write docker-compose.yaml: single service, container_name=heimdall, static VPC IP, env: PUID=1000, PGID=1000, TZ=UTC. Persist /config with a named volume.
3. cd ~/podium-projects/heimdall && podium setup heimdall --no-startup && podium up heimdall
4. curl -sI http://heimdall/ — expect 200.'"$SUMMARY_SUFFIX"

IDEA_UMAMI='Deploy Umami on this Podium server. The project name is umami — use this exact name, no changes.

Umami is a privacy-focused analytics platform (image: ghcr.io/umami-software/umami:postgresql-latest). It listens on port 3000. Use an nginx reverse proxy. IMPORTANT: Umami supports PostgreSQL ONLY. Use the shared podium-postgres (host=podium-postgres, port=5432, user=root, password=password).

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE umami;"
2. mkdir -p ~/podium-projects/umami
3. Write docker-compose.yaml: umami-app service (env: DATABASE_URL=postgresql://root:password@podium-postgres:5432/umami, APP_SECRET=any-random-32-char-string) + nginx (container_name=umami, static VPC IP). Write nginx.conf proxying to umami-app:3000.
4. cd ~/podium-projects/umami && podium setup umami --no-startup && podium up umami
5. curl -sI http://umami/ — expect 200. Default: admin/umami.'"$SUMMARY_SUFFIX"

IDEA_DASHY='Deploy Dashy on this Podium server. The project name is dashy — use this exact name, no changes.

Dashy is a self-hosted dashboard (image: lissy93/dashy:latest). It listens on port 8080. Use an nginx reverse proxy. No database needed.

Steps:
1. mkdir -p ~/podium-projects/dashy
2. Write docker-compose.yaml: dashy-app service (env: NODE_ENV=production; persist /app/user-data) + nginx (container_name=dashy, static VPC IP). Write nginx.conf proxying to dashy-app:8080.
3. cd ~/podium-projects/dashy && podium setup dashy --no-startup && podium up dashy
4. curl -sI http://dashy/ — expect 200.'"$SUMMARY_SUFFIX"

IDEA_LIMESURVEY='Deploy LimeSurvey on this Podium server. The project name is limesurvey — use this exact name, no changes.

LimeSurvey is an online survey platform (image: martialblog/limesurvey:latest). It listens on port 8080. Use an nginx reverse proxy. IMPORTANT: LimeSurvey rejects an empty DB password — create a dedicated user first.

Steps:
1. Create DB user: docker exec podium-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS limesurvey; CREATE USER IF NOT EXISTS '"'"'limesurvey'"'"'@'"'"'%'"'"' IDENTIFIED BY '"'"'limesurvey'"'"'; GRANT ALL PRIVILEGES ON limesurvey.* TO '"'"'limesurvey'"'"'@'"'"'%'"'"'; FLUSH PRIVILEGES;"
2. mkdir -p ~/podium-projects/limesurvey
3. Write docker-compose.yaml: limesurvey-app service (env: DB_TYPE=mysql, DB_HOST=podium-mariadb, DB_PORT=3306, DB_NAME=limesurvey, DB_USERNAME=limesurvey, DB_PASSWORD=limesurvey, ADMIN_USER=admin, ADMIN_NAME=Administrator, ADMIN_EMAIL=admin@example.com, ADMIN_PASSWORD=admin123, PUBLIC_URL=http://limesurvey; persist /var/www/html/upload) + nginx (container_name=limesurvey, static VPC IP). Write nginx.conf proxying to limesurvey-app:8080.
4. cd ~/podium-projects/limesurvey && podium setup limesurvey --no-startup && podium up limesurvey
5. curl -sI http://limesurvey/ — expect 200 or 302. Credentials: admin/admin123.'"$SUMMARY_SUFFIX"

run_project "stirling-pdf"    "$IDEA_STIRLING" &
run_project "it-tools"        "$IDEA_ITTOOLS" &
run_project "changedetection" "$IDEA_CHANGEDETECTION" &
run_project "flame"           "$IDEA_FLAME" &
run_project "heimdall"        "$IDEA_HEIMDALL" &
run_project "umami"           "$IDEA_UMAMI" &
run_project "dashy"           "$IDEA_DASHY" &
run_project "limesurvey"      "$IDEA_LIMESURVEY" &

wait

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
