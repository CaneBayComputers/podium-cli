#!/bin/bash -l
# OSS project tests — dingdong, agent: claude

mkdir -p /tmp/podium-tests/oss-sessions
LOG=/tmp/podium-tests/oss-master.log
PODIUM="/usr/local/bin/podium"

run_project() {
    local name="$1"
    local idea="$2"
    local logfile="/tmp/podium-tests/oss-sessions/${name}.log"

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

echo "=== OSS Project Tests (dingdong / claude) — $(date) ===" | tee "$LOG"
echo "Agent: $(grep '^AI_AGENT=' /etc/podium-cli/.env)" | tee -a "$LOG"
echo "" | tee -a "$LOG"

IDEA_VAULTWARDEN='Deploy Vaultwarden on this Podium server. The project name is vaultwarden — use this exact name, no changes.

Vaultwarden is an unofficial Bitwarden-compatible password manager server (image: vaultwarden/server:latest). It serves its own web vault on port 80 directly — no nginx proxy needed.

Steps:
1. mkdir -p ~/podium-projects/vaultwarden
2. Write docker-compose.yaml using image vaultwarden/server:latest. Single service, container_name=vaultwarden, static VPC IP, persist /data with a named volume.
3. cd ~/podium-projects/vaultwarden && podium setup vaultwarden --no-startup
4. podium up vaultwarden
5. curl -sI http://vaultwarden/ to verify HTTP 200.'"$SUMMARY_SUFFIX"

IDEA_PORTAINER='Deploy Portainer CE on this Podium server. The project name is portainer — use this exact name, no changes.

Portainer is a Docker management UI (image: portainer/portainer-ce:latest). It runs on port 9000 internally. Use an nginx reverse proxy to expose it at port 80.

CRITICAL: The container MUST mount /var/run/docker.sock:/var/run/docker.sock:ro — without this Portainer cannot see containers.

Steps:
1. mkdir -p ~/podium-projects/portainer
2. Write docker-compose.yaml with two services: portainer-app (the Portainer container with Docker socket mount) and nginx (container_name=portainer, static VPC IP, proxies to portainer-app:9000). Write nginx.conf.
3. cd ~/podium-projects/portainer && podium setup portainer --no-startup
4. podium up portainer
5. curl -sI http://portainer/ — expect 200. Note: you have 5 minutes to set up admin before Portainer locks.'"$SUMMARY_SUFFIX"

IDEA_GRAFANA='Deploy Grafana on this Podium server. The project name is grafana — use this exact name, no changes.

Grafana is a metrics and dashboards platform (image: grafana/grafana:latest). It listens on port 3000. Use an nginx reverse proxy.

Steps:
1. mkdir -p ~/podium-projects/grafana
2. Write docker-compose.yaml: grafana-app service + nginx service (container_name=grafana, static VPC IP). Write nginx.conf proxying to grafana-app:3000.
3. Set env: GF_SERVER_ROOT_URL=http://grafana/, GF_SECURITY_ADMIN_PASSWORD=admin
4. Persist /var/lib/grafana with a named volume.
5. cd ~/podium-projects/grafana && podium setup grafana --no-startup && podium up grafana
6. curl -sI http://grafana/ — expect 200 or 302.'"$SUMMARY_SUFFIX"

IDEA_KANBOARD='Deploy Kanboard on this Podium server. The project name is kanboard — use this exact name, no changes.

Kanboard is a Kanban project management tool (image: kanboard/kanboard:latest). It serves on port 80 directly — no nginx proxy needed. Uses SQLite.

Steps:
1. mkdir -p ~/podium-projects/kanboard
2. Write docker-compose.yaml: single service, container_name=kanboard, static VPC IP, persist /var/www/app/data with a named volume.
3. cd ~/podium-projects/kanboard && podium setup kanboard --no-startup && podium up kanboard
4. curl -sI http://kanboard/ — expect 200. Default login: admin/admin.'"$SUMMARY_SUFFIX"

IDEA_MINIFLUX='Deploy Miniflux on this Podium server. The project name is miniflux — use this exact name, no changes.

Miniflux is a minimalist RSS reader (image: miniflux/miniflux:latest). It listens on port 8080. Use an nginx reverse proxy. IMPORTANT: Miniflux supports PostgreSQL ONLY — do not use MariaDB. Use the shared podium-postgres container (host=podium-postgres, port=5432, user=root, password=password).

Steps:
1. Create database: docker exec podium-postgres psql -U root -d postgres -c "CREATE DATABASE miniflux;"
2. mkdir -p ~/podium-projects/miniflux
3. Write docker-compose.yaml: miniflux-app service (env: DATABASE_URL, RUN_MIGRATIONS=1, CREATE_ADMIN=1, ADMIN_USERNAME=admin, ADMIN_PASSWORD=admin123) + nginx service (container_name=miniflux, static VPC IP). Write nginx.conf proxying to miniflux-app:8080.
4. cd ~/podium-projects/miniflux && podium setup miniflux --no-startup && podium up miniflux
5. curl -sI http://miniflux/ — expect 200.'"$SUMMARY_SUFFIX"

IDEA_VIKUNJA='Deploy Vikunja on this Podium server. The project name is vikunja — use this exact name, no changes.

Vikunja is a self-hosted task manager (image: vikunja/vikunja:latest). It listens on port 3456. Use an nginx reverse proxy. Use the shared MariaDB (host=podium-mariadb, user=root, password=empty).

Steps:
1. Create DB: docker exec podium-mariadb mysql -u root -e "CREATE DATABASE IF NOT EXISTS vikunja;"
2. mkdir -p ~/podium-projects/vikunja
3. Write docker-compose.yaml: vikunja-app service (env: VIKUNJA_DATABASE_TYPE=mysql, VIKUNJA_DATABASE_HOST=podium-mariadb, VIKUNJA_DATABASE_USER=root, VIKUNJA_DATABASE_PASSWORD=, VIKUNJA_DATABASE_DATABASE=vikunja, VIKUNJA_SERVICE_JWTSECRET=any-random-32-char-string, VIKUNJA_SERVICE_FRONTENDURL=http://vikunja/) + nginx (container_name=vikunja, static VPC IP). Write nginx.conf proxying to vikunja-app:3456.
4. cd ~/podium-projects/vikunja && podium setup vikunja --no-startup && podium up vikunja
5. curl -sI http://vikunja/ — expect 200.'"$SUMMARY_SUFFIX"

IDEA_MEALIE='Deploy Mealie on this Podium server. The project name is mealie — use this exact name, no changes.

Mealie is a recipe manager (image: ghcr.io/mealie-recipes/mealie:latest). It listens on port 9000. Use an nginx reverse proxy. Uses SQLite by default (no external database needed).

Steps:
1. mkdir -p ~/podium-projects/mealie
2. Write docker-compose.yaml: mealie-app service (env: BASE_URL=http://mealie, ALLOW_SIGNUP=true, persist /app/data) + nginx (container_name=mealie, static VPC IP). Write nginx.conf proxying to mealie-app:9000.
3. cd ~/podium-projects/mealie && podium setup mealie --no-startup && podium up mealie
4. curl -sI http://mealie/ — expect 200. Default: changeme@example.com / MyPassword.'"$SUMMARY_SUFFIX"

IDEA_NETDATA='Deploy Netdata on this Podium server. The project name is netdata — use this exact name, no changes.

Netdata is a real-time system monitoring tool (image: netdata/netdata:latest). It listens on port 19999. Use an nginx reverse proxy.

CRITICAL special requirements for the netdata container:
- cap_add: [SYS_PTRACE]
- security_opt: [apparmor:unconfined]
- volumes: /proc:/host/proc:ro, /sys:/host/sys:ro, /etc/passwd:/host/etc/passwd:ro, /etc/group:/host/etc/group:ro, /etc/os-release:/host/etc/os-release:ro

Steps:
1. mkdir -p ~/podium-projects/netdata
2. Write docker-compose.yaml: netdata-app service (with the special caps and bind mounts above, persist named volumes for /etc/netdata, /var/lib/netdata, /var/cache/netdata) + nginx (container_name=netdata, static VPC IP). Write nginx.conf proxying to netdata-app:19999.
3. cd ~/podium-projects/netdata && podium setup netdata --no-startup && podium up netdata
4. curl -sI http://netdata/ — expect 200. No login required.'"$SUMMARY_SUFFIX"

run_project "vaultwarden" "$IDEA_VAULTWARDEN" &
run_project "portainer"   "$IDEA_PORTAINER" &
run_project "grafana"     "$IDEA_GRAFANA" &
run_project "kanboard"    "$IDEA_KANBOARD" &
run_project "miniflux"    "$IDEA_MINIFLUX" &
run_project "vikunja"     "$IDEA_VIKUNJA" &
run_project "mealie"      "$IDEA_MEALIE" &
run_project "netdata"     "$IDEA_NETDATA" &

wait

echo "" | tee -a "$LOG"
echo "=== ALL DONE — $(date) ===" | tee -a "$LOG"
