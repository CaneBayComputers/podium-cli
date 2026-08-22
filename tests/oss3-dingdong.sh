#!/bin/bash -l
# OSS batch 3 — dingdong, agent: claude

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.nvm/versions/node/v24.15.0/bin:$PATH"

mkdir -p /tmp/zeltro-tests/oss3-sessions
LOG=/tmp/zeltro-tests/oss3-master.log
ZELTRO="/usr/local/bin/zeltro"

run_project() {
    local name="$1"
    local idea="$2"
    local logfile="/tmp/zeltro-tests/oss3-sessions/${name}.log"

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

echo "=== OSS Batch 3 (dingdong / claude) — $(date) ===" | tee "$LOG"
echo "" | tee -a "$LOG"

IDEA_FIREFLYIII='Deploy Firefly III on this Zeltro server. The project name is firefly-iii — use this exact name, no changes.

Firefly III is a personal finance manager (image: fireflyiii/core:latest). It listens on port 8080. Use an nginx reverse proxy. Use the shared MariaDB (host=zeltro-mariadb, user=root, password=empty).

Steps:
1. Create DB: docker exec zeltro-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS firefly;"
2. mkdir -p ~/zeltro-projects/firefly-iii
3. Generate APP_KEY: base64:$(openssl rand -base64 32)
4. Write docker-compose.yaml: firefly-iii-app service (image: fireflyiii/core:latest; env: APP_KEY=<generated>, APP_URL=http://firefly-iii, DB_CONNECTION=mysql, DB_HOST=zeltro-mariadb, DB_PORT=3306, DB_DATABASE=firefly, DB_USERNAME=root, DB_PASSWORD=, TRUSTED_PROXIES=**; volume: firefly-upload:/var/www/html/storage/upload) + nginx service (container_name=firefly-iii, static VPC IP). Write nginx.conf proxying to firefly-iii-app:8080.
5. cd ~/zeltro-projects/firefly-iii && zeltro setup firefly-iii --no-startup && zeltro up firefly-iii
6. curl -sI http://firefly-iii/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_INVOICENINJA='Deploy Invoice Ninja v5 on this Zeltro server. The project name is invoice-ninja — use this exact name, no changes.

Invoice Ninja is an invoicing platform (image: invoiceninja/invoiceninja:5). It serves on port 80 directly via its own nginx — no external nginx proxy needed. Use the shared MariaDB (host=zeltro-mariadb, user=root, password=empty).

Steps:
1. Create DB: docker exec zeltro-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS ninja CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
2. mkdir -p ~/zeltro-projects/invoice-ninja
3. Generate APP_KEY: base64:$(openssl rand -base64 32)
4. Write docker-compose.yaml: single service invoice-ninja-app (image: invoiceninja/invoiceninja:5; env: APP_KEY=<generated>, APP_URL=http://invoice-ninja, DB_HOST=zeltro-mariadb, DB_PORT=3306, DB_DATABASE=ninja, DB_USERNAME=root, DB_PASSWORD=, NINJA_ENVIRONMENT=selfhosted, IN_USER_EMAIL=admin@example.com, IN_PASSWORD=changeme1; volumes: ninja-public:/var/www/app/public, ninja-storage:/var/www/app/storage; container_name=invoice-ninja, static VPC IP).
5. cd ~/zeltro-projects/invoice-ninja && zeltro setup invoice-ninja --no-startup && zeltro up invoice-ninja
6. Wait 30 seconds for first-run initialization, then curl -sI http://invoice-ninja/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_FLARUM='Deploy Flarum on this Zeltro server. The project name is flarum — use this exact name, no changes.

Flarum is a modern forum platform (image: mondedie/flarum:latest). It listens on port 8888. Use an nginx reverse proxy. Use the shared MariaDB (host=zeltro-mariadb, user=root, password=empty).

Steps:
1. Create DB: docker exec zeltro-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS flarum CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
2. mkdir -p ~/zeltro-projects/flarum
3. Write docker-compose.yaml: flarum-app service (image: mondedie/flarum:latest; env: FORUM_URL=http://flarum, DB_HOST=zeltro-mariadb, DB_PORT=3306, DB_NAME=flarum, DB_USER=root, DB_PASS=, DB_PREF=flarum_, FLARUM_ADMIN_USER=admin, FLARUM_ADMIN_PASS=adminpass, FLARUM_ADMIN_MAIL=admin@example.com, FLARUM_TITLE=My Forum; volume: flarum-assets:/flarum/app/public/assets) + nginx (container_name=flarum, static VPC IP). Write nginx.conf proxying to flarum-app:8888.
4. cd ~/zeltro-projects/flarum && zeltro setup flarum --no-startup && zeltro up flarum
5. Wait 60 seconds for first-run DB install, then curl -sI http://flarum/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_FREESCOUT='Deploy FreeScout on this Zeltro server. The project name is freescout — use this exact name, no changes.

FreeScout is an open-source help desk (image: tiredofit/freescout:latest). It serves on port 80 directly — no nginx proxy needed. Use the shared MariaDB (host=zeltro-mariadb, user=root, password=empty).

Steps:
1. Create DB: docker exec zeltro-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS freescout CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
2. mkdir -p ~/zeltro-projects/freescout
3. Write docker-compose.yaml: single service freescout-app (image: tiredofit/freescout:latest; env: DB_HOST=zeltro-mariadb, DB_PORT=3306, DB_NAME=freescout, DB_USER=root, DB_PASS=, SITE_URL=http://freescout, ADMIN_EMAIL=admin@example.com, ADMIN_FIRST_NAME=Admin, ADMIN_LAST_NAME=User, ADMIN_PASS=admin123, TIMEZONE=UTC, LANGUAGE=en, ENABLE_SSL_PROXY=TRUE; container_name=freescout, static VPC IP).
4. cd ~/zeltro-projects/freescout && zeltro setup freescout --no-startup && zeltro up freescout
5. Wait 60 seconds for first-run setup, then curl -sI http://freescout/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_LEANTIME='Deploy Leantime on this Zeltro server. The project name is leantime — use this exact name, no changes.

Leantime is a project management system (image: leantime/leantime:latest). It serves on port 80 directly — no nginx proxy needed. Use the shared MariaDB (host=zeltro-mariadb, user=root, password=empty).

Steps:
1. Create DB: docker exec zeltro-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS leantime CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
2. mkdir -p ~/zeltro-projects/leantime
3. Write docker-compose.yaml: single service leantime-app (image: leantime/leantime:latest; env: LEAN_DB_HOST=zeltro-mariadb, LEAN_DB_PORT=3306, LEAN_DB_DATABASE=leantime, LEAN_DB_USER=root, LEAN_DB_PASSWORD=, LEAN_SITENAME=Leantime, LEAN_APP_URL=http://leantime, LEAN_SESSION_PASSWORD=$(openssl rand -hex 16), LEAN_EMAIL_RETURN=admin@example.com; volumes: leantime-userfiles:/var/www/html/userfiles, leantime-public-userfiles:/var/www/html/public/userfiles; container_name=leantime, static VPC IP).
4. cd ~/zeltro-projects/leantime && zeltro setup leantime --no-startup && zeltro up leantime
5. curl -sI http://leantime/ — expect 200 or 302. First user to register becomes admin.'"$SUMMARY_SUFFIX"

IDEA_KOEL='Deploy Koel on this Zeltro server. The project name is koel — use this exact name, no changes.

Koel is a personal music streaming service (image: phanan/koel:latest). It serves on port 80 directly — no nginx proxy needed. Use the shared PostgreSQL (host=zeltro-postgres, port=5432, user=root, password=password).

Steps:
1. Create DB: docker exec zeltro-postgres psql -U root -d postgres -c "CREATE DATABASE koel;" 2>/dev/null || true
2. mkdir -p ~/zeltro-projects/koel
3. Generate APP_KEY: base64:$(openssl rand -base64 32)
4. Write docker-compose.yaml: single service koel-app (image: phanan/koel:latest; env: DB_CONNECTION=pgsql, DB_HOST=zeltro-postgres, DB_PORT=5432, DB_DATABASE=koel, DB_USERNAME=root, DB_PASSWORD=password, APP_KEY=<generated>, MEDIA_PATH=/music, APP_URL=http://koel; volume: koel-music:/music; container_name=koel, static VPC IP).
5. cd ~/zeltro-projects/koel && zeltro setup koel --no-startup && zeltro up koel
6. Wait 30 seconds, then curl -sI http://koel/ — expect 200 or 302. Visit http://koel/ to set admin credentials on first run.'"$SUMMARY_SUFFIX"

IDEA_SHLINK='Deploy Shlink on this Zeltro server. The project name is shlink — use this exact name, no changes.

Shlink is a self-hosted URL shortener (image: shlinkio/shlink:stable). It listens on port 8080. Use an nginx reverse proxy. Use the shared MariaDB (host=zeltro-mariadb, user=root, password=empty).

Steps:
1. Create DB: docker exec zeltro-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS shlink;"
2. mkdir -p ~/zeltro-projects/shlink
3. Write docker-compose.yaml: shlink-app service (image: shlinkio/shlink:stable; env: DEFAULT_DOMAIN=shlink, IS_HTTPS_ENABLED=false, DB_DRIVER=mysql, DB_HOST=zeltro-mariadb, DB_PORT=3306, DB_NAME=shlink, DB_USER=root, DB_PASSWORD=, GEOLITE_LICENSE_KEY=, DISABLE_TRACKING_FROM=, SHORT_DOMAIN_SCHEMA=http) + nginx (container_name=shlink, static VPC IP). Write nginx.conf proxying to shlink-app:8080.
4. cd ~/zeltro-projects/shlink && zeltro setup shlink --no-startup && zeltro up shlink
5. curl -sI http://shlink/ — expect 200 or 302. Get API key from: docker logs shlink-shlink-app-1 | grep "API key"'"$SUMMARY_SUFFIX"

IDEA_CACHET='Deploy Cachet on this Zeltro server. The project name is cachet — use this exact name, no changes.

Cachet is an open-source status page system (image: cachethq/docker:latest). It listens on port 8000. Use an nginx reverse proxy. Use the shared PostgreSQL (host=zeltro-postgres, port=5432, user=root, password=password).

Steps:
1. Create DB: docker exec zeltro-postgres psql -U root -d postgres -c "CREATE DATABASE cachet;" 2>/dev/null || true
2. mkdir -p ~/zeltro-projects/cachet
3. Generate APP_KEY: base64:$(openssl rand -base64 32)
4. Write docker-compose.yaml: cachet-app service (image: cachethq/docker:latest; env: DB_DRIVER=pgsql, DB_HOST=zeltro-postgres, DB_PORT=5432, DB_DATABASE=cachet, DB_USERNAME=root, DB_PASSWORD=password, APP_KEY=<generated>, APP_ENV=production, APP_URL=http://cachet, APP_DEBUG=false, CACHE_DRIVER=array, SESSION_DRIVER=array, QUEUE_DRIVER=sync, MAIL_DRIVER=log) + nginx (container_name=cachet, static VPC IP). Write nginx.conf proxying to cachet-app:8000.
5. cd ~/zeltro-projects/cachet && zeltro setup cachet --no-startup && zeltro up cachet
6. Wait 30 seconds, then curl -sI http://cachet/ — expect 200 or 302. Visit http://cachet/setup to complete installation.'"$SUMMARY_SUFFIX"

echo "=== OSS Batch 3 (dingdong / claude) — $(date) ===" | tee "$LOG"
echo "" | tee -a "$LOG"

run_project "firefly-iii"   "$IDEA_FIREFLYIII" &
run_project "invoice-ninja" "$IDEA_INVOICENINJA" &
run_project "flarum"        "$IDEA_FLARUM" &
run_project "freescout"     "$IDEA_FREESCOUT" &
run_project "leantime"      "$IDEA_LEANTIME" &
run_project "koel"          "$IDEA_KOEL" &
run_project "shlink"        "$IDEA_SHLINK" &
run_project "cachet"        "$IDEA_CACHET" &

wait

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
