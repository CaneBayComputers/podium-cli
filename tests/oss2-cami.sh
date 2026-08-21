#!/bin/bash -l
# OSS batch 2 — cami, agent: codex

# Load NVM so codex is on PATH before ai-set runs
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.nvm/versions/node/v24.15.0/bin:$PATH"

mkdir -p /tmp/zeltro-tests/oss2-sessions
LOG=/tmp/zeltro-tests/oss2-master.log
ZELTRO="/usr/local/bin/zeltro"

$ZELTRO ai-set --agent codex
echo "AI agent set to: $(grep '^AI_AGENT=' /etc/zeltro-cli/.env)"

run_project() {
    local name="$1"
    local idea="$2"
    local logfile="/tmp/zeltro-tests/oss2-sessions/${name}.log"

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

echo "=== OSS Batch 2 (cami / codex) — $(date) ===" | tee "$LOG"
echo "Agent: $(grep '^AI_AGENT=' /etc/zeltro-cli/.env)" | tee -a "$LOG"
echo "" | tee -a "$LOG"

IDEA_MONICA='Deploy Monica on this Zeltro server. The project name is monica — use this exact name, no changes.

Monica is a personal CRM (image: monica:latest). It listens on port 80 — no nginx proxy needed. Use the shared MariaDB (host=zeltro-mariadb, user=root, password=empty).

Steps:
1. Create DB: docker exec zeltro-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS monica;"
2. Generate APP_KEY: docker run --rm monica php artisan key:generate --show
3. mkdir -p ~/zeltro-projects/monica
4. Write docker-compose.yaml: single service, container_name=monica, static VPC IP. Env: APP_ENV=production, APP_KEY=<generated>, APP_URL=http://monica, DB_HOST=zeltro-mariadb, DB_DATABASE=monica, DB_USERNAME=root, DB_PASSWORD=. Persist /var/www/html/storage.
5. cd ~/zeltro-projects/monica && zeltro setup monica --no-startup && zeltro up monica
6. Wait 30s for migrations, then curl -sI http://monica/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_LISTMONK='Deploy Listmonk on this Zeltro server. The project name is listmonk — use this exact name, no changes.

Listmonk is a self-hosted newsletter manager (image: listmonk/listmonk:latest). It listens on port 9000. Use an nginx reverse proxy. Use PostgreSQL (host=zeltro-postgres, port=5432, user=root, password=password).

Steps:
1. Create DB: docker exec zeltro-postgres psql -U root -d postgres -c "CREATE DATABASE listmonk;"
2. mkdir -p ~/zeltro-projects/listmonk
3. Write docker-compose.yaml: listmonk-app service (env: LISTMONK_db__host=zeltro-postgres, LISTMONK_db__port=5432, LISTMONK_db__user=root, LISTMONK_db__password=password, LISTMONK_db__database=listmonk) + nginx (container_name=listmonk, static VPC IP). Write nginx.conf proxying to listmonk-app:9000.
4. cd ~/zeltro-projects/listmonk && zeltro setup listmonk --no-startup && zeltro up listmonk
5. Wait 15s, then curl -sI http://listmonk/ — expect 200 or 302. Default: admin/listmonk.'"$SUMMARY_SUFFIX"

IDEA_HEDGEDOC='Deploy HedgeDoc on this Zeltro server. The project name is hedgedoc — use this exact name, no changes.

HedgeDoc is a collaborative markdown editor (image: quay.io/hedgedoc/hedgedoc:latest). It listens on port 3000. Use an nginx reverse proxy. Use PostgreSQL (host=zeltro-postgres, port=5432, user=root, password=password).

Steps:
1. Create DB: docker exec zeltro-postgres psql -U root -d postgres -c "CREATE DATABASE hedgedoc;"
2. mkdir -p ~/zeltro-projects/hedgedoc
3. Write docker-compose.yaml: hedgedoc-app service (env: CMD_DB_URL=postgres://root:password@zeltro-postgres:5432/hedgedoc, CMD_DOMAIN=hedgedoc, CMD_URL_ADDPORT=false, CMD_PROTOCOL_USESSL=false, CMD_SESSION_SECRET=any-random-string; persist /hedgedoc/public/uploads) + nginx (container_name=hedgedoc, static VPC IP). Write nginx.conf proxying to hedgedoc-app:3000 (include WebSocket headers).
4. cd ~/zeltro-projects/hedgedoc && zeltro setup hedgedoc --no-startup && zeltro up hedgedoc
5. curl -sI http://hedgedoc/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_LINKWARDEN='Deploy Linkwarden on this Zeltro server. The project name is linkwarden — use this exact name, no changes.

Linkwarden is a bookmark manager (image: ghcr.io/linkwarden/linkwarden:latest). It listens on port 3000. Use an nginx reverse proxy. Use PostgreSQL (host=zeltro-postgres, port=5432, user=root, password=password).

Steps:
1. Create DB: docker exec zeltro-postgres psql -U root -d postgres -c "CREATE DATABASE linkwarden;"
2. mkdir -p ~/zeltro-projects/linkwarden
3. Write docker-compose.yaml: linkwarden-app service (env: DATABASE_URL=postgresql://root:password@zeltro-postgres:5432/linkwarden, NEXTAUTH_SECRET=any-random-32-char-string, NEXTAUTH_URL=http://linkwarden, NEXT_PUBLIC_DISABLE_REGISTRATION=false; persist /data/data) + nginx (container_name=linkwarden, static VPC IP). Write nginx.conf proxying to linkwarden-app:3000.
4. cd ~/zeltro-projects/linkwarden && zeltro setup linkwarden --no-startup && zeltro up linkwarden
5. curl -sI http://linkwarden/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_TANDOOR='Deploy Tandoor Recipes on this Zeltro server. The project name is tandoor — use this exact name, no changes.

Tandoor is a recipe manager (image: vabene1111/recipes:latest). It listens on port 8080. Use an nginx reverse proxy. Use PostgreSQL (host=zeltro-postgres, port=5432, user=root, password=password).

Steps:
1. Create DB: docker exec zeltro-postgres psql -U root -d postgres -c "CREATE DATABASE tandoor;"
2. mkdir -p ~/zeltro-projects/tandoor
3. Write docker-compose.yaml: tandoor-app service (env: DB_ENGINE=django.db.backends.postgresql, POSTGRES_HOST=zeltro-postgres, POSTGRES_PORT=5432, POSTGRES_USER=root, POSTGRES_PASSWORD=password, POSTGRES_DB=tandoor, SECRET_KEY=any-50-char-random-string, ALLOWED_HOSTS=*, CSRF_TRUSTED_ORIGINS=http://tandoor; persist /opt/recipes/mediafiles and /opt/recipes/staticfiles) + nginx (container_name=tandoor, static VPC IP). Write nginx.conf proxying to tandoor-app:8080.
4. cd ~/zeltro-projects/tandoor && zeltro setup tandoor --no-startup && zeltro up tandoor
5. curl -sI http://tandoor/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_N8N='Deploy n8n on this Zeltro server. The project name is n8n — use this exact name, no changes.

n8n is a workflow automation platform (image: n8nio/n8n:latest). It listens on port 5678. Use an nginx reverse proxy. No database needed by default — uses SQLite.

Steps:
1. mkdir -p ~/zeltro-projects/n8n
2. Write docker-compose.yaml: n8n-app service (env: N8N_HOST=n8n, N8N_PORT=5678, N8N_PROTOCOL=http, WEBHOOK_URL=http://n8n/; persist /home/node/.n8n) + nginx (container_name=n8n, static VPC IP). Write nginx.conf proxying to n8n-app:5678 (include WebSocket upgrade headers).
3. cd ~/zeltro-projects/n8n && zeltro setup n8n --no-startup && zeltro up n8n
4. curl -sI http://n8n/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_ACTUALBUDGET='Deploy Actual Budget on this Zeltro server. The project name is actual-budget — use this exact name, no changes.

Actual Budget is a local-first personal finance tool (image: actualbudget/actual-server:latest). It listens on port 5006. Use an nginx reverse proxy. No database needed — uses its own file storage.

Steps:
1. mkdir -p ~/zeltro-projects/actual-budget
2. Write docker-compose.yaml: actual-budget-app service (persist /data) + nginx (container_name=actual-budget, static VPC IP). Write nginx.conf proxying to actual-budget-app:5006.
3. cd ~/zeltro-projects/actual-budget && zeltro setup actual-budget --no-startup && zeltro up actual-budget
4. curl -sI http://actual-budget/ — expect 200.'"$SUMMARY_SUFFIX"

IDEA_NEXTCLOUD='Deploy Nextcloud on this Zeltro server. The project name is nextcloud — use this exact name, no changes.

Nextcloud is a file hosting platform (image: nextcloud:latest). It listens on port 80 — no nginx proxy needed. Use the shared MariaDB (host=zeltro-mariadb, user=root, password=empty).

Steps:
1. Create DB: docker exec zeltro-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS nextcloud;"
2. mkdir -p ~/zeltro-projects/nextcloud
3. Write docker-compose.yaml: single service, container_name=nextcloud, static VPC IP. Env: MYSQL_HOST=zeltro-mariadb, MYSQL_DATABASE=nextcloud, MYSQL_USER=root, MYSQL_PASSWORD=, NEXTCLOUD_TRUSTED_DOMAINS=nextcloud. Persist /var/www/html with a named volume.
4. cd ~/zeltro-projects/nextcloud && zeltro setup nextcloud --no-startup && zeltro up nextcloud
5. curl -sI http://nextcloud/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

run_project "monica"        "$IDEA_MONICA" &
run_project "listmonk"      "$IDEA_LISTMONK" &
run_project "hedgedoc"      "$IDEA_HEDGEDOC" &
run_project "linkwarden"    "$IDEA_LINKWARDEN" &
run_project "tandoor"       "$IDEA_TANDOOR" &
run_project "n8n"           "$IDEA_N8N" &
run_project "actual-budget" "$IDEA_ACTUALBUDGET" &
run_project "nextcloud"     "$IDEA_NEXTCLOUD" &

wait

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
