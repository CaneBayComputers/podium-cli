#!/bin/bash -l
# OSS batch 3 — cassie, agent: gemini

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.nvm/versions/node/v24.15.0/bin:$PATH"

mkdir -p /tmp/podium-tests/oss3-sessions
LOG=/tmp/podium-tests/oss3-master.log
PODIUM="/usr/local/bin/podium"

$PODIUM ai-set --agent gemini
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

echo "=== OSS Batch 3 (cassie / gemini) — $(date) ===" | tee "$LOG"
echo "Agent: $(grep '^AI_AGENT=' /etc/podium-cli/.env)" | tee -a "$LOG"
echo "" | tee -a "$LOG"

IDEA_REDASH='Deploy Redash on this Podium server. The project name is redash — use this exact name, no changes.

Redash is a SQL dashboarding and data visualization tool (image: redash/redash:latest). The web server listens on port 5000. Use an nginx reverse proxy. Use the shared PostgreSQL and Redis.

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE redash;" 2>/dev/null || true
2. mkdir -p ~/podium-projects/redash
3. Generate REDASH_SECRET_KEY=$(openssl rand -hex 32); REDASH_COOKIE_SECRET=$(openssl rand -hex 32)
4. Write docker-compose.yaml with TWO app services:
   - redash-server: image redash/redash:latest, command: server, env: REDASH_DATABASE_URL=postgresql://root:password@podium-postgres/redash, REDASH_REDIS_URL=redis://podium-redis:6379/3, REDASH_SECRET_KEY=<generated>, REDASH_COOKIE_SECRET=<generated>, PYTHONUNBUFFERED=0
   - redash-worker: same image, command: scheduler,scheduled_worker,worker, same env vars
   - nginx: container_name=redash, static VPC IP, proxies to redash-server:5000
5. Run migrations first: docker run --rm --network podium-cli_vpc -e REDASH_DATABASE_URL=postgresql://root:password@podium-postgres/redash redash/redash:latest manage db upgrade
6. Create admin: docker run --rm --network podium-cli_vpc -e REDASH_DATABASE_URL=postgresql://root:password@podium-postgres/redash redash/redash:latest manage users create_root admin@example.com admin --password admin123
7. cd ~/podium-projects/redash && podium setup redash --no-startup && podium up redash
8. curl -sI http://redash/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_ARCHIVEBOX='Deploy ArchiveBox on this Podium server. The project name is archivebox — use this exact name, no changes.

ArchiveBox is a self-hosted web archiving tool (image: archivebox/archivebox:latest). It listens on port 8000. Use an nginx reverse proxy. Uses SQLite internally — no external database needed.

Steps:
1. mkdir -p ~/podium-projects/archivebox
2. Write docker-compose.yaml: archivebox-app service (image: archivebox/archivebox:latest; command: server --quick-init 0.0.0.0:8000; env: ALLOWED_HOSTS=*, MEDIA_MAX_SIZE=750m; volume: archivebox-data:/data) + nginx (container_name=archivebox, static VPC IP). Write nginx.conf proxying to archivebox-app:8000.
3. cd ~/podium-projects/archivebox && podium setup archivebox --no-startup && podium up archivebox
4. Wait 30 seconds for initialization, then curl -sI http://archivebox/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_KAVITA='Deploy Kavita on this Podium server. The project name is kavita — use this exact name, no changes.

Kavita is a fast digital library server for manga, comics, and books (image: jvmilazz0/kavita:latest). It listens on port 5000. Use an nginx reverse proxy. Uses SQLite internally — no external database needed.

Steps:
1. mkdir -p ~/podium-projects/kavita
2. Write docker-compose.yaml: kavita-app service (image: jvmilazz0/kavita:latest; volumes: kavita-config:/kavita/config, kavita-books:/books) + nginx (container_name=kavita, static VPC IP). Write nginx.conf proxying to kavita-app:5000.
3. cd ~/podium-projects/kavita && podium setup kavita --no-startup && podium up kavita
4. curl -sI http://kavita/ — expect 200 or 302. Visit http://kavita/ to create admin account.'"$SUMMARY_SUFFIX"

IDEA_AUDIOBOOKSHELF='Deploy Audiobookshelf on this Podium server. The project name is audiobookshelf — use this exact name, no changes.

Audiobookshelf is a self-hosted audiobook and podcast server (image: ghcr.io/advplyr/audiobookshelf:latest). It serves on port 80 directly — no nginx proxy needed. No database required.

Steps:
1. mkdir -p ~/podium-projects/audiobookshelf
2. Write docker-compose.yaml: single service audiobookshelf-app (image: ghcr.io/advplyr/audiobookshelf:latest; volumes: audiobookshelf-config:/config, audiobookshelf-metadata:/metadata, audiobookshelf-audiobooks:/audiobooks, audiobookshelf-podcasts:/podcasts; container_name=audiobookshelf, static VPC IP).
3. cd ~/podium-projects/audiobookshelf && podium setup audiobookshelf --no-startup && podium up audiobookshelf
4. curl -sI http://audiobookshelf/ — expect 200 or 302. Visit http://audiobookshelf/ to create admin account.'"$SUMMARY_SUFFIX"

IDEA_NGINXPROXYMANAGER='Deploy Nginx Proxy Manager on this Podium server. The project name is nginx-proxy-manager — use this exact name, no changes.

Nginx Proxy Manager is a reverse proxy management UI (image: jc21/nginx-proxy-manager:latest). The admin UI listens on port 81. Use an nginx reverse proxy (from Podium) to expose the admin UI at port 80. Uses SQLite internally — no external database needed.

Steps:
1. mkdir -p ~/podium-projects/nginx-proxy-manager
2. Write docker-compose.yaml: npm-app service (image: jc21/nginx-proxy-manager:latest; volumes: npm-data:/data, npm-letsencrypt:/etc/letsencrypt) + nginx (container_name=nginx-proxy-manager, static VPC IP). Write nginx.conf proxying to npm-app:81.
3. cd ~/podium-projects/nginx-proxy-manager && podium setup nginx-proxy-manager --no-startup && podium up nginx-proxy-manager
4. Wait 30 seconds, then curl -sI http://nginx-proxy-manager/ — expect 200 or 302. Default login: admin@example.com / changeme.'"$SUMMARY_SUFFIX"

IDEA_BABYBUDDY='Deploy BabyBuddy on this Podium server. The project name is babybuddy — use this exact name, no changes.

BabyBuddy is a baby tracking app (image: lscr.io/linuxserver/babybuddy:latest). It listens on port 8000. Use an nginx reverse proxy. Use the shared PostgreSQL (host=podium-postgres, port=5432, user=root, password=password).

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE babybuddy;" 2>/dev/null || true
2. mkdir -p ~/podium-projects/babybuddy
3. Write docker-compose.yaml: babybuddy-app service (image: lscr.io/linuxserver/babybuddy:latest; env: PUID=1000, PGID=1000, TZ=UTC, DB_ENGINE=django.db.backends.postgresql, DB_HOST=podium-postgres, DB_PORT=5432, DB_NAME=babybuddy, DB_USER=root, DB_PASSWORD=password, CSRF_TRUSTED_ORIGINS=http://babybuddy; volume: babybuddy-config:/config) + nginx (container_name=babybuddy, static VPC IP). Write nginx.conf proxying to babybuddy-app:8000.
4. cd ~/podium-projects/babybuddy && podium setup babybuddy --no-startup && podium up babybuddy
5. curl -sI http://babybuddy/ — expect 200 or 302. Default login: admin / admin.'"$SUMMARY_SUFFIX"

IDEA_SUPERSET='Deploy Apache Superset on this Podium server. The project name is superset — use this exact name, no changes.

Apache Superset is a data exploration and visualization platform (image: apache/superset:latest). It listens on port 8088. Use an nginx reverse proxy. Use the shared PostgreSQL (host=podium-postgres, port=5432, user=root, password=password).

Steps:
1. Create DB: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE superset;" 2>/dev/null || true
2. mkdir -p ~/podium-projects/superset
3. Generate SECRET_KEY: $(openssl rand -hex 32)
4. Write docker-compose.yaml with TWO services:
   - superset-init: image apache/superset:latest, restart: "no", command: bash -c "superset db upgrade && superset fab create-admin --username admin --firstname Admin --lastname User --email admin@example.com --password admin123 && superset init", env: SUPERSET_SECRET_KEY=<generated>, SQLALCHEMY_DATABASE_URI=postgresql+psycopg2://root:password@podium-postgres/superset
   - superset-app: same image, env: same, depends_on: superset-init
   - nginx: container_name=superset, static VPC IP, proxies to superset-app:8088
5. cd ~/podium-projects/superset && podium setup superset --no-startup && podium up superset
6. Wait 60 seconds for init to complete, then curl -sI http://superset/ — expect 200 or 302. Login: admin / admin123.'"$SUMMARY_SUFFIX"

IDEA_ROUNDCUBE='Deploy Roundcube on this Podium server. The project name is roundcube — use this exact name, no changes.

Roundcube is an open-source webmail client (image: roundcube/roundcubemail:latest). It serves on port 80 directly — no nginx proxy needed. Use the shared MariaDB (host=podium-mariadb, user=root, password=empty). Pre-configure to use Podium'"'"'s MailHog for local development.

Steps:
1. Create DB: docker exec podium-mariadb mariadb -u root -e "CREATE DATABASE IF NOT EXISTS roundcube CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
2. mkdir -p ~/podium-projects/roundcube
3. Write docker-compose.yaml: single service roundcube-app (image: roundcube/roundcubemail:latest; env: ROUNDCUBEMAIL_DB_TYPE=mysql, ROUNDCUBEMAIL_DB_HOST=podium-mariadb, ROUNDCUBEMAIL_DB_PORT=3306, ROUNDCUBEMAIL_DB_NAME=roundcube, ROUNDCUBEMAIL_DB_USER=root, ROUNDCUBEMAIL_DB_PASSWORD=, ROUNDCUBEMAIL_DEFAULT_HOST=podium-mailhog, ROUNDCUBEMAIL_DEFAULT_PORT=1025, ROUNDCUBEMAIL_SMTP_SERVER=podium-mailhog, ROUNDCUBEMAIL_SMTP_PORT=1025, ROUNDCUBEMAIL_SKIN=elastic; container_name=roundcube, static VPC IP).
4. cd ~/podium-projects/roundcube && podium setup roundcube --no-startup && podium up roundcube
5. Wait 30 seconds for DB initialization, then curl -sI http://roundcube/ — expect 200. Note: this is a webmail client; no real IMAP server configured for dev use.'"$SUMMARY_SUFFIX"

run_project "redash"               "$IDEA_REDASH" &
run_project "archivebox"           "$IDEA_ARCHIVEBOX" &
run_project "kavita"               "$IDEA_KAVITA" &
run_project "audiobookshelf"       "$IDEA_AUDIOBOOKSHELF" &
run_project "nginx-proxy-manager"  "$IDEA_NGINXPROXYMANAGER" &
run_project "babybuddy"            "$IDEA_BABYBUDDY" &
run_project "superset"             "$IDEA_SUPERSET" &
run_project "roundcube"            "$IDEA_ROUNDCUBE" &

wait

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
