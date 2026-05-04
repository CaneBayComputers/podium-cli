#!/bin/bash -l
# OSS batch 3 — cami, agent: codex

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.nvm/versions/node/v24.15.0/bin:$PATH"

mkdir -p /tmp/podium-tests/oss3-sessions
LOG=/tmp/podium-tests/oss3-master.log
PODIUM="/usr/local/bin/podium"

$PODIUM ai-set --agent codex
echo "AI agent set to: $(grep '^AI_AGENT=' /etc/podium-cli/.env)"

run_project() {
    local name="$1"
    local idea="$2"
    local logfile="/tmp/podium-tests/oss3-sessions/${name}.log"

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

echo "=== OSS Batch 3 (cami / codex) — $(date) ===" | tee "$LOG"
echo "Agent: $(grep '^AI_AGENT=' /etc/podium-cli/.env)" | tee -a "$LOG"
echo "" | tee -a "$LOG"

IDEA_STRAPI='Deploy Strapi on this Podium server. The project name is strapi — use this exact name, no changes.

Strapi is a headless CMS (image: naskio/strapi:latest). It listens on port 1337. Use an nginx reverse proxy. Use the shared PostgreSQL (host=podium-postgres, port=5432, user=root, password=password).

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE strapi;" 2>/dev/null || true
2. mkdir -p ~/podium-projects/strapi
3. Generate secrets: APP_KEYS=$(openssl rand -hex 16),$(openssl rand -hex 16); API_TOKEN_SALT=$(openssl rand -hex 16); ADMIN_JWT_SECRET=$(openssl rand -hex 32); TRANSFER_TOKEN_SALT=$(openssl rand -hex 16); JWT_SECRET=$(openssl rand -hex 32)
4. Write docker-compose.yaml: strapi-app service (image: naskio/strapi:latest; env: DATABASE_CLIENT=postgres, DATABASE_HOST=podium-postgres, DATABASE_PORT=5432, DATABASE_NAME=strapi, DATABASE_USERNAME=root, DATABASE_PASSWORD=password, APP_KEYS=<generated>, API_TOKEN_SALT=<generated>, ADMIN_JWT_SECRET=<generated>, TRANSFER_TOKEN_SALT=<generated>, JWT_SECRET=<generated>, NODE_ENV=production; volume: strapi-uploads:/opt/app/public/uploads) + nginx (container_name=strapi, static VPC IP). Write nginx.conf proxying to strapi-app:1337.
5. cd ~/podium-projects/strapi && podium setup strapi --no-startup && podium up strapi
6. Wait 60 seconds for first build, then curl -sI http://strapi/ — expect 200 or 302. Visit http://strapi/admin to create admin.'"$SUMMARY_SUFFIX"

IDEA_DIRECTUS='Deploy Directus on this Podium server. The project name is directus — use this exact name, no changes.

Directus is an open data platform / headless CMS (image: directus/directus:latest). It listens on port 8055. Use an nginx reverse proxy. Use the shared PostgreSQL (host=podium-postgres, port=5432, user=root, password=password).

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE directus;" 2>/dev/null || true
2. mkdir -p ~/podium-projects/directus
3. Generate SECRET: $(openssl rand -hex 32)
4. Write docker-compose.yaml: directus-app service (image: directus/directus:latest; env: SECRET=<generated>, DB_CLIENT=pg, DB_HOST=podium-postgres, DB_PORT=5432, DB_DATABASE=directus, DB_USER=root, DB_PASSWORD=password, ADMIN_EMAIL=admin@example.com, ADMIN_PASSWORD=admin123, PUBLIC_URL=http://directus; volume: directus-uploads:/directus/uploads) + nginx (container_name=directus, static VPC IP). Write nginx.conf proxying to directus-app:8055.
5. cd ~/podium-projects/directus && podium setup directus --no-startup && podium up directus
6. curl -sI http://directus/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_EXCALIDRAW='Deploy Excalidraw on this Podium server. The project name is excalidraw — use this exact name, no changes.

Excalidraw is a virtual collaborative whiteboard (image: excalidraw/excalidraw:latest). It serves on port 80 directly — no nginx proxy needed. No database required.

Steps:
1. mkdir -p ~/podium-projects/excalidraw
2. Write docker-compose.yaml: single service excalidraw-app (image: excalidraw/excalidraw:latest; container_name=excalidraw, static VPC IP). No volumes or env vars needed.
3. cd ~/podium-projects/excalidraw && podium setup excalidraw --no-startup && podium up excalidraw
4. curl -sI http://excalidraw/ — expect 200.'"$SUMMARY_SUFFIX"

IDEA_MEILISEARCH='Deploy Meilisearch on this Podium server. The project name is meilisearch — use this exact name, no changes.

Meilisearch is a fast search engine API (image: getmeili/meilisearch:latest). It listens on port 7700. Use an nginx reverse proxy. No database needed.

Steps:
1. mkdir -p ~/podium-projects/meilisearch
2. Generate MASTER_KEY: $(openssl rand -hex 32)
3. Write docker-compose.yaml: meilisearch-app service (image: getmeili/meilisearch:latest; env: MEILI_ENV=production, MEILI_MASTER_KEY=<generated>; volume: meilisearch-data:/meili_data) + nginx (container_name=meilisearch, static VPC IP). Write nginx.conf proxying to meilisearch-app:7700.
4. cd ~/podium-projects/meilisearch && podium setup meilisearch --no-startup && podium up meilisearch
5. curl -sI http://meilisearch/ — expect 200. Access the search dashboard at http://meilisearch/.'"$SUMMARY_SUFFIX"

IDEA_METABASE='Deploy Metabase on this Podium server. The project name is metabase — use this exact name, no changes.

Metabase is a business intelligence and analytics tool (image: metabase/metabase:latest). It listens on port 3000. Use an nginx reverse proxy. Uses an embedded H2 database — no external DB needed.

Steps:
1. mkdir -p ~/podium-projects/metabase
2. Write docker-compose.yaml: metabase-app service (image: metabase/metabase:latest; env: MB_DB_TYPE=h2, MB_DB_FILE=/metabase-data/metabase.db, JAVA_TIMEZONE=UTC; volume: metabase-data:/metabase-data) + nginx (container_name=metabase, static VPC IP). Write nginx.conf proxying to metabase-app:3000 with proxy_read_timeout 300s.
3. cd ~/podium-projects/metabase && podium setup metabase --no-startup && podium up metabase
4. Wait 60 seconds for JVM startup, then curl -sI http://metabase/ — expect 200. Visit http://metabase/ to complete setup.'"$SUMMARY_SUFFIX"

IDEA_HEALTHCHECKS='Deploy Healthchecks on this Podium server. The project name is healthchecks — use this exact name, no changes.

Healthchecks is a cron job monitoring service (image: healthchecks/healthchecks:latest). It listens on port 8000. Use an nginx reverse proxy. Use the shared PostgreSQL (host=podium-postgres, port=5432, user=root, password=password).

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE healthchecks;" 2>/dev/null || true
2. mkdir -p ~/podium-projects/healthchecks
3. Generate SECRET_KEY: $(openssl rand -hex 32)
4. Write docker-compose.yaml: healthchecks-app service (image: healthchecks/healthchecks:latest; env: DB=postgres, DB_HOST=podium-postgres, DB_PORT=5432, DB_NAME=healthchecks, DB_USER=root, DB_PASSWORD=password, SECRET_KEY=<generated>, SITE_ROOT=http://healthchecks, SITE_NAME=Healthchecks, EMAIL_HOST=podium-mailhog, EMAIL_PORT=1025, EMAIL_USE_TLS=False, DEFAULT_FROM_EMAIL=hc@example.com, SUPERUSER_EMAIL=admin@example.com, SUPERUSER_PASSWORD=admin123) + nginx (container_name=healthchecks, static VPC IP). Write nginx.conf proxying to healthchecks-app:8000.
5. cd ~/podium-projects/healthchecks && podium setup healthchecks --no-startup && podium up healthchecks
6. curl -sI http://healthchecks/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_NETBOX='Deploy NetBox on this Podium server. The project name is netbox — use this exact name, no changes.

NetBox is an IP address management and network documentation tool (image: netboxcommunity/netbox:latest). It listens on port 8080. Use an nginx reverse proxy. Use the shared PostgreSQL and Redis.

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE netbox;" 2>/dev/null || true
2. mkdir -p ~/podium-projects/netbox
3. Generate SECRET_KEY (50 chars): $(openssl rand -base64 37 | tr -d "=+/" | head -c 50); SUPERUSER_API_TOKEN=$(openssl rand -hex 20)
4. Write docker-compose.yaml: netbox-app service (image: netboxcommunity/netbox:latest; env: DB_HOST=podium-postgres, DB_PORT=5432, DB_NAME=netbox, DB_USER=root, DB_PASSWORD=password, REDIS_HOST=podium-redis, REDIS_PORT=6379, REDIS_PASSWORD=, REDIS_DB=4, REDIS_CACHE_DB=5, SECRET_KEY=<generated>, SUPERUSER_NAME=admin, SUPERUSER_EMAIL=admin@example.com, SUPERUSER_PASSWORD=admin123, SUPERUSER_API_TOKEN=<generated>, ALLOWED_HOSTS=netbox; volumes: netbox-media:/opt/netbox/netbox/media, netbox-reports:/opt/netbox/netbox/reports, netbox-scripts:/opt/netbox/netbox/scripts) + nginx (container_name=netbox, static VPC IP). Write nginx.conf proxying to netbox-app:8080.
5. cd ~/podium-projects/netbox && podium setup netbox --no-startup && podium up netbox
6. Wait 60 seconds for migrations to run, then curl -sI http://netbox/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_LABELSTUDIO='Deploy Label Studio on this Podium server. The project name is label-studio — use this exact name, no changes.

Label Studio is a data labeling tool for AI/ML (image: heartexlabs/label-studio:latest). It listens on port 8080. Use an nginx reverse proxy. Uses SQLite by default — no external database needed.

Steps:
1. mkdir -p ~/podium-projects/label-studio
2. Write docker-compose.yaml: label-studio-app service (image: heartexlabs/label-studio:latest; env: DJANGO_DB=default, LOCAL_FILES_SERVING_ENABLED=true; volume: label-studio-data:/label-studio/data) + nginx (container_name=label-studio, static VPC IP). Write nginx.conf proxying to label-studio-app:8080 with client_max_body_size 200M.
3. cd ~/podium-projects/label-studio && podium setup label-studio --no-startup && podium up label-studio
4. curl -sI http://label-studio/ — expect 200 or 302. Visit http://label-studio/ to create your account.'"$SUMMARY_SUFFIX"

run_project "strapi"        "$IDEA_STRAPI" &
run_project "directus"      "$IDEA_DIRECTUS" &
run_project "excalidraw"    "$IDEA_EXCALIDRAW" &
run_project "meilisearch"   "$IDEA_MEILISEARCH" &
run_project "metabase"      "$IDEA_METABASE" &
run_project "healthchecks"  "$IDEA_HEALTHCHECKS" &
run_project "netbox"        "$IDEA_NETBOX" &
run_project "label-studio"  "$IDEA_LABELSTUDIO" &

wait

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
