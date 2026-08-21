#!/bin/bash -l
# OSS batch 4 — cami, agent: codex

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.nvm/versions/node/v24.15.0/bin:$PATH"

mkdir -p /tmp/zeltro-tests/oss4-sessions
LOG=/tmp/zeltro-tests/oss4-master.log
ZELTRO="/usr/local/bin/zeltro"

run_project() {
    local name="$1"
    local idea="$2"
    local logfile="/tmp/zeltro-tests/oss4-sessions/${name}.log"

    echo "[$(date '+%H:%M:%S')] === Starting: $name ===" | tee -a "$LOG"

    TERM=xterm $ZELTRO remove "$name" --force-db-delete > /dev/null 2>&1 || true

    timeout 2400 bash -l -c "TERM=xterm $ZELTRO create --one-off \"$idea\" > \"$logfile\" 2>&1"
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

echo "=== OSS Batch 4 (cami / codex) — $(date) ===" | tee "$LOG"
echo "" | tee -a "$LOG"

IDEA_APPWRITE='Deploy Appwrite on this Zeltro server. The project name is appwrite — use this exact name, no changes.

Appwrite is a backend-as-a-service platform (image: appwrite/appwrite:1.5.7). It serves on port 80 directly — no nginx proxy needed. Use the shared MariaDB (host=zeltro-mariadb, user=root, password=empty) and shared Redis (host=zeltro-redis, port=6379).

Steps:
1. Create DB: docker exec zeltro-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS appwrite CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
2. mkdir -p ~/zeltro-projects/appwrite
3. Write docker-compose.yaml: single service appwrite-app (image: appwrite/appwrite:1.5.7; env: _APP_ENV=production, _APP_OPENSSL_KEY_V1=$(openssl rand -hex 16), _APP_DOMAIN=appwrite, _APP_DOMAIN_TARGET=appwrite, _APP_DB_HOST=zeltro-mariadb, _APP_DB_PORT=3306, _APP_DB_SCHEMA=appwrite, _APP_DB_USER=root, _APP_DB_PASS=, _APP_REDIS_HOST=zeltro-redis, _APP_REDIS_PORT=6379, _APP_REDIS_USER=, _APP_REDIS_PASS=, _APP_SMTP_HOST=zeltro-mailhog, _APP_SMTP_PORT=1025; volumes: appwrite-uploads:/storage/uploads, appwrite-cache:/storage/cache, appwrite-config:/storage/config, appwrite-certificates:/storage/certificates, appwrite-functions:/storage/functions; container_name=appwrite, static VPC IP).
4. cd ~/zeltro-projects/appwrite && zeltro setup appwrite --no-startup && zeltro up appwrite
5. Wait 60 seconds for initial setup, then curl -sI http://appwrite/ — expect 200 or 302. Visit http://appwrite/ to create the first admin account.'"$SUMMARY_SUFFIX"

IDEA_CALCOM='Deploy Cal.com on this Zeltro server. The project name is cal-com — use this exact name, no changes.

Cal.com is an open-source scheduling platform (image: calcom/cal.com:latest). It listens on port 3000. Use an nginx reverse proxy. Use the shared PostgreSQL (host=zeltro-postgres, port=5432, user=root, password=password).

Steps:
1. Create DB: docker exec zeltro-postgres psql -U root -d postgres -c "CREATE DATABASE calcom;" 2>/dev/null || true
2. mkdir -p ~/zeltro-projects/cal-com
3. Write docker-compose.yaml: cal-com-app service (image: calcom/cal.com:latest; env: DATABASE_URL=postgresql://root:password@zeltro-postgres:5432/calcom, NEXTAUTH_SECRET=$(openssl rand -hex 32), NEXTAUTH_URL=http://cal-com, CALENDSO_ENCRYPTION_KEY=$(openssl rand -hex 16), NEXT_PUBLIC_WEBAPP_URL=http://cal-com, NODE_ENV=production) + nginx service (container_name=cal-com, static VPC IP). Write nginx.conf proxying to cal-com-app:3000.
4. cd ~/zeltro-projects/cal-com && zeltro setup cal-com --no-startup && zeltro up cal-com
5. Wait 60 seconds for migrations and build, then curl -sI http://cal-com/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_STANDARDNOTES='Deploy Standard Notes on this Zeltro server. The project name is standard-notes — use this exact name, no changes.

Standard Notes is an encrypted notes platform (image: standardnotes/server:latest). It listens on port 3000. Use an nginx reverse proxy. Use the shared PostgreSQL (host=zeltro-postgres, port=5432, user=root, password=password) and shared Redis (host=zeltro-redis, port=6379).

Steps:
1. Create DB: docker exec zeltro-postgres psql -U root -d postgres -c "CREATE DATABASE standard_notes;" 2>/dev/null || true
2. mkdir -p ~/zeltro-projects/standard-notes
3. Write docker-compose.yaml: standard-notes-app service (image: standardnotes/server:latest; env: DB_HOST=zeltro-postgres, DB_PORT=5432, DB_DATABASE=standard_notes, DB_USERNAME=root, DB_PASSWORD=password, REDIS_URL=redis://zeltro-redis:6379, AUTH_JWT_SECRET=$(openssl rand -hex 32), SERVER_JWT_SECRET=$(openssl rand -hex 32), VALET_TOKEN_SECRET=$(openssl rand -hex 32), APP_PORT=3000, PUBLIC_FILES_SERVER_URL=http://standard-notes/files; volumes: standard-notes-uploads:/opt/bundled/packages/files/dist/data) + nginx service (container_name=standard-notes, static VPC IP). Write nginx.conf proxying to standard-notes-app:3000.
4. cd ~/zeltro-projects/standard-notes && zeltro setup standard-notes --no-startup && zeltro up standard-notes
5. Wait 30 seconds, then curl -sI http://standard-notes/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_APPSMITH='Deploy Appsmith on this Zeltro server. The project name is appsmith — use this exact name, no changes.

Appsmith is a low-code app builder (image: appsmith/appsmith-ce:latest). It serves on port 80 directly — no nginx proxy needed. This is an all-in-one image that includes MongoDB, Redis, and nginx internally.

Steps:
1. mkdir -p ~/zeltro-projects/appsmith
2. Write docker-compose.yaml: single service appsmith-app (image: appsmith/appsmith-ce:latest; env: APPSMITH_ENCRYPTION_PASSWORD=$(openssl rand -hex 16), APPSMITH_ENCRYPTION_SALT=$(openssl rand -hex 16); volumes: appsmith-stacks:/appsmith-stacks; container_name=appsmith, static VPC IP).
3. cd ~/zeltro-projects/appsmith && zeltro setup appsmith --no-startup && zeltro up appsmith
4. Wait 90 seconds for initial startup (Appsmith takes time on first boot), then curl -sI http://appsmith/ — expect 200 or 302. Visit http://appsmith/ to create the first admin account.'"$SUMMARY_SUFFIX"

IDEA_SNAPPYMAIL='Deploy SnappyMail on this Zeltro server. The project name is snappymail — use this exact name, no changes.

SnappyMail is a modern webmail client (image: djmaze/snappymail:latest). It listens on port 8888. Use an nginx reverse proxy. No external database needed (file-based storage).

Steps:
1. mkdir -p ~/zeltro-projects/snappymail
2. Write docker-compose.yaml: snappymail-app service (image: djmaze/snappymail:latest; env: SNAPPYMAIL_INCLUDE_ADMINPANEL=True; volumes: snappymail-data:/var/lib/snappymail) + nginx service (container_name=snappymail, static VPC IP). Write nginx.conf proxying to snappymail-app:8888.
3. cd ~/zeltro-projects/snappymail && zeltro setup snappymail --no-startup && zeltro up snappymail
4. Wait 10 seconds, then curl -sI http://snappymail/ — expect 200 or 302. Admin panel at http://snappymail/?admin.'"$SUMMARY_SUFFIX"

IDEA_LOCALSTACK='Deploy LocalStack on this Zeltro server. The project name is localstack — use this exact name, no changes.

LocalStack is a local AWS cloud emulator (image: localstack/localstack:latest). It listens on port 4566. Use an nginx reverse proxy. No external database needed.

Steps:
1. mkdir -p ~/zeltro-projects/localstack
2. Write docker-compose.yaml: localstack-app service (image: localstack/localstack:latest; env: SERVICES=s3,sqs,lambda,dynamodb, DEBUG=0, PERSISTENCE=0; volumes: localstack-data:/var/lib/localstack, /var/run/docker.sock:/var/run/docker.sock) + nginx service (container_name=localstack, static VPC IP). Write nginx.conf proxying all traffic to localstack-app:4566.
3. cd ~/zeltro-projects/localstack && zeltro setup localstack --no-startup && zeltro up localstack
4. Wait 15 seconds, then curl -sI http://localstack/ — expect 200 (LocalStack responds on port 4566 root path). Also verify: curl -s http://localstack/_localstack/health | grep running.'"$SUMMARY_SUFFIX"

IDEA_COOLIFY='Deploy Coolify on this Zeltro server. The project name is coolify — use this exact name, no changes.

Coolify is a self-hosted PaaS platform (image: ghcr.io/coollabsio/coolify:latest). It listens on port 8000. Use an nginx reverse proxy. Use the shared PostgreSQL (host=zeltro-postgres, port=5432, user=root, password=password) and shared Redis (host=zeltro-redis, port=6379).

Steps:
1. Create DB: docker exec zeltro-postgres psql -U root -d postgres -c "CREATE DATABASE coolify;" 2>/dev/null || true
2. mkdir -p ~/zeltro-projects/coolify
3. Write docker-compose.yaml: coolify-app service (image: ghcr.io/coollabsio/coolify:latest; env: APP_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || openssl rand -hex 16), APP_KEY=base64:$(openssl rand -base64 32), APP_NAME=Coolify, APP_URL=http://coolify, DB_HOST=zeltro-postgres, DB_PORT=5432, DB_DATABASE=coolify, DB_USERNAME=root, DB_PASSWORD=password, REDIS_HOST=zeltro-redis, REDIS_PORT=6379, QUEUE_CONNECTION=redis; volumes: /var/run/docker.sock:/var/run/docker.sock, coolify-data:/data/coolify) + nginx service (container_name=coolify, static VPC IP). Write nginx.conf proxying to coolify-app:8000.
4. cd ~/zeltro-projects/coolify && zeltro setup coolify --no-startup && zeltro up coolify
5. Wait 30 seconds, then curl -sI http://coolify/ — expect 200 or 302. Visit http://coolify/ to create the first admin account.'"$SUMMARY_SUFFIX"

IDEA_CODESERVER='Deploy Code-Server on this Zeltro server. The project name is code-server — use this exact name, no changes.

Code-Server is VS Code running in a browser (image: codercom/code-server:latest). It listens on port 8080. Use an nginx reverse proxy. No external database needed.

Steps:
1. mkdir -p ~/zeltro-projects/code-server
2. Write docker-compose.yaml: code-server-app service (image: codercom/code-server:latest; env: PASSWORD=codeserver123; volumes: code-server-data:/home/coder/.local/share/code-server, code-server-workspace:/home/coder/project) + nginx service (container_name=code-server, static VPC IP). Write nginx.conf proxying to code-server-app:8080.
3. cd ~/zeltro-projects/code-server && zeltro setup code-server --no-startup && zeltro up code-server
4. Wait 10 seconds, then curl -sI http://code-server/ — expect 200 or 302. Password: codeserver123.'"$SUMMARY_SUFFIX"

IDEA_MATOMO='Deploy Matomo on this Zeltro server. The project name is matomo — use this exact name, no changes.

Matomo is an open-source web analytics platform (image: matomo:apache). It serves on port 80 directly — no nginx proxy needed. Use the shared MariaDB (host=zeltro-mariadb, user=root, password=empty).

Steps:
1. Create DB: docker exec zeltro-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS matomo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
2. mkdir -p ~/zeltro-projects/matomo
3. Write docker-compose.yaml: single service matomo-app (image: matomo:apache; env: MATOMO_DATABASE_HOST=zeltro-mariadb, MATOMO_DATABASE_TABLES_PREFIX=matomo_, MATOMO_DATABASE_USERNAME=root, MATOMO_DATABASE_PASSWORD=, MATOMO_DATABASE_DBNAME=matomo; volumes: matomo-data:/var/www/html; container_name=matomo, static VPC IP).
4. cd ~/zeltro-projects/matomo && zeltro setup matomo --no-startup && zeltro up matomo
5. Wait 15 seconds, then curl -sI http://matomo/ — expect 200 or 302. First visit shows the installation wizard.'"$SUMMARY_SUFFIX"

IDEA_FLOWISE='Deploy Flowise on this Zeltro server. The project name is flowise — use this exact name, no changes.

Flowise is an open-source LLM workflow builder (image: flowiseai/flowise:latest). It listens on port 3000. Use an nginx reverse proxy. No external database needed (uses SQLite internally).

Steps:
1. mkdir -p ~/zeltro-projects/flowise
2. Write docker-compose.yaml: flowise-app service (image: flowiseai/flowise:latest; env: FLOWISE_USERNAME=admin, FLOWISE_PASSWORD=flowise123; volumes: flowise-data:/root/.flowise) + nginx service (container_name=flowise, static VPC IP). Write nginx.conf proxying to flowise-app:3000.
3. cd ~/zeltro-projects/flowise && zeltro setup flowise --no-startup && zeltro up flowise
4. Wait 10 seconds, then curl -sI http://flowise/ — expect 200 or 302. Log in with admin / flowise123.'"$SUMMARY_SUFFIX"

run_project "appwrite"       "$IDEA_APPWRITE" &
run_project "cal-com"        "$IDEA_CALCOM" &
run_project "standard-notes" "$IDEA_STANDARDNOTES" &
run_project "appsmith"       "$IDEA_APPSMITH" &
run_project "snappymail"     "$IDEA_SNAPPYMAIL" &
run_project "localstack"     "$IDEA_LOCALSTACK" &
run_project "coolify"        "$IDEA_COOLIFY" &
run_project "code-server"    "$IDEA_CODESERVER" &
run_project "matomo"         "$IDEA_MATOMO" &
run_project "flowise"        "$IDEA_FLOWISE" &

wait

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
